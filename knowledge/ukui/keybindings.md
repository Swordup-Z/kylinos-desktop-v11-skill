# KylinOS Desktop V11 UKUI 快捷键

此文档适用于 UKUI 全局快捷键设置、快捷键冲突、系统提示快捷键已被占用、全局搜索快捷键、窗口管理器快捷键和 `gsettings` 后端诊断。

## 目录

- 基础原则
- 诊断快捷键占用
- `Alt+Space` 与全局搜索冲突
- 验证与回滚

## 基础原则

1. UKUI 快捷键多数属于用户级 `gsettings` 配置，一般不需要维护模式。
2. 修改前先读取当前值，避免覆盖用户已有自定义快捷键。
3. 如果快捷键设置界面提示“已被系统占用”，不要只查 UKUI 自己的 media-keys，还要查窗口管理器兼容层，例如 `org.gnome.desktop.wm.keybindings`。
4. 修改后读取最终值，并让用户实际按键验证。

## 诊断快捷键占用

先搜索当前用户的快捷键配置：

```bash
gsettings list-recursively 2>/dev/null | rg -i '<Alt>space|<Alt>Space|Alt\+Space|window-menu|search|menu'
```

重点检查：

```bash
gsettings list-recursively org.gnome.desktop.wm.keybindings 2>/dev/null | rg -i 'space|menu|search'
gsettings list-recursively org.ukui.SettingsDaemon.plugins.media-keys 2>/dev/null | rg -i 'search|space|menu'
```

如果涉及全局搜索，确认相关进程存在：

```bash
ps -ef | rg -i 'ukui-search|ukui-settings-daemon' | rg -v rg
```

## `Alt+Space` 与全局搜索冲突

在 KylinOS Desktop V11/UKUI 中，`Alt+Space` 可能默认被窗口管理器用于激活窗口菜单：

```text
org.gnome.desktop.wm.keybindings activate-window-menu ['<Alt>space']
```

这会导致在设置界面把全局搜索改成 `Alt+Space` 时提示快捷键已被系统占用。若用户明确要把 `Alt+Space` 用作全局搜索，可以先释放窗口菜单快捷键，再设置 UKUI 全局搜索：

```bash
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "[]"
gsettings set org.ukui.SettingsDaemon.plugins.media-keys ukui-search '<Alt>space'
```

这会让 `Alt+Space` 不再打开窗口菜单，而是交给 UKUI 全局搜索使用。

## 验证与回滚

验证：

```bash
gsettings get org.gnome.desktop.wm.keybindings activate-window-menu
gsettings get org.ukui.SettingsDaemon.plugins.media-keys ukui-search
```

预期：

```text
@as []
'<Alt>space'
```

如果要恢复默认窗口菜单和默认搜索快捷键：

```bash
gsettings set org.gnome.desktop.wm.keybindings activate-window-menu "['<Alt>space']"
gsettings set org.ukui.SettingsDaemon.plugins.media-keys ukui-search '<Super>s'
```

