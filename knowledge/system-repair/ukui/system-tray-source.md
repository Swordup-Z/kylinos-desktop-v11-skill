# UKUI 系统托盘源码级修改

## 适用场景

- `systemTray.json` 已正确保存 `orderedItems` 和 `separateIndex`，但主显示区应用退出后，折叠/隐藏区图标会自动补位到主托盘。
- 用户要求“隐藏到折叠区”，不是写入 `trayIconsInhibited` 抑制显示。
- 配置级修复无法满足“显示项退出时隐藏项仍保持隐藏”的行为。

## 组件定位

关键包和文件：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' ukui-widget-system-tray
dpkg -L ukui-widget-system-tray | rg 'systemTray|libukui-system-tray'
zcat /usr/share/doc/ukui-widget-system-tray/changelog.Debian.gz | sed -n '1,120p'
```

常见目标：

```text
Source: ukui-sni
Plugin: /usr/lib/aarch64-linux-gnu/qt5/qml/org/ukui/systemTray/libukui-system-tray.so
QML: /usr/share/ukui/widgets/org.ukui.systemTray/ui/
```

公开源码候选：

```bash
git clone https://gitee.com/openkylin/ukui-sni.git
```

如果发行版没有公开精确源码包，不要只凭 tag 名称相近就替换系统库；按 `knowledge/feature-enhancement/source-rebuild/README.md` 的“源码获取与候选节点收敛”流程，用 changelog、bug id、关键符号、`readelf`、`nm` 和 QML 接口做精确比对。

## 最小补丁思路

原始分组逻辑容易使用当前运行时行号判断主显示区和折叠区。运行时行号会随着已注册托盘项增减而压缩，所以主显示区应用退出后，后面的隐藏项可能被补到主显示区。

更稳定的做法：

1. 在 `TrayItemsModel` 增加内部角色，例如 `ConfigOrder`。
2. `ConfigOrder` 返回托盘项在 `fixedItems + orderedItems` 中的配置序号。
3. `ItemGroupModel::filterAcceptsRow()` 使用 `ConfigOrder` 与 `separateIndex` 比较。
4. 未进入配置列表的托盘项可回退到运行时行号，保留未配置应用的原有行为。

示意：

```cpp
int order = sourceIndex.data(TrayItemsModel::ConfigOrder).toInt();
if (order < 0) {
    order = source_row;
}

if (m_groupType == GroupType::Show) {
    return order >= 0 && order <= m_currentSeparateIndex;
} else if (m_groupType == GroupType::Fold) {
    return order > m_currentSeparateIndex;
}
```

注意：`fixedItems` 会被源码拼到 `orderedItems` 前面；计算 `separateIndex` 时必须按内部顺序 `fixedItems + orderedItems` 判断。

## 构建与试装

源码、构建目录、staging 和回滚包应放在 DATA 分区共享工作区：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/
```

构建示例：

```bash
cmake -S /data/usershare/kylinos-local-sources/<component-or-fix>/ukui-sni \
      -B /data/usershare/kylinos-local-sources/<component-or-fix>/build \
      -DCMAKE_BUILD_TYPE=Release -DCMAKE_SKIP_RPATH=ON
cmake --build /data/usershare/kylinos-local-sources/<component-or-fix>/build --target ukui-system-tray -j$(nproc)
```

安装前至少检查：

```bash
readelf -d <new-lib> | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
readelf -d /usr/lib/aarch64-linux-gnu/qt5/qml/org/ukui/systemTray/libukui-system-tray.so | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
ldd <new-lib> | rg 'not found' || true
QT_QPA_PLATFORM=offscreen QML2_IMPORT_PATH=<staged-qml-import-root> qmlplugindump -nonrelocatable org.ukui.systemTray 1.0
```

`qmlplugindump` 会初始化插件并可能触发用户配置同步；执行后要复查 `$HOME/.config/org.ukui/_ukui-config-global/org.ukui.systemTray.json` 是否被意外改写。

手动替换单个插件库前，必须准备本地试装包：

```text
rollback/<timestamp>/system-backup/libukui-system-tray.so
rollback/<timestamp>/staged/libukui-system-tray.so
rollback/<timestamp>/original-build/libukui-system-tray.so
rollback/<timestamp>/SHA256SUMS
rollback/<timestamp>/restore.sh
```

## 验证

安装后重启面板：

```bash
pkill -x ukui-panel
pgrep -a ukui-panel || true
```

验证插件已加载：

```bash
pid=$(pgrep -n -x ukui-panel)
rg -F 'libukui-system-tray.so' /proc/$pid/maps
journalctl --user --since '2 minutes ago' --no-pager | rg -i 'ukui-panel|systemTray|system-tray|qml|crash|error|failed' || true
```

功能验证：

1. 确认截图、剪切板等目标项在 `fixedItems + orderedItems` 的 `separateIndex` 之后。
2. 确认目标项没有写入 `trayIconsInhibited`。
3. 重启面板后退出一个主显示区应用。
4. 检查截图、剪切板仍留在折叠/隐藏区，主显示区允许出现空位。

## 回滚

如果出现 `symbol lookup error`、面板崩溃、托盘缺失或 QML 加载失败，立即执行同目录回滚脚本：

```bash
pkexec /data/usershare/kylinos-local-sources/<component-or-fix>/rollback/<timestamp>/restore.sh
pkill -x ukui-panel
```

回滚后运行：

```bash
dpkg -V ukui-widget-system-tray || true
pgrep -a ukui-panel || true
```

