# KylinOS Desktop V11 KARE Namespace 与宿主机边界

此文档适用于 KARE 打包应用与宿主机 namespace 不一致、应用内 hostname 显示 `kare`、终端类应用从 KARE 启动、误启动 KARE 版 UKUI 面板、开始菜单固定项仍指向 KARE 入口等问题。

## 目录

- [主机名统一](#主机名统一)
- [KARE 应用内 hostname 不一致](#kare-应用内-hostname-不一致)
- [从 KARE 环境恢复 UKUI 面板](#从-kare-环境恢复-ukui-面板)

## 主机名统一

如果不同终端、shell prompt 或应用中显示的 hostname 不一致，先区分系统静态主机名、当前运行时主机名、`/etc/hosts` 本机解析和外部 DNS/代理解析。

诊断：

```bash
hostnamectl status
hostname
cat /etc/hostname
sed -n '1,20p' /etc/hosts
getent hosts <hostname>
rg -n '<old-hostname>|<new-hostname>' /etc/hostname /etc/hosts /etc/machine-info /etc/NetworkManager 2>/dev/null || true
```

修改主机名前必须处于维护模式，并先备份：

```bash
sudo cp -a /etc/hostname /etc/hostname.bak-$(date +%Y%m%d-%H%M%S)
sudo cp -a /etc/hosts /etc/hosts.bak-$(date +%Y%m%d-%H%M%S)
sudo hostnamectl set-hostname <new-hostname>
sudo sed -i 's/\b<old-hostname>\b/<new-hostname>/g' /etc/hosts
```

验证：

```bash
hostnamectl status
hostname
cat /etc/hostname
getent hosts <new-hostname>
```

如果旧主机名仍能通过 `getent hosts <old-hostname>` 解析，但 `/etc/hostname`、`/etc/hosts` 和系统配置中已无旧名，通常不是本机主机名残留，而是 DNS、mDNS、代理 fake-ip 或上游解析缓存返回的结果。不要为此继续改本机主机名文件。

## KARE 应用内 hostname 不一致

如果宿主机 `hostname` 已正确，但某个 KARE 打包应用内执行 `hostname` 仍显示 `kare`，先确认进程是否处于独立 UTS namespace：

```bash
ps -ef | rg -i '<app-name>|kare' | rg -v rg
readlink /proc/<pid>/ns/uts
readlink /proc/$$/ns/uts
tr '\0' ' ' < /proc/<pid>/cmdline
```

KARE 应用可能通过类似下面的桌面入口启动：

```desktop
Exec=/usr/bin/kare run <app-id> <app-command>
```

这类应用进入 KARE namespace 后，hostname 可能来自 KARE rootfs 的 `config.json`，例如：

```json
{
  "domainname": "kare",
  "hostname": "kare"
}
```

不要轻易把 KARE base 环境的 `config.json` 全局改成宿主机 hostname，因为这会影响同一 base_env 下的其他 KARE 应用。若只是终端类应用需要显示宿主机 hostname，优先检查是否能从宿主机直接启动该应用真实二进制，并用用户级 `.desktop` 覆盖 KARE 桌面入口。例如 Tabby 的 KARE 桌面入口可能指向：

```desktop
Exec=/usr/bin/kare run tabby-terminal /opt/Tabby/tabby --no-sandbox %U
```

如果真实二进制在宿主机可解析依赖，可以创建用户级入口：

```desktop
[Desktop Entry]
Name=Tabby
Comment=A terminal for a modern age
Exec=/opt/kare-applications/v10sp1/merge/opt/Tabby/tabby --no-sandbox %U
Terminal=false
Type=Application
Icon=/opt/kare-applications/v10sp1/merge/usr/share/icons/hicolor/512x512/apps/tabby.png
StartupWMClass=tabby
MimeType=x-scheme-handler/tabby;
Categories=System;TerminalEmulator;
```

保存到：

```bash
$HOME/.local/share/applications/tabby.desktop
```

然后刷新用户级 desktop database：

```bash
update-desktop-database "$HOME/.local/share/applications"
```

如果应用是从 UKUI 开始菜单的固定图标启动，还要检查开始菜单收藏项是否仍然指向 KARE 入口：

```bash
rg -n '<desktop-id>|<app-name>' "$HOME/.config/ukui-menu/favorite.json"
```

若收藏项仍是 `app:///opt/kare/usr/share/applications/<desktop-id>.desktop`，需要改成用户级入口，例如：

```text
app://$HOME/.local/share/applications/<desktop-id>.desktop
```

实际写入 `favorite.json` 时应使用展开后的绝对路径，例如 `app:///home/<user>/.local/share/applications/<desktop-id>.desktop`。修改后关闭并重新打开开始菜单；若开始菜单缓存未刷新，再考虑重启 `ukui-menu` 或重新登录。

如果之后已经把应用重装为宿主机原生版本，应删除之前创建的用户级覆盖入口，避免它继续遮蔽 `/usr/share/applications/<desktop-id>.desktop` 或在开始菜单里显示失效图标：

```bash
rm "$HOME/.local/share/applications/<desktop-id>.desktop"
update-desktop-database "$HOME/.local/share/applications"
rg -n '<app-name>|<desktop-id>' "$HOME/.local/share/applications" /usr/share/applications 2>/dev/null
```

验证时需要完全退出旧的 KARE 版应用实例，再从应用菜单重新启动；否则 Electron 单实例锁可能复用旧 KARE namespace。新进程应与宿主机处于同一个 UTS namespace，应用内 `hostname` 应显示宿主机 hostname。

如果 AI 工具当前就是从旧 KARE 版终端中启动的，当前进程也会位于 KARE UTS namespace 中；此时在工具里运行 `hostname` 仍会显示 `kare`。这不代表宿主机主机名修改失败。验证宿主机主机名时可以查看 KARE 暴露的宿主机映射：

```bash
hostnamectl status
cat /run/host/etc/hostname
sed -n '1,8p' /run/host/etc/hosts
readlink /proc/$$/ns/uts
```

当前 KARE namespace 若要临时改名，可在该 shell 中手动执行：

```bash
sudo hostname <new-hostname>
```

这只影响当前 KARE UTS namespace，不是持久化修复。持久化方案仍应优先使用宿主机 namespace 启动终端，或在维护模式下谨慎修改 KARE base 环境 `config.json`，并明确其会影响同一 `base_env` 下的其他 KARE 应用。

## 从 KARE 环境恢复 UKUI 面板

如果任务栏/面板消失，而当前 AI 工具或终端运行在 KARE namespace 中，不要直接执行当前环境里的 `/usr/bin/ukui-panel`。这会启动 KARE rootfs 中的面板，可能出现外观、插件、托盘和原宿主桌面不一致。

先确认现有会话和当前工具所在 namespace：

```bash
ps -ef | rg -i 'ukui-session|ukui-panel|kare' | rg -v rg
readlink /proc/<ukui-session-pid>/ns/mnt
readlink /proc/<ukui-session-pid>/ns/uts
readlink /proc/$$/ns/mnt
readlink /proc/$$/ns/uts
```

如果已经误启动了 KARE 里的面板，先停止对应的错误 `ukui-panel` 进程。再通过宿主用户服务管理器拉起面板，让新进程继承宿主会话 namespace：

```bash
DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$(id -u)/bus \
systemd-run --user --collect --unit=ukui-panel-manual-restore \
env DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_SESSION_TYPE=wayland /usr/bin/ukui-panel
```

验证新面板必须与 `ukui-session` 处于同一个 mount/UTS namespace：

```bash
readlink /proc/<ukui-panel-pid>/ns/mnt
readlink /proc/<ukui-session-pid>/ns/mnt
readlink /proc/<ukui-panel-pid>/ns/uts
readlink /proc/<ukui-session-pid>/ns/uts
```

这类恢复属于用户会话级操作，不需要维护模式；但如果后续要修改 `/usr`、`/etc`、`/opt` 或系统服务，仍必须先检查维护模式。
