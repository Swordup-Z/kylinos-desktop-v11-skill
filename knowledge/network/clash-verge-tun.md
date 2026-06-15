# Clash Verge TUN

此流程用于 Kylin Desktop V11 上的 Clash Verge Rev TUN 问题，覆盖 KARE 打包版以及从 KARE 迁移到宿主机原生安装后的残留问题。应用数据目录通常是：

```bash
~/.local/share/io.github.clash-verge-rev.clash-verge-rev
```

## 目录

- 安全规则
- 诊断
- 修复 TUN 设备
- 安装 Clash Verge 服务
- 从 KARE 迁移到宿主机原生包
- 在 Clash Verge 中启用 TUN
- 如果代理组消失
- 最终验证

## 安全规则

- 不要删除、移动或覆盖任何已有的 `mihomo`、`verge-mihomo`、`clash`、`clash-verge` 可执行文件。
- 修改服务或核心路径前，先检查当前路径，并保留用户已经恢复正常的工作状态。
- 将 `/usr/bin/verge-mihomo` 视为 Clash Verge 可能依赖的关键路径。代理组消失时，已知的一种恢复方式是补回该核心二进制：

```bash
sudo cp /opt/kare-applications/shadow/upper/usr/bin/verge-mihomo /usr/bin/verge-mihomo
```

- 除非 `/usr/bin/verge-mihomo` 缺失或损坏，并且用户明确同意，否则不要执行上面的复制操作。确实需要复制时，只能从上面的 KARE 打包二进制复制，并用 `/usr/bin/verge-mihomo -v` 验证。
- 在此环境中进行图形/系统修复时，优先使用 `pkexec`，不要优先使用 `sudo`。Clash Verge 运行在 KARE 环境内，应用内 `sudo` 可能因为主机名 `kare` 和无终端密码输入而失败。

## 诊断

先查看日志：

```bash
tail -200 ~/.local/share/io.github.clash-verge-rev.clash-verge-rev/logs/latest.log
tail -200 ~/.local/share/io.github.clash-verge-rev.clash-verge-rev/logs/sidecar/sidecar_latest.log
```

已知的服务安装失败特征：

```text
pkexec failed with code 127, falling back to sudo
sudo: 无法解析主机：kare
sudo: a terminal is required to read the password
```

检查 TUN 和服务状态：

```bash
modinfo tun
ls -l /dev/net/tun
systemctl status clash-verge-service --no-pager
systemctl is-enabled clash-verge-service
systemctl is-active clash-verge-service
```

在当前内核上，`tun` 可能是内建模块，因此 `modinfo tun` 可能显示 `filename: (builtin)`。这表示内核支持 TUN，缺失的可能只是 `/dev/net/tun` 设备节点。

## 修复 TUN 设备

如果 `/dev/net/tun` 不存在，在宿主机上创建设备节点：

```bash
pkexec sh -c 'mkdir -p /dev/net; if [ ! -e /dev/net/tun ]; then mknod /dev/net/tun c 10 200; fi; chmod 0666 /dev/net/tun'
```

在宿主机上下文验证：

```bash
ls -l /dev/net/tun
```

预期形态：

```text
crw-rw-rw- 1 root root 10, 200 ... /dev/net/tun
```

如果沙箱终端仍然看不到 `/dev/net/tun`，不要直接判断宿主机修复失败。应使用宿主机/提权命令重新检查。

## 安装 Clash Verge 服务

先确认 KARE 打包的二进制存在：

```bash
ls -l /opt/kare-applications/shadow/upper/usr/bin/clash-verge-service-install
ls -l /opt/kare-applications/shadow/upper/usr/bin/clash-verge-service
ls -l /opt/kare-applications/shadow/upper/usr/bin/verge-mihomo
```

用当前用户主组安装 systemd 服务。不要硬编码 UID/GID；先动态读取当前用户的主组 GID：

```bash
SERVICE_GID="$(id -g)"
pkexec /usr/bin/env CLASH_VERGE_SERVICE_GID="$SERVICE_GID" /opt/kare-applications/shadow/upper/usr/bin/clash-verge-service-install
```

然后验证：

```bash
systemctl status clash-verge-service --no-pager
systemctl is-enabled clash-verge-service
systemctl is-active clash-verge-service
sed -n '1,120p' /etc/systemd/system/clash-verge-service.service
ls -la /tmp/verge
```

预期服务属性：

```text
Loaded: loaded (/etc/systemd/system/clash-verge-service.service; enabled)
Active: active (running)
Group=<当前用户名或当前用户主组名>
ExecStart=/var/opt/kare-applications/shadow/upper/usr/bin/clash-verge-service
```

预期 IPC socket：

```text
/tmp/verge/clash-verge-service.sock
```

## 从 KARE 迁移到宿主机原生包

如果用户从 KARE 打包版改为宿主机原生 `.deb` 安装，不能只看 `clash-verge` 命令是否存在，还要同时确认包归属、桌面入口、服务单元和运行进程都已离开 KARE 路径。

