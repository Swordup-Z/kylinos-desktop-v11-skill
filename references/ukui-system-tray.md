# UKUI 系统托盘

## 定位

这是任务栏右侧小图标顺序、隐藏区和持久化配置的分类入口。

## 适用场景

- 托盘图标顺序重启后不保留。
- 截图、剪切板等图标隐藏状态不持久。
- 需要调整 `systemTray.json`、`orderedItems`、`separateIndex`。

## 先读知识章节

- UKUI 系统托盘具体诊断和修复：[`../knowledge/ukui/system-tray.md`](../knowledge/ukui/system-tray.md)

## 最小诊断

```bash
find "$HOME/.config" -iname '*systemTray*' -o -iname '*tray*'
```
