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

如果开始菜单里出现一个不可用的 KARE 入口，同时用户实际使用的是宿主机路径或另一个可用入口，优先使用用户级 `.desktop` 覆盖，不直接删除 `/opt/kare` 下的文件。若用户明确要求直接删除，必须先确认维护模式，并区分“桌面入口/命令残留”、“KARE 运行期元数据”和“应用本体目录”；不要删除仍在使用的应用本体。

尤其要注意 `/opt/apps/<app>/<app>` 这类宿主启动脚本。它表面上位于宿主路径，但内部可能仍通过 KARE app-id 启动：

```bash
sed -n '1,80p' /opt/apps/<app>/<app>
```

如果脚本包含 `/usr/bin/kare run <app-id> ...`，则 `/opt/kare/usr/share/applications/<app-id>.desktop` 和 `/opt/kare/usr/bin/<app-id>` 可能是运行期元数据，不是纯菜单残留。此时不要删除这些文件；应保留或恢复它们，并在 KARE desktop 中设置 `NoDisplay=true` 隐藏菜单入口，再用用户级可见入口承接开始菜单和 MIME 默认值。

Firefox/Zen 类浏览器不适合长期放在每次 `kare run` 都创建新 namespace 的入口上。双击本地 HTML 或再次打开 URL 时，新实例可能看到同一个 profile 的 `lock`，但无法把打开请求转发给已有实例，于是提示 “already running, but is not responding”。若真实浏览器二进制在 KARE overlay 中能直接从宿主运行，可以复制为宿主原生目录，再把 `.desktop` 和 MIME 默认值改到宿主 wrapper；但在飞腾 FTG 图形栈上还要先按硬件章节评估是否需要禁用浏览器硬件加速，避免原生运行后触发 ES30/FTG devfreq 卡死。

如果宿主原生 Zen 已经可用，后续升级优先使用官方 `zen.linux-<arch>.tar.xz` 包直接替换宿主安装目录，不要再换回 KARE 入口，也不要在这类系统上优先使用 AppImage。AppImage 会额外引入 FUSE/沙箱/集成层变量，不能解决 profile 单实例路由问题，排障面更大。

升级流程要点：

1. 先确认维护模式、架构、当前版本和运行进程：

```bash
mm-cli -s
uname -m
/usr/local/bin/zen-browser --version
pgrep -a -f '/opt/zen-browser/zen' || true
```

2. 从官方 release 下载与架构匹配的 `zen.linux-<arch>.tar.xz`，并用 release API 或发布页提供的 sha256 digest 做校验。校验失败不得安装。
3. 解包到临时目录后先验证二进制：

```bash
file /tmp/<workdir>/zen/zen
/tmp/<workdir>/zen/zen --version
```

4. 替换前正常关闭当前 Zen 主进程，确认没有 `/opt/zen-browser/zen` 残留，再备份旧目录并安装新目录：

```bash
kill -TERM <main-zen-pid>
pgrep -a -f '/opt/zen-browser/zen' || true
mv /opt/zen-browser /opt/zen-browser.backup-<date>
mv /tmp/<workdir>/zen /opt/zen-browser
chown -R root:root /opt/zen-browser
```

5. 保留原有宿主 wrapper，不要让 `.desktop` 直接执行 `/opt/zen-browser/zen`。在 FTG 图形栈机器上，wrapper 应继续携带软件渲染保护：

```sh
#!/bin/sh
export MOZ_X11_EGL=0
export MOZ_ENABLE_WAYLAND=0
export MOZ_WEBRENDER=0
export MOZ_DISABLE_GPU_SANDBOX=1
export LIBGL_ALWAYS_SOFTWARE=1
exec /opt/zen-browser/zen "$@"
```

6. 验证版本、桌面入口、MIME 默认值、本地 HTML 二次打开和日志：

