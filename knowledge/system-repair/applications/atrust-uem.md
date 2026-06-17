# aTrust/UEM 安全客户端修复

## 适用场景

- aTrust 或类似 VPN/安全客户端安装后提示虚拟网络组件、剪切板隔离组件、UEM 组件启动失败。
- 安装脚本尝试编译或安装第三方内核模块，例如 `sfuem.ko`。
- 第三方内核模块、DKMS、`modules-load.d` 或临时安装脚本残留导致系统启动异常。

## 处理原则

- 不要把“内核模块能编译成功”等同于“可以安全开机自加载”。第三方安全客户端的内核模块会影响网络栈、LSM、安全隔离或早期启动路径，必须按高风险系统改动处理。
- 未获得官方明确支持当前内核版本的模块前，不要强行修补源码、伪造兼容对象、加入 DKMS 或写入 `modules-load.d` 持久加载。
- 若确实需要验证内核模块，只能在维护模式下先准备回滚方案，再在当前会话中手动加载和卸载验证；跨重启自动加载必须等用户确认功能和重启稳定性后再考虑。
- 一旦自编或强行适配的第三方模块造成启动异常，优先回滚内核侧改动，保留主程序服务，再另找用户态、官方包、官方驱动或版本匹配方案。

## 最小诊断

```bash
mm-cli -s
dpkg -l | rg -i 'atrust|sangfor|uem' || true
systemctl status aTrustDaemon.service --no-pager 2>/dev/null || true
systemctl status uem_service.service --no-pager 2>/dev/null || true
systemctl is-enabled uem_service.service 2>/dev/null || true
systemctl is-active uem_service.service 2>/dev/null || true
lsmod | rg -i 'sfuem|sangfor|uem' || true
find /lib/modules /usr/lib/modules -name 'sfuem.ko*' 2>/dev/null
find /dev -maxdepth 2 \( -iname '*uem*' -o -iname '*sfuem*' \) -ls 2>/dev/null
rg -n 'sfuem|uem_service' /etc/modules-load.d /usr/lib/modules-load.d /lib/modules-load.d /etc/modprobe.d /usr/lib/modprobe.d 2>/dev/null || true
```

如果用户报告启动异常，应先确认模块是否仍在磁盘、DKMS 或自加载配置中；不要先重装客户端。

## UEM RPC 与驱动设备诊断

如果用户态日志出现 `connect() failed: 拒绝连接`、`onRpcUserLogin failed` 或 `onRpcConfChange failed`，先区分是 `uem_service` 没运行，还是 UEM 驱动缺失：

```bash
tail -n 120 "$HOME/.aTrust/logs/uem/uemsdk.log" "$HOME/.aTrust/logs/uem/uem_launcher.log" 2>/dev/null
sudo tail -n 160 /root/.aTrust/logs/uem/uem_service.log /root/.aTrust/logs/uem/uem_installer.log 2>/dev/null
systemctl is-enabled uem_service.service 2>/dev/null || true
systemctl is-active uem_service.service 2>/dev/null || true
find /dev -maxdepth 2 \( -iname '*uem*' -o -iname '*sfuem*' \) -ls 2>/dev/null
strings -a /usr/share/sangfor/aTrust/uem/bin/uem_service 2>/dev/null | rg '/dev/|sfuem|driver init|Open uem'
```

判断：

- `uem_service` 为 `masked/inactive` 且 `uemsdk.log` 报 RPC 拒绝连接，说明客户端确实连不上 UEM 服务；这通常是为了避免不兼容内核模块开机加载而主动屏蔽后的结果。
- 临时解除屏蔽并启动 `uem_service` 后，如果 `/root/.aTrust/logs/uem/uem_service.log` 报 `Uem driver ctrl init failed.; Reason: Open uem device failed.` 或 `driver init failed`，同时没有 `/dev/sfuem`，说明 UEM 服务依赖的厂商驱动设备不存在。
- aTrust 的普通隧道进程、`/dev/net/tun` 或 `utun*` 存在，不代表 UEM 虚拟网络环境可用；UEM 虚拟网络依赖的是 `/dev/sfuem` 这条独立链路。

低风险验证只能做到“临时启动用户态服务观察日志”，不要启用开机自启：

```bash
sudo systemctl daemon-reload
sudo systemctl unmask uem_service.service
sudo systemctl start uem_service.service
systemctl status uem_service.service --no-pager
```

验证结束后，如果日志确认缺 `/dev/sfuem` 或服务反复退出，应恢复安全状态：

```bash
sudo systemctl stop uem_service.service 2>/dev/null || true
sudo systemctl mask uem_service.service 2>/dev/null || true
sudo systemctl reset-failed uem_service.service 2>/dev/null || true
```

如果当前安装包只包含 DKMS 构建脚本、`modules-load.d/sfuem.conf`，但没有官方预编译 `.ko` 或明确支持当前内核版本的驱动包，应判定为厂商驱动兼容性问题；不要继续伪造兼容对象或用自编模块硬适配。

## 回滚内核侧残留

在维护模式下执行，目标是移除高风险内核残留，同时尽量保留 aTrust 主程序用于后续诊断：

```bash
sudo systemctl disable --now uem_service.service 2>/dev/null || true
sudo systemctl mask uem_service.service 2>/dev/null || true
sudo dkms remove sfuem/1.0.0 --all 2>/dev/null || true
sudo dkms remove sfuem.disabled/1.0.0 --all 2>/dev/null || true
sudo find /lib/modules /usr/lib/modules -name 'sfuem.ko*' -delete
sudo rm -f /etc/modules-load.d/*sfuem* /usr/lib/modules-load.d/*sfuem* /lib/modules-load.d/*sfuem*
sudo depmod -a
```

