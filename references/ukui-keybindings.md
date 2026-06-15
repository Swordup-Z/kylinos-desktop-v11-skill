# UKUI 快捷键

## 定位

这是 UKUI 全局快捷键、全局搜索快捷键和 `Alt+Space` 冲突的分类入口。

## 适用场景

- 设置界面提示快捷键被系统占用。
- 想设置全局搜索显示/隐藏快捷键。
- `Alt+Space` 与窗口菜单或系统保留快捷键冲突。

## 先读知识章节

- UKUI 快捷键诊断和修复：[`../knowledge/ukui/keybindings.md`](../knowledge/ukui/keybindings.md)

## 最小诊断

```bash
gsettings list-recursively | rg -i 'keybinding|shortcut|search|space'
```