```bash
/usr/local/bin/zen-browser --version
desktop-file-validate "$HOME/.local/share/applications/zen-browser.desktop"
xdg-mime query default x-scheme-handler/http
xdg-mime query default text/html
gio open /path/to/local.html
journalctl -k --since '5 minutes ago' --no-pager | rg -i 'es30|texture|webrender|gpu|devfreq|ftg|error|failed'
journalctl --user --since '5 minutes ago' --no-pager | rg -i 'zen|already running|profile|lock|responding|crash|failed'
```

验证通过的状态应是：主进程仍为 `/opt/zen-browser/zen`，再次打开本地 HTML 只转发到已有主进程并新增内容进程，不再出现 profile lock 或 “already running” 报错；内核日志不应新增 `failed to set ftg frequency`、`devfreq ... dvfs failed` 或连续 `ES30:texture` 错误。用户日志中单独的 GTK 主题 warning 或 UKUI transient scope warning 通常不是 Zen 启动失败。

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

用户明确要求删除时，只能删除已验证不被当前可用启动链路依赖的 KARE 暴露入口。如果 `/opt/apps/<app>/<app>`、面板固定项、MIME 默认值或应用日志仍引用相同 app-id，改用 `NoDisplay=true` 隐藏，不要删除。确认为无依赖后才可删除，例如：

```bash
mm-cli -s
rm -f /opt/kare/usr/share/applications/<bad-id>.desktop
rm -f /opt/kare/usr/bin/<bad-command>
rm -f /opt/kare-applications/<version>/upper/usr/share/applications/<bad-id>.desktop
rm -f /opt/kare-applications/<version>/upper/usr/bin/<bad-command>
```

如果已经误删了 KARE 运行期元数据，恢复时优先把 KARE 入口设为隐藏，而不是重新暴露成开始菜单中的第二个应用：

```ini
[Desktop Entry]
Type=Application
Name=<App Name>
Exec=/usr/bin/kare run <app-id> <app-command> %u
Icon=<app-id>
NoDisplay=true
Categories=Network;WebBrowser;
```

```bash
install -D -m 0644 <restored>.desktop /opt/kare/usr/share/applications/<app-id>.desktop
install -D -m 0755 <restored-command> /opt/kare/usr/bin/<app-id>
install -D -m 0644 <restored>.desktop /opt/kare-applications/<version>/upper/usr/share/applications/<app-id>.desktop
install -D -m 0755 <restored-command> /opt/kare-applications/<version>/upper/usr/bin/<app-id>
```

如果 `merge/` 视图仍显示旧文件但 `upper/` 源文件已经消失，通常是 overlay 合并视图未刷新。不要为了清一个菜单项强行重挂 KARE overlay，尤其是相关应用仍在运行时；重启 KARE 或系统后再复查。

确需刷新 KARE overlay 时，先关闭相关应用并确认没有进程仍使用目标应用路径。不要直接依赖 `systemctl restart var-opt-kare...merge-usr.mount` 这类从 `/proc/self/mountinfo` 生成的运行时 mount unit；它可能先卸载成功，再因为没有持久 mount 参数而挂载失败，导致 `merge/usr` 暂时不是挂载点。若已经发生这种情况，按 `findmnt` 中原始参数手动挂回：

```bash
mount -t overlay overlay \
  -o lowerdir=/opt/kare-applications/base/kare-v10sp1/usr:/opt/kare-applications/host/usr,upperdir=/opt/kare-applications/v10sp1/upper/usr,workdir=/opt/kare-applications/v10sp1/work/usr \
  /var/opt/kare-applications/v10sp1/merge/usr
```

重挂后验证：

```bash
mountpoint /var/opt/kare-applications/v10sp1/merge/usr
findmnt -T /var/opt/kare-applications/v10sp1/merge/usr
```

验证时确认：

```bash
command -v <app>
xdg-mime query default x-scheme-handler/http
xdg-mime query default x-scheme-handler/https
xdg-mime query default text/html
gio mime text/html 2>/dev/null
desktop-file-validate "$HOME/.local/share/applications/<good-id>.desktop"
```
