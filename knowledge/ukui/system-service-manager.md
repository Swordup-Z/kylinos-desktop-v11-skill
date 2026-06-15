# UKUI 系统服务管理器异常

此流程用于 KylinOS Desktop V11/UKUI 上 `ukui-system-service-manager.service` 反复启动超时、日志出现 `QDBusError("", "")`、`org.ukui.serviceManager` D-Bus 名称被孤儿进程占用等问题。

## 目录

- 关键结论
- 诊断
- 修复
- 持久化修复
- 验证
- 与卡死问题的关联排查

## 关键结论

- `ukui-system-service-manager.service` 是 `Type=dbus` 服务，正式 D-Bus 名称是 `org.ukui.serviceManager`。
- 如果旧的 `ukui-system-service-manager` 进程脱离 systemd service cgroup，但仍持有 `org.ukui.serviceManager`，systemd 新拉起的实例会拿不到服务名，表现为持续 `activating (start)`，约 90 秒后 timeout，再进入下一轮重启。
- 常见根因是 D-Bus activation 文件直接使用 `Exec=/usr/bin/ukui-system-service-manager`，没有通过 `SystemdService=ukui-system-service-manager.service` 交给 systemd 管理；当 D-Bus 请求早于 systemd unit 或两者并发时，dbus-daemon 可能直接拉起一个归属 `dbus.service` 的旧进程，造成后续 systemd 实例抢不到同一个 D-Bus 名称。
- 典型日志是 `ukui-system-service-manager[<pid>]: QDBusError("", "")`，随后 `start operation timed out`。
- 运行时修复重点是先停掉 systemd 正在拉起的新实例，再清理持有旧 D-Bus 名称的孤儿进程，最后重新启动服务。
- 持久化修复重点是让 system-bus D-Bus activation 也指向 systemd unit，避免重启或服务重拉起后再次出现同类竞争。
- 这是系统服务运行时修复。执行 `systemctl stop/start/kill` 或杀 root 进程前，应按通用流程先检查维护模式。
- 如果同一时段还出现整机卡死、强制重启或图形栈异常，应把本问题作为重要线索，但不能仅凭该服务 timeout 判断它就是整机卡死根因。

## 诊断

先确认维护模式：

```bash
mm-cli -s
```

只有确认是 maintain mode，才继续系统级修复。非维护模式下只做读取状态和日志。

检查服务状态：

```bash
systemctl status ukui-system-service-manager.service --no-pager
systemctl show ukui-system-service-manager.service \
  -p ActiveState -p SubState -p MainPID -p NRestarts -p Result --no-pager
journalctl -u ukui-system-service-manager.service -n 80 --no-pager
```

检查 D-Bus 名称归属：

```bash
busctl --system list | rg -i 'org.ukui.serviceManager|ukui-system-service-manager'
```

检查进程和 cgroup：

```bash
pgrep -af '/usr/bin/ukui-system-service-manager' || true
for pid in $(pgrep -f '/usr/bin/ukui-system-service-manager' || true); do
  echo "PID $pid"
  tr '\0' ' ' < "/proc/$pid/cmdline"
  echo
  cat "/proc/$pid/cgroup"
  grep -E 'Name|State|PPid|Threads|VmRSS' "/proc/$pid/status"
done
```

异常特征：

- `systemctl status` 显示 `activating (start)`，并反复 timeout。
- `journalctl` 反复出现 `QDBusError("", "")`。
- `busctl --system list` 中 `org.ukui.serviceManager` 指向一个旧 PID，且该 PID 不属于 `ukui-system-service-manager.service` 的 cgroup。
- 同时存在一个 systemd 正在拉起的新 PID 和一个持有 D-Bus 名称的旧 PID。

## 修复

先停止 systemd 正在拉起的服务实例：

```bash
pkexec systemctl stop ukui-system-service-manager.service
```

再次确认 D-Bus 名称是否仍被旧 PID 持有：

```bash
busctl --system list | rg -i 'org.ukui.serviceManager|ukui-system-service-manager'
pgrep -af '/usr/bin/ukui-system-service-manager' || true
```

如果还有旧 PID 持有 `org.ukui.serviceManager`，只清理该旧 PID：

```bash
pkexec kill <stale-pid>
```

不要用宽泛的 `killall`，避免误杀刚被 systemd 拉起的新实例或其他无关进程。

重新启动服务：

```bash
pkexec systemctl start ukui-system-service-manager.service
```

## 持久化修复

检查 system-bus D-Bus activation 文件：

```bash
sed -n '1,40p' /usr/share/dbus-1/system-services/org.ukui.serviceManager.service
```

如果只有 `Exec=/usr/bin/ukui-system-service-manager`，没有 `SystemdService=ukui-system-service-manager.service`，说明 D-Bus 可能绕过 systemd 直接拉起进程。先备份并补充 `SystemdService`：

```bash
pkexec sed -i.bak-$(date +%Y%m%d%H%M%S) \
  -e '/^Exec=\/usr\/bin\/ukui-system-service-manager$/i SystemdService=ukui-system-service-manager.service' \
  /usr/share/dbus-1/system-services/org.ukui.serviceManager.service
```

补充后重新加载 system bus 配置：

```bash
busctl --system call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
```

再重启服务验证：

```bash
pkexec systemctl restart ukui-system-service-manager.service
```

注意：这是包文件级修复，未来系统包升级可能覆盖该文件。升级后如果问题复现，应重新检查该 activation 文件。

## 验证

服务应变为 `active (running)`：

```bash
systemctl status ukui-system-service-manager.service --no-pager
systemctl show ukui-system-service-manager.service \
  -p ActiveState -p SubState -p MainPID -p NRestarts -p Result --no-pager
```

D-Bus 名称应归属同一个 systemd service PID：

```bash
busctl --system list | rg -i 'org.ukui.serviceManager|ukui-system-service-manager'
pgrep -af '/usr/bin/ukui-system-service-manager' || true
```

预期结果：

- 只有一个 `/usr/bin/ukui-system-service-manager` 进程。
- `org.ukui.serviceManager` 和临时 `:1.x` 名称指向同一个 PID。
- 该 PID 的 unit 是 `ukui-system-service-manager.service`。
- `NRestarts` 不再持续增长。

## 与卡死问题的关联排查

如果用户报告整机卡死并只能强制重启，应重点检查卡死前后日志：

```bash
journalctl --list-boots --no-pager
journalctl -b -1 -k --no-pager
journalctl -b -1 --no-pager
```

对疑似时间点做窗口查询：

```bash
journalctl --since '<YYYY-MM-DD HH:MM:SS>' --until '<YYYY-MM-DD HH:MM:SS>' -p warning..alert --no-pager
journalctl --since '<YYYY-MM-DD HH:MM:SS>' --until '<YYYY-MM-DD HH:MM:SS>' -k --no-pager
```

重点看：

- 是否有 `kernel panic`、`oops`、`hung task`、`soft lockup`、`hard lockup`、`watchdog`、`OOM`、磁盘 I/O error。
- 是否有 GPU/devfreq/DRM 相关错误，例如 `failed to set ftg frequency`、`devfreq ... dvfs failed`。
- 是否有 `Power key pressed` 后日志突然中断、下一轮启动提示文件系统未正常卸载。
- 是否有完整 `systemd-reboot.service`、`Reached target reboot.target`、`systemd-shutdown` 链路；如果没有完整链路，更像强制重启或异常断电。

`ukui-system-service-manager.service` timeout 可以作为桌面服务异常线索，但需要和内核、图形栈、电源键、文件系统恢复日志一起判断。
