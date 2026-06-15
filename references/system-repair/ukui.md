# 系统问题修复：UKUI 桌面

## 适用场景

- 开机自启动不生效或设置界面不显示。
- 全局搜索异常、软件商店结果异常、快捷键无法唤起。
- 右侧托盘隐藏/显示状态不持久、任务栏/面板异常。
- 桌面 AI 组件残留、AI 子系统卸载。

## 按子场景读取

- 开机自启动不生效或设置界面不显示：[`../../knowledge/system-repair/ukui/autostart.md`](../../knowledge/system-repair/ukui/autostart.md)
- 快捷键冲突、全局搜索快捷键无法唤起：[`../../knowledge/system-repair/ukui/keybindings.md`](../../knowledge/system-repair/ukui/keybindings.md)
- 全局搜索结果来源异常、软件商店结果异常：[`../../knowledge/system-repair/ukui/search.md`](../../knowledge/system-repair/ukui/search.md)
- 右侧托盘隐藏/显示状态不持久、顺序异常：[`../../knowledge/system-repair/ukui/system-tray.md`](../../knowledge/system-repair/ukui/system-tray.md)
- 托盘问题必须源码级修复：[`../../knowledge/system-repair/ukui/system-tray-source.md`](../../knowledge/system-repair/ukui/system-tray-source.md)
- 桌面服务启动顺序、D-Bus activation、面板/任务栏异常：[`../../knowledge/system-repair/ukui/system-service-manager.md`](../../knowledge/system-repair/ukui/system-service-manager.md)
- 桌面 AI 组件、AI 子系统和残留清理：[`../../knowledge/system-repair/ukui/ai-subsystem.md`](../../knowledge/system-repair/ukui/ai-subsystem.md)

## 最小诊断

```bash
ps -ef | rg -i 'ukui|search|panel|tray' | rg -v rg
gsettings list-recursively org.ukui.search.settings 2>/dev/null || true
journalctl --user -b --no-pager | rg -i 'ukui|search|panel|tray' | tail -n 120
```