先确认当前 shell 位于宿主机 namespace，且系统处于维护模式：

```bash
mm-cli -s
hostname
readlink /proc/$$/ns/mnt
readlink /proc/$$/ns/uts
```

宿主机原生安装的典型特征：

```bash
command -v clash-verge
command -v verge-mihomo
dpkg -l | rg -i 'clash|verge|mihomo'
dpkg -S /usr/bin/clash-verge /usr/bin/verge-mihomo /usr/bin/clash-verge-service /usr/bin/clash-verge-service-install 2>/dev/null || true
sed -n '1,80p' /usr/share/applications/*Clash* 2>/dev/null
```

预期结果是 `clash-verge` 包提供 `/usr/bin/clash-verge`、`/usr/bin/verge-mihomo`、`/usr/bin/clash-verge-service` 和 `/usr/bin/clash-verge-service-install`，桌面入口使用：

```text
Exec=clash-verge %u
```

如果仍看到 `Exec=/usr/bin/kare run ...`，或路径位于 `/opt/kare`、`/opt/kare-applications`，说明还没有完全切换到宿主机原生入口。

迁移后要特别检查旧服务单元是否残留 KARE 路径：

```bash
systemctl status clash-verge-service --no-pager
sed -n '1,120p' /etc/systemd/system/clash-verge-service.service
```

如果服务报 `status=203/EXEC`，且 `ExecStart=` 仍指向：

```text
/var/opt/kare-applications/shadow/upper/usr/bin/clash-verge-service
```

说明旧 KARE 服务单元覆盖了新包。应在维护模式下把 `ExecStart=` 修正为宿主机路径：

```ini
ExecStart=/usr/bin/clash-verge-service
```

然后重新加载并启用服务：

```bash
pkexec systemctl daemon-reload
pkexec systemctl enable --now clash-verge-service
```

如果服务 core 和图形界面 sidecar 同时运行，可能出现端口冲突：

```text
Start Mixed(http+socks) server error: listen tcp 127.0.0.1:<port>: bind: address already in use
```

此时检查进程父子关系：

```bash
pgrep -a 'clash-verge|verge-mihomo' || true
ps -o pid,ppid,user,group,comm,args -p <pid-list>
ss -ltnup 2>/dev/null | rg ':53|:<mixed-port>|verge-mihomo' || true
```

若普通用户 `verge-mihomo` 是由图形进程拉起，而 systemd 服务也在运行，应完整退出 Clash Verge 图形进程，再重启 `clash-verge-service`，让图形进程在服务已就绪的状态下重新连接服务。不要删除或覆盖 `verge-mihomo`。

## 在 Clash Verge 中启用 TUN

服务和 TUN 设备正常后，让用户从托盘完全退出 Clash Verge，再重新启动。然后在 Clash Verge 界面中启用 TUN 模式。

在界面启用前，配置文件可能仍显示 TUN 关闭：

```bash
rg -n 'enable_tun_mode|^tun:|enable:|stack:|auto-route|dns-hijack' \
  ~/.local/share/io.github.clash-verge-rev.clash-verge-rev/verge.yaml \
  ~/.local/share/io.github.clash-verge-rev.clash-verge-rev/config.yaml \
  ~/.local/share/io.github.clash-verge-rev.clash-verge-rev/clash-verge.yaml
```

界面切换前的常见状态：

```text
enable_tun_mode: false
tun:
  enable: false
```

除非用户明确要求，不要手动编辑这些 YAML 文件。应让 Clash Verge 自己写入运行时配置。

## 如果代理组消失

立即检查核心二进制路径：

```bash
ls -l /usr/bin/verge-mihomo
/usr/bin/verge-mihomo -v
ls -l /opt/kare-applications/shadow/upper/usr/bin/verge-mihomo
```

如果 `/usr/bin/verge-mihomo` 缺失或不可用，说明代理组可能因为 Clash Verge 找不到预期核心而消失。已知的手动修复命令是：

```bash
sudo cp /opt/kare-applications/shadow/upper/usr/bin/verge-mihomo /usr/bin/verge-mihomo
```

该命令会写入 `/usr/bin`，只能在用户明确同意后执行。

## 最终验证

向用户报告以下事实：

- `/dev/net/tun` 存在，并且是字符设备 `10,200`。
- `clash-verge-service` 是 `enabled` 且 `active`。
- `/tmp/verge/clash-verge-service.sock` 存在。
- `verge-mihomo` 存在于 Clash Verge 期望的路径；如果当前环境依赖 `/usr/bin/verge-mihomo`，必须特别确认这个路径。
- TUN 是否已经在应用配置中启用，或者仍等待用户在界面中切换。
- 如果已经启用 TUN，`ip -br link show` 中应出现 `Meta` 等 TUN 网卡，服务日志应出现类似 `[TUN] Tun adapter listening`；同时确认没有普通用户 sidecar 与 systemd 服务 core 同时抢占代理端口。
