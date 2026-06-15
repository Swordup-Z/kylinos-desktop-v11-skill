# KylinOS Desktop V11 应用安装与包管理

此文档适用于 KylinOS Desktop V11 上的桌面应用安装、AppImage 用户级集成、命令行安装边界、KARE 环境误装判断、第三方 apt 源残留和公钥缺失等问题。

## 目录

- 基础原则
- 宿主机命令行安装
- KARE 环境中安装软件包
- AppImage 用户级安装
- 用户级应用图标与 UKUI 开始菜单
- 第三方 apt 源残留或公钥缺失

## 基础原则

1. 先确认当前 shell 位于宿主机 namespace，避免把应用安装到 KARE rootfs/overlay。
2. 涉及 `/usr`、`/etc`、`/opt`、系统包、系统服务或 KSaf 策略时，先按维护模式流程处理。
3. 能做用户级安装的应用优先写入 `$HOME`，例如 AppImage 放到 `$HOME/Applications`，桌面入口放到 `$HOME/.local/share/applications`。
4. 安装前先确认 CPU 架构、包来源、应用入口和图标路径；安装后验证命令、桌面入口、进程 namespace 和重启后的持久性。

## 宿主机命令行安装

在 KylinOS Desktop V11 上安装桌面应用时，优先使用宿主机命令行安装，并在安装前进入维护模式，避免通过 KARE 环境中的终端、应用商店套壳或容器内 `apt/dpkg` 把应用安装到 KARE rootfs/overlay 中。

安装前先确认：

```bash
mm-cli -s
readlink /proc/$$/ns/mnt
readlink /proc/$$/ns/uts
hostname
```

只有确认当前是 maintain mode，并且当前 shell 位于宿主机 namespace，才继续执行 `apt install`、`dpkg -i`、`apt-get install ./<package>.deb` 等实际安装命令。若 `hostname` 显示 `kare`，或 namespace 与 `ukui-session` 不一致，说明当前很可能在 KARE 环境内，不应在该终端中安装宿主机应用。

安装完成后验证应用入口来自宿主机路径，而不是 KARE 入口：

```bash
command -v <app-command> || true
rg -n '<app-name>|<desktop-id>' /usr/share/applications "$HOME/.local/share/applications" 2>/dev/null
```

如果看到类似 `Exec=/usr/bin/kare run ...` 或路径位于 `/opt/kare`、`/opt/kare-applications`，说明它仍然是 KARE 应用；终端、开发工具、代理工具等需要访问宿主系统状态的应用，应优先使用原生宿主机安装。

## KARE 环境中安装软件包

如果当前终端或 AI 工具运行在 KARE namespace 中，直接执行 `apt`、`dpkg`、`sudo apt install` 等命令，修改的可能是 KARE rootfs/overlay，而不是宿主机系统。先确认当前环境：

```bash
readlink /proc/$$/ns/mnt
readlink /proc/$$/ns/uts
hostname
ls -l /run/host/usr/bin/<command> /usr/bin/<command> 2>/dev/null
```

在 KARE 环境里安装包时，可能出现下面这类非致命提示：

```text
sudo: 无法发送审核消息: 不允许的操作
GDBus.Error:org.freedesktop.DBus.Error.ServiceUnknown: The name org.freedesktop.PackageKit was not provided by any .service files
```

前者通常是 KARE/容器环境无法向宿主 audit 子系统发送审计消息；后者通常是 PackageKit 的 D-Bus 通知或软件中心刷新链路在当前 bus 中不可用。只要 `dpkg` 状态为 `ii`、命令可执行且版本正常，这些提示不一定代表安装失败：

```bash
command -v <command> && <command> --version
dpkg -l <package-name>
```

如果目标是修复宿主机系统包或宿主机命令，不能只看 KARE 内 `/usr/bin`。应在宿主机 namespace 中处理，且涉及 `/usr`、`/etc`、`/opt` 或系统包时必须先检查维护模式。

## AppImage 用户级安装

AppImage 通常不需要写入 `/usr`、`/opt` 或系统包数据库。优先做用户级安装，放到：

```bash
$HOME/Applications
```

并在用户级目录创建开始菜单入口：

```bash
$HOME/.local/share/applications/<app>.desktop
$HOME/.local/share/icons/hicolor/<size>/apps/<app>.png
```

安装前必须先检查 AppImage 架构，尤其是 ARM64 机器不要误装 x86-64 AppImage：

```bash
uname -m
dpkg --print-architecture
file "$HOME/下载/<app>.AppImage"
```

如果 `file` 显示 `x86-64`，而系统是 `aarch64`/`arm64`，不要创建桌面入口；应重新下载 arm64/aarch64 版本。安装后赋予执行权限：

```bash
chmod +x "$HOME/Applications/<app>.AppImage"
```

如果启动时报错：

```text
dlopen(): error loading libfuse.so.2
AppImages require FUSE to run.
```

说明系统缺少 FUSE 2 兼容库。即使系统已经安装 `libfuse3-3`，部分 AppImage 仍然需要 `libfuse2`。先诊断：

