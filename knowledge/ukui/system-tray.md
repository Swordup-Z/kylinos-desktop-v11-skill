# UKUI 右侧托盘小图标顺序与隐藏区

此流程用于 KylinOS Desktop V11/UKUI 上“任务栏右侧小图标位置或隐藏区规则重启应用/重启系统后不保留”的问题。这里的小图标指系统托盘/StatusNotifier 图标，不是左侧固定应用大图标。

## 目录

- 关键结论
- 检查当前托盘配置
- 修复排序不保留
- 验证
- 排查被覆盖

## 关键结论

- UKUI 右侧托盘配置保存在用户级文件 `$HOME/.config/org.ukui/_ukui-config-global/org.ukui.systemTray.json`。
- `orderedItems` 记录普通托盘图标顺序；`fixedItems` 记录固定在右侧的特殊项；`controlPanelItems` 记录音量、蓝牙、网络等控制区图标；`separateIndex` 记录显示区和折叠/隐藏区的分界。
- 如果某个常驻托盘图标没有进入 `orderedItems`、`fixedItems` 或 `controlPanelItems`，它通常会按 StatusNotifier 注册顺序插入，重启应用或重启系统后位置容易变化。
- `separateIndex` 应与希望显示在主托盘区域的 `orderedItems` 数量匹配；`orderedItems` 中位于该分界之后的项目进入折叠/隐藏区。
- `separateIndex` 更接近“主托盘显示区容量”而不是“固定可见项集合”。如果分界前的某个应用退出，例如蓝信退出后 `orderedItems` 前段少了一个已注册项目，UKUI 面板可能会从分界后的已注册项目中补位到主托盘显示区，导致原本在折叠区的截图或剪切板显示出来。这是当前配置模型/面板逻辑的限制，不是配置没有保存。
- 如果目标是“某些 ID 永远主显示，某些 ID 永远折叠；主显示项退出时不从折叠区补位”，单靠 `systemTray.json` 的 `orderedItems` + `separateIndex` 通常做不到，需要面板托盘逻辑支持显式可见列表/隐藏列表，或源码级修改。
- 临时托盘项通常不要写入排序配置；但如果用户明确要求某个临时项持久进入隐藏区，例如截图工具，可以把该项 ID 写入 `orderedItems` 并放到 `separateIndex` 分界之后。
- “隐藏到折叠区”和“抑制显示”不是一回事：要把图标收进隐藏/折叠区，应调整 `orderedItems` 和 `separateIndex`；不要把它写入 `trayIconsInhibited`。
- `trayIconsInhibited` 会抑制图标显示，效果接近从托盘中不显示；除非用户明确要禁用显示，否则不要写入该列表。
- 修改该用户级 JSON 不需要维护模式；但修改 `/usr`、`/etc`、`/opt` 下的系统文件仍需按通用维护流程检查维护模式。

## 检查当前托盘配置

```bash
sed -n '1,240p' "$HOME/.config/org.ukui/_ukui-config-global/org.ukui.systemTray.json"
stat "$HOME/.config/org.ukui/_ukui-config-global/org.ukui.systemTray.json"
```

检查当前注册的 StatusNotifier 项：

```bash
busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems
busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItemPids
```

查看托盘项的稳定 ID、标题和图标名：

```bash
items=$(busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems | sed -E 's/^as [0-9]+ //; s/"//g')
for item in $items; do
  svc=${item%%/*}
  path=/${item#*/}
  echo "== $svc $path"
  busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem Id 2>/dev/null || true
  busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem Title 2>/dev/null || true
  busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem IconName 2>/dev/null || true
  busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem Status 2>/dev/null || true
done
```

常见 ID 示例：

```text
Fcitx
ukui-power-manager-tray
ukui-clipboard-tray
ukui-volume-control-applet-qt
ukui-bluetooth
kylin-nm
ukui-sidebar
```

部分第三方应用的 ID 可能不直观，例如 Clash Verge Rev 可能注册为 `tray-icon tray app main`，蓝信可能注册为 `1`。这类项应以现场 StatusNotifier 属性为准。

截图工具常见 ID 是 `麒麟截图`。如果用户说“隐藏截图托盘图标”，通常应理解为放入折叠区，而不是写入 `trayIconsInhibited`。

## 修复排序不保留

先备份配置：

```bash
cp "$HOME/.config/org.ukui/_ukui-config-global/org.ukui.systemTray.json" \
   "$HOME/.config/org.ukui/_ukui-config-global/org.ukui.systemTray.json.bak.$(date +%Y%m%d%H%M%S)"
```

把常驻托盘项加入 `orderedItems`，并按期望顺序排列。示例：

```json
{
    "controlPanelItems": [
        "ukui-volume-control-applet-qt",
        "ukui-bluetooth",
        "kylin-nm"
    ],
    "fixedItems": [
        "ukui-sidebar"
    ],
    "orderedItems": [
        "ukui-power-manager-tray",
        "Fcitx",
        "tray-icon tray app main",
        "1",
        "kylin-virtual-keyboard",
        "kylin-vpn"
    ],
    "separateIndex": 6,
    "trayIconsCanInhibited": [
        "Fcitx",
        "ukui-power-manager-tray"
    ],
    "trayIconsInhibited": [
    ],
    "version": "2.4"
}
```

`separateIndex` 应与希望显示在主托盘区域的 `orderedItems` 数量匹配。`orderedItems` 中位于 `separateIndex` 分界后的项目会进入折叠/隐藏区。底部面板通常用 `RightToLeft` 布局显示，视觉上的左右顺序可能和 JSON 数组顺序相反；判断显示/折叠时以分界和实际截图为准。

如果要保留电池、输入法、蓝信和 Clash 在主托盘，同时让剪切板和截图进入隐藏区，可把前 4 个作为显示区，剪切板和截图放在分界之后。示例：

```json
{
    "orderedItems": [
        "ukui-power-manager-tray",
        "Fcitx",
        "1",
        "tray-icon tray app main",
        "麒麟截图",
        "ukui-clipboard-tray",
        "kylin-virtual-keyboard",
        "kylin-vpn"
    ],
    "separateIndex": 4,
    "trayIconsInhibited": [
    ]
}
```

上例中 `separateIndex` 为 4，因此 `ukui-power-manager-tray`、`Fcitx`、`1`、`tray-icon tray app main` 留在主托盘，`麒麟截图`、`ukui-clipboard-tray` 以及后续项目进入折叠/隐藏区。若某个第三方应用的 ID 变化，应先用 StatusNotifier 属性重新确认 ID。

## 验证

重启用户级面板：

```bash
pkill -x ukui-panel
```

等待面板自动拉起后检查：

```bash
pgrep -a ukui-panel || true
sed -n '1,240p' "$HOME/.config/org.ukui/_ukui-config-global/org.ukui.systemTray.json"
```

如果文件在面板重启后仍保留新 `orderedItems`，说明配置已落盘。

## 排查被覆盖

如果重启系统后排序又被还原，检查 UKUI 云同步或配置同步是否接管：

```bash
gsettings list-recursively org.ukui.cloudsync.panel
gsettings list-recursively org.ukui.cloudsync.quicklaunch
ps -ef | rg -i 'cloudsync|conf2-sync|quicklaunch|panel' | rg -v rg
```

如果云同步状态未启用、数据为 `nil`，通常不是云同步覆盖。
