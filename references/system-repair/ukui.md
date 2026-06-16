# 系统问题修复：UKUI 桌面

## 适用场景

- 开机自启动不生效或设置界面不显示。
- 全局搜索异常、软件商店结果异常、快捷键无法唤起。
- 右侧托盘隐藏/显示状态不持久、任务栏/面板异常。
- 输入法托盘显示异常、Fcitx5 主程序缺失、输入法默认项不符合预期。
- 桌面 AI 组件残留、AI 子系统卸载。

## 知识入口

进入 UKUI 索引后，按自启动、快捷键、全局搜索、托盘、输入法、桌面服务或 AI 组件残留继续读取具体知识；不要一次性读取整个 UKUI 目录。

- [`../../knowledge/system-repair/ukui/README.md`](../../knowledge/system-repair/ukui/README.md)

## 最小诊断

```bash
ps -ef | rg -i 'ukui|search|panel|tray' | rg -v rg
gsettings list-recursively org.ukui.search.settings 2>/dev/null || true
journalctl --user -b --no-pager | rg -i 'ukui|search|panel|tray' | tail -n 120
```