```bash
ldconfig -p 2>/dev/null | rg 'libfuse\.so\.2|libfuse3' || true
dpkg -l | rg '^ii\s+libfuse2(:\S+)?\s|^ii\s+libfuse3-3(:\S+)?\s' || true
apt-cache policy libfuse2 libfuse3-3
```

若确认缺少 `libfuse2`，且当前处于维护模式，安装：

```bash
sudo apt-get install libfuse2
```

安装后重新运行 AppImage，确认不再出现 `libfuse.so.2` 报错。若涉及系统包安装，完成后按维护模式流程保存修改、退出维护模式并重启验证。

可用 AppImage 自带的提取功能获取 desktop 文件和图标：

```bash
"$HOME/Applications/<app>.AppImage" --appimage-extract '*.desktop'
"$HOME/Applications/<app>.AppImage" --appimage-extract 'usr/share/icons/*'
```

创建或更新用户级 `.desktop` 后刷新数据库：

```bash
update-desktop-database "$HOME/.local/share/applications"
gtk-update-icon-cache -q "$HOME/.local/share/icons/hicolor" 2>/dev/null || true
desktop-file-validate "$HOME/.local/share/applications/<app>.desktop"
```

只有用户明确要求系统级部署到 `/opt` 或 `/usr/share/applications` 时，才按维护模式流程处理。

## 用户级应用图标与 UKUI 开始菜单

如果 AppImage 或手工安装应用的桌面图标正常，但 UKUI 开始菜单中的图标仍显示异常，优先检查用户级 `.desktop`、图标主题索引和 UKUI 菜单缓存，而不是直接改系统路径。

先诊断：

```bash
sed -n '1,120p' "$HOME/.local/share/applications/<app>.desktop"
find "$HOME/.local/share/icons" -iname '*<app>*' -print
desktop-file-validate "$HOME/.local/share/applications/<app>.desktop"
```

让 `.desktop` 使用标准图标名，并把图标放到用户级 `hicolor` 主题下：

```ini
Icon=<app>
```

```bash
mkdir -p "$HOME/.local/share/icons/hicolor/512x512/apps"
install -m 0644 "<source-icon>.png" "$HOME/.local/share/icons/hicolor/512x512/apps/<app>.png"
```

若 `$HOME/.local/share/icons/hicolor` 缺少 `index.theme`，`gtk-update-icon-cache` 可能无法可靠生成用户级图标缓存，导致桌面文件管理器能显示图标，但开始菜单仍解析失败。可以复制系统 `hicolor` 主题索引到用户级目录后刷新缓存：

```bash
mkdir -p "$HOME/.local/share/icons/hicolor"
install -m 0644 /usr/share/icons/hicolor/index.theme "$HOME/.local/share/icons/hicolor/index.theme"
gtk-update-icon-cache -f -q "$HOME/.local/share/icons/hicolor"
update-desktop-database "$HOME/.local/share/applications"
```

刷新后重启或重新加载开始菜单进程：

```bash
pkill -x ukui-menu || true
systemd-run --user --collect --unit=ukui-menu-refresh \
  env DISPLAY=:0 WAYLAND_DISPLAY=wayland-0 XDG_SESSION_TYPE=wayland XDG_CURRENT_DESKTOP=UKUI \
  /usr/bin/ukui-menu
```

如果应用已固定到开始菜单收藏，还要确认收藏项指向的是用户级 `.desktop`：

```bash
rg -n '<app>|<desktop-id>' "$HOME/.config/ukui-menu/favorite.json" "$HOME/.local/share/applications" 2>/dev/null
```

此类修复属于用户级配置，一般不需要维护模式；只有要写入 `/usr/share/icons`、`/usr/share/applications` 或安装系统包时，才按维护模式流程处理。

## 第三方 apt 源残留或公钥缺失

如果 `apt update` 因第三方源缺失公钥失败，例如：

```text
NO_PUBKEY <key-id>
仓库 “<repo-url>” 没有数字签名
```

先判断用户是否还需要该第三方应用。若用户明确要删除该应用，或系统中已经没有对应包、命令、桌面入口和进程，应清理残留 apt 源，而不是继续修复公钥。

诊断：

```bash
dpkg -l | rg -i '<app-name>|<package-name>' || true
command -v <app-command> 2>/dev/null || true
find /usr/share/applications "$HOME/.local/share/applications" -maxdepth 1 -iname '*<app-name>*' -print 2>/dev/null
ps -ef | rg -i '<app-name>|<package-name>' | rg -v rg || true
rg -n '<repo-domain>|<app-name>' /etc/apt /etc/apt/sources.list.d 2>/dev/null || true
```

如果确认只剩源配置残留，且当前处于维护模式，可以删除对应源文件和已无用 keyring：

```bash
sudo rm /etc/apt/sources.list.d/<repo>.sources
sudo rm /usr/share/keyrings/<repo>-archive-keyring.gpg 2>/dev/null || true
sudo apt-get update
```

验证 `apt-get update` 不再访问该第三方源，也不再出现 `NO_PUBKEY` 或“没有数字签名”错误。

如果用户仍要保留该应用，应改为按厂商官方文档重新安装 keyring，并确认 `Signed-By=` 指向的 keyring 文件存在；不要在未确认来源时导入未知公钥。
