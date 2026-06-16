# 宿主机命令行安装应用

## 适用场景

- 用户要通过 `apt`、`apt-get install ./<package>.deb` 或 `dpkg -i` 安装宿主机应用。
- 需要避免应用被安装到 KARE rootfs/overlay。
- 需要确认当前终端是否在宿主机 namespace。

不适用于 AppImage 用户级安装、第三方 apt 源清理或 KARE 应用桌面入口修复；这些场景读取本目录其他章节。

## 基础原则

1. 涉及 `/usr`、`/etc`、`/opt`、系统包或系统服务前，先检查维护模式。
2. 优先在宿主机 namespace 的终端中安装桌面应用。
3. 安装前确认架构、包来源、命令入口和桌面入口；安装后验证进程路径和 namespace。

## 安装前诊断

```bash
mm-cli -s
readlink /proc/$$/ns/mnt
readlink /proc/$$/ns/uts
hostname
dpkg --print-architecture
```

只有当前是 maintain mode，且当前 shell 位于宿主机 namespace，才继续执行实际安装命令。若 `hostname` 显示 `kare`，或 namespace 与 `ukui-session` 不一致，当前很可能在 KARE 环境内，不应在该终端中安装宿主机应用。

## 安装

`.deb` 包优先使用 apt 处理依赖：

```bash
sudo apt-get install ./<package>.deb
```

如果本地包位于中文路径、权限较窄的用户目录或 KARE 映射路径，`apt` 可能提示 `_apt` 无法访问本地文件并退回 root 读取。为减少路径和权限干扰，可先复制到纯英文临时目录再安装：

```bash
mkdir -p /tmp/<app-install>
cp "$HOME/下载/<package>.deb" /tmp/<app-install>/<package>.deb
pkexec apt-get install -y /tmp/<app-install>/<package>.deb
```

只有确认依赖已经满足或需要先解包排错时，才使用：

```bash
sudo dpkg -i <package>.deb
sudo apt-get -f install
```

## 供应商 deb 包内路径异常

个别第三方 `.deb` 包自身打包错误，可能在包内容里包含根目录文件，例如 `./<package>.deb`。安装时报错类似：

```text
无法创建 /<package>.deb.dpkg-new (处理 ./<package>.deb 时): 不允许的操作
```

这不是外部安装包所在路径的问题，而是包内路径会落到系统根目录。先确认包内容和安装脚本是否引用该根目录文件：

```bash
dpkg-deb -c /tmp/<app-install>/<package>.deb | rg '<package>|^[-d].* \./[^u]'
rm -rf /tmp/<app-control>
mkdir -p /tmp/<app-control>
dpkg-deb -e /tmp/<app-install>/<package>.deb /tmp/<app-control>
rg -n '<package>|/<package>|dpkg|apt|cp .*deb|rm .*deb' /tmp/<app-control>
```

如果确认该根目录文件只是供应商打包残留，且控制脚本不依赖它，可以用 dpkg 的路径排除选项做最小修复，避免重打包整个第三方包：

```bash
apt-get -s -o Dpkg::Options::=--path-exclude=/<package>.deb install /tmp/<app-install>/<package>.deb
pkexec apt-get -o Dpkg::Options::=--path-exclude=/<package>.deb install -y /tmp/<app-install>/<package>.deb
```

不要把 `--path-exclude` 用成宽泛规则；只排除已确认错误的单个根目录残留文件。安装后验证该文件没有出现在 `/`，并确认包状态、服务和桌面入口正常。

## 验证

```bash
command -v <app-command> || true
dpkg -l | rg -i '<package-or-app>' || true
rg -n '<app-name>|<desktop-id>' /usr/share/applications "$HOME/.local/share/applications" 2>/dev/null || true
```

如果桌面入口包含 `Exec=/usr/bin/kare run ...`，或路径位于 `/opt/kare`、`/opt/kare-applications`，说明它仍然是 KARE 应用。终端、开发工具、代理工具等需要访问宿主系统状态的应用，应优先使用原生宿主机安装。

完成系统级安装后，按维护模式流程执行：

```bash
sudo mm-cli -c -a
```

随后重启系统验证持久性。
