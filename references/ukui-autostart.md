# UKUI 开机自启动

## 定位

这是 UKUI 开机自启动不生效、设置界面不显示启动项的分类入口。

## 适用场景

- `~/.config/autostart` 中有 `.desktop` 但未自启动。
- UKUI 设置界面看不到新增启动项。
- KARE/Kaiming 应用图标路径导致自启动项过滤。

## 先读知识章节

- UKUI 自启动具体诊断、设置后端和持久化修复：[`../knowledge/ukui/autostart.md`](../knowledge/ukui/autostart.md)

## 最小诊断

```bash
ls -la "$HOME/.config/autostart"
gsettings list-recursively org.ukui.control-center | rg 'auto|sort|status' || true
```
