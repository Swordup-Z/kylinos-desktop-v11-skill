# 用户级桌面入口与开始菜单图标

## 适用场景

- 手工安装应用或 AppImage 的桌面图标异常。
- 桌面文件管理器图标正常，但 UKUI 开始菜单中图标异常。
- 需要删除或修复无效开始菜单入口。

不适用于应用二进制安装失败或第三方 apt 源错误。

## 诊断

```bash
sed -n '1,120p' "$HOME/.local/share/applications/<app>.desktop"
find "$HOME/.local/share/icons" -iname '*<app>*' -print
desktop-file-validate "$HOME/.local/share/applications/<app>.desktop"
rg -n '<app>|<desktop-id>' "$HOME/.local/share/applications" /usr/share/applications 2>/dev/null || true
```

如果同一个应用同时存在宿主机安装版本和 KARE/Kaiming 入口，必须同时检查桌面入口、命令路径和 MIME 默认值：

```bash
command -v <app-command> || true
which -a <app-command> 2>/dev/null || true
find /usr/share/applications "$HOME/.local/share/applications" \
  /opt/kare/usr/share/applications /opt/kaiming/share/applications \
  -maxdepth 1 -type f -iname '*<app>*desktop' -print 2>/dev/null
xdg-mime query default x-scheme-handler/http || true
xdg-mime query default x-scheme-handler/https || true
xdg-mime query default text/html || true
gio mime text/html 2>/dev/null || true
```

如果应用已固定到开始菜单收藏，还要检查收藏项：

```bash
rg -n '<app-name>|<desktop-id>' "$HOME/.config/ukui-menu/favorite.json" 2>/dev/null || true
```

## 图标修复

让 `.desktop` 使用标准图标名：

```ini
Icon=<app>
```

UKUI 开始菜单中不要优先使用绝对 SVG 路径作为 `Icon=` 的长期配置。实际观察到用户级 `.desktop` 写成
`Icon=$HOME/.local/share/icons/hicolor/scalable/apps/<app>.svg` 后，UKUI 菜单可能在旧 QML/图标缓存存在时反复刷新或闪屏。
更稳妥的做法是使用标准图标名 `Icon=<app>`，把图标放到用户级 hicolor 主题，并补齐 hicolor 的 `index.theme` 后刷新缓存。

把图标放到用户级 `hicolor` 主题下：

```bash
mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps"
install -m 0644 "<source-icon>.png" "$HOME/.local/share/icons/hicolor/512x512/apps/<app>.png"
```

若 `$HOME/.local/share/icons/hicolor` 缺少 `index.theme`，开始菜单可能无法解析用户级图标。可以复制系统主题索引后刷新缓存：

```bash
mkdir -p "$HOME/.local/share/icons/hicolor"
install -m 0644 /usr/share/icons/hicolor/index.theme "$HOME/.local/share/icons/hicolor/index.theme"
gtk-update-icon-cache -f -q "$HOME/.local/share/icons/hicolor"
update-desktop-database "$HOME/.local/share/applications"
```

## 刷新 UKUI 菜单

```bash
pkill -x ukui-menu || true
systemd-run --user --collect --unit=ukui-menu-refresh \
  env DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=UKUI \
  /usr/bin/ukui-menu
```

如果开始菜单区域持续闪屏，先确认是否存在 `ukui-menu` 反复生成 transient scope：

```bash
pgrep -a ukui-menu || true
systemctl --user list-units 'app-ukui-menu*' --all --no-pager || true
journalctl --user --since '5 minutes ago' --no-pager | rg -i 'ukui-menu|qml|icon|desktop' | tail -n 120
```

若 `.desktop` 已恢复为标准图标名但仍闪屏，可以清理用户级 UKUI 菜单缓存后只重启一次菜单：

```bash
mv "$HOME/.cache/ukui/ukui-menu" "$HOME/.cache/ukui/ukui-menu.backup.$(date +%Y%m%d-%H%M%S)" 2>/dev/null || true
pkill -x ukui-menu || true
```

正常情况下会话会自动拉起一个新的 `/usr/bin/ukui-menu`。清理的是缓存目录，不会删除收藏配置；收藏配置通常在
`$HOME/.config/ukui-menu/favorite.json`。

这类修复属于用户级配置，一般不需要维护模式；只有要写入 `/usr/share/icons`、`/usr/share/applications` 或安装系统包时，才按维护模式流程处理。

## 隐藏 KARE 残留入口并保留可用宿主入口

如果开始菜单里出现一个不可用的 KARE 入口，同时用户实际使用的是宿主机路径或另一个可用入口，优先使用用户级 `.desktop` 覆盖，不直接删除 `/opt/kare` 下的文件。若用户明确要求直接删除，必须先确认维护模式，并区分“桌面入口/命令残留”和“应用本体目录”；不要删除仍在使用的应用本体。

典型做法：

1. 新增一个明确可用的用户级入口，例如 `$HOME/.local/share/applications/<app>-browser.desktop`，`Exec=` 指向已验证可用的宿主命令或启动脚本。
2. 用同名用户级 desktop ID 覆盖 KARE 入口，例如 `$HOME/.local/share/applications/<bad-id>.desktop`：

```ini
[Desktop Entry]
Type=Application
Name=<App Name>
NoDisplay=true
Hidden=true
```

3. 将 `x-scheme-handler/http`、`x-scheme-handler/https`、`text/html` 等默认应用统一到可用入口：

```bash
xdg-mime default <good-id>.desktop x-scheme-handler/http
xdg-mime default <good-id>.desktop x-scheme-handler/https
xdg-mime default <good-id>.desktop text/html
xdg-settings set default-web-browser <good-id>.desktop 2>/dev/null || true
update-desktop-database "$HOME/.local/share/applications"
```

4. 如果命令行 `command -v <app>` 仍优先命中 `/opt/kare/usr/bin/<app>`，且桌面会话 `PATH` 中 `$HOME/.local/bin` 位于 `/usr/bin` 和 `/opt/kare/usr/bin` 之前，可增加用户级 wrapper：

```bash
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/<app>" <<'EOF'
#!/bin/sh
exec /path/to/working/app "$@"
EOF
chmod 755 "$HOME/.local/bin/<app>"
```

5. 若 UKUI 面板或收藏固定的是旧 desktop ID，同步改为新 desktop ID，再刷新菜单。

用户明确要求删除时，可只删除已验证无效的 KARE 暴露入口，例如：

```bash
mm-cli -s
rm -f /opt/kare/usr/share/applications/<bad-id>.desktop
rm -f /opt/kare/usr/bin/<bad-command>
rm -f /opt/kare-applications/<version>/upper/usr/share/applications/<bad-id>.desktop
rm -f /opt/kare-applications/<version>/upper/usr/bin/<bad-command>
```

如果 `merge/` 视图仍显示旧文件但 `upper/` 源文件已经消失，通常是 overlay 合并视图未刷新。不要为了清一个菜单项强行重挂 KARE overlay，尤其是相关应用仍在运行时；重启 KARE 或系统后再复查。

验证时确认：

```bash
command -v <app>
xdg-mime query default x-scheme-handler/http
xdg-mime query default x-scheme-handler/https
xdg-mime query default text/html
gio mime text/html 2>/dev/null
desktop-file-validate "$HOME/.local/share/applications/<good-id>.desktop"
```
