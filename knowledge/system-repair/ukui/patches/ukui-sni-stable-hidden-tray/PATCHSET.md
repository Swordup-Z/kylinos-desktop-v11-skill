# UKUI 托盘隐藏区稳定性 Patch 集

## 功能目标

让 UKUI 右侧托盘按配置中的持久顺序划分主显示区和折叠/隐藏区。主显示区应用退出时，不从折叠区自动补位显示截图、剪切板等隐藏项。

## 类型与场景

- 需求类型：系统问题修复。
- 实际场景：UKUI 托盘。
- 知识入口：`knowledge/system-repair/ukui/system-tray-source.md`。

## 上游与基线

- 上游仓库：`https://gitee.com/openkylin/ukui-sni.git`
- 源码包：`ukui-sni`
- 相关二进制包：`ukui-widget-system-tray`
- 已验证系统包版本：`4.21.0.2-ok0.1k0.10`
- 基线节点：tag `build/4.21.0.2-ok0.1`，commit `3b2b1a6abaf2f1d5b083060b56bbfe69c04bad15`
- 本地功能分支：`codex/stable-hidden-tray`
- patch 文件：`ukui-sni-stable-hidden-tray.patch`
- 验证状态：`installed-pending-runtime-verification`

## 套用策略

现场修复时先确认当前系统包版本：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' ukui-widget-system-tray
apt-cache policy ukui-widget-system-tray
```

然后获取当前系统对应源码：

```bash
git clone https://gitee.com/openkylin/ukui-sni.git
cd ukui-sni
git fetch --all --tags
git checkout <current-system-matched-node>
```

套用：

```bash
git apply <patch-file>
```

如果冲突，必须分析 `TrayItemsModel`、`ItemGroupModel` 和当前源码的托盘排序/过滤逻辑：

- 如果新版本已经按持久配置序号区分主显示区和折叠区，记录现有实现并停止重复套用。
- 如果只是角色名、模型字段或文件位置变化，按“用配置序号判断隐藏区边界”的语义手工迁移。
- 如果托盘模型架构变化，重新确认 `fixedItems`、`orderedItems`、`separateIndex` 和运行时行号之间的关系，再设计最小补丁。

冲突处理后重新构建、试装和验证，并导出新的 patch 更新本目录。

## 安装前验证

至少验证：

```bash
readelf -d <build>/ukui-system-tray/libukui-system-tray.so | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
ldd <build>/ukui-system-tray/libukui-system-tray.so | rg 'not found' || true
```

## 运行时验证

- `systemTray.json` 中截图、剪切板位于 `separateIndex` 分界之后。
- 重启 `ukui-panel` 后，隐藏项仍在隐藏区。
- 退出主显示区应用后，隐藏区图标不会自动补位到主显示区。

## DATA 工作区映射

当前机器现场工作区：

```text
/data/usershare/kylinos-local-sources/ukui-panel-tray-hidden-stable/
```

现场工作区用于保存当前机器源码树、构建和回滚状态；本目录用于保存可复用 patch 知识。