验证：

```bash
lsmod | rg -i 'sfuem|uem' || true
find /lib/modules /usr/lib/modules -name 'sfuem.ko*' 2>/dev/null
dkms status 2>/dev/null | rg -i 'sfuem|uem' || true
systemctl is-enabled uem_service.service 2>/dev/null || true
systemctl is-active uem_service.service 2>/dev/null || true
systemctl is-active aTrustDaemon.service 2>/dev/null || true
```

期望状态：`sfuem` 不在 `lsmod`，磁盘无 `sfuem.ko*`，DKMS 无 `sfuem` 或 `sfuem.disabled` 残留，`uem_service` 为 `masked` 或 `disabled/inactive`，`aTrustDaemon` 可继续保持 `active` 便于后续排查。

## 临时脚本清理

排查过程中生成在 `$HOME` 的一次性脚本、wrapper 或编译辅助文件，在确认不再需要回滚后应删除，避免后续误执行：

```bash
find "$HOME" -maxdepth 1 -type f \( -name '*atrust*' -o -name '*aTrust*' -o -name '*sfuem*' \) -printf '%f\n'
```

只删除能确认属于本次临时修复链路的文件；不要按扩展名批量删除用户自己的脚本。

## 不可用时卸载清理

如果确认当前 aTrust/UEM 版本不兼容当前系统或内核，并且用户要求卸载清理，仍按维护模式执行。先停服务和进程，再通过包管理器卸载，最后做残留扫描。不要直接从 `/usr/share`、`/opt/apps` 开始手工删除，否则容易让 dpkg 数据库保留脏状态。

```bash
mm-cli -s
dpkg -l | rg -i 'atrust|sangfor|uem|sfuem' || true
systemctl list-unit-files | rg -i 'atrust|sangfor|uem|eaio' || true
ps -ef | rg -i 'atrust|sangfor|uem|eaio|sfuem' | rg -v rg || true
```

卸载：

```bash
sudo systemctl stop aTrustDaemon.service aTrustShell.service eaio_service.service uem_service.service 2>/dev/null || true
sudo systemctl disable aTrustDaemon.service aTrustShell.service aTrustTray@.service eaio_service.service uem_service.service 2>/dev/null || true
sudo apt-get purge -y cn.com.sangfor.atrust
```

aTrust 卸载脚本可能输出 `kill` 用法、找不到 UEM 插件文件、`Failed to connect to bus` 或“保留 root 日志目录”等非致命信息。只要 dpkg 最终不再显示 `cn.com.sangfor.atrust`，再继续清理残留：

```bash
sudo rm -rf \
  /etc/systemd/system/uem_service.service \
  /usr/share/glib-2.0/schemas/99_cn.com.sangfor.atrust.uem.gschema.override \
  /usr/share/kylin-software-center/data/icons/cn.com.sangfor.atrust.png \
  /usr/share/sangfor \
  /var/log/sangfor \
  /root/.aTrust \
  /opt/apps/cn.com.sangfor.atrust
sudo find /lib/modules /usr/lib/modules -name 'sfuem.ko*' -delete 2>/dev/null || true
sudo rm -f /etc/modules-load.d/*sfuem* /usr/lib/modules-load.d/*sfuem* /lib/modules-load.d/*sfuem* 2>/dev/null || true
sudo rm -rf /usr/src/sfuem-* /var/lib/dkms/sfuem /var/lib/dkms/sfuem.disabled 2>/dev/null || true
sudo rm -rf /var/tmp/aTrustShell.conf /var/tmp/com.sangfor.aTrustTray.script.start.log /var/tmp/com.sangfor.atrust /var/tmp/sapp2_aTrustXtunnel-64*
sudo depmod -a
sudo glib-compile-schemas /usr/share/glib-2.0/schemas/ 2>/dev/null || true
sudo systemctl daemon-reload
sudo systemctl reset-failed aTrustDaemon.service aTrustShell.service aTrustTray@.service eaio_service.service uem_service.service 2>/dev/null || true
rm -rf "$HOME/.aTrust" "$HOME/.config/aTrustTray"
systemctl --user daemon-reload 2>/dev/null || true
systemctl --user reset-failed aTrustShell.service aTrustTray.service uem_shell@.service 2>/dev/null || true
```

验证：

```bash
dpkg -l | rg -i 'atrust|sangfor|sfuem' || true
systemctl list-unit-files | rg -i 'atrust|sangfor|uem|eaio' || true
systemctl --user list-unit-files | rg -i 'atrust|sangfor|uem|eaio' || true
ps -ef | rg -i 'atrust|sangfor|uem|eaio|sfuem' | rg -v rg || true
lsmod | rg -i 'sfuem|sangfor|uem' || true
dkms status 2>/dev/null | rg -i 'sfuem|atrust|uem' || true
```

不要把 `apt autoremove` 作为 aTrust 卸载的一部分自动执行；它可能列出输入法或其他桌面组件的历史依赖，应由用户单独确认。`$HOME/下载` 中用户手动保存的安装包、表格或归档也不要默认删除，除非用户明确要求一并清理。

## 后续排查方向

- 优先查找官方支持当前系统和内核版本的 aTrust 包、UEM 组件或虚拟网络组件。
- 检查 aTrust 用户态日志，判断失败是否来自主程序、`aTrustDaemon`、`aTrustXtunnel`、UEM 服务或内核模块加载。
- 如果功能必须依赖官方 UEM 内核模块，而当前内核无匹配版本，应向用户说明这是厂商兼容性问题；不要继续用自编模块硬适配。
