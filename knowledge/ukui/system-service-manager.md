# UKUI 系统服务管理器异常

此流程用于 KylinOS Desktop V11/UKUI 上 `ukui-system-service-manager.service` 反复启动超时、日志出现 `QDBusError("", "")`、`org.ukui.serviceManager` D-Bus 名称被孤儿进程占用等问题。

## 目录

- 关键结论
- 诊断
- 修复
- 持久化修复
- 启动顺序竞态修复
- 验证
- 与卡死问题的关联排查

## 关键结论

- `ukui-system-service-manager.service` 是 `Type=dbus` 服务，正式 D-Bus 名称是 `org.ukui.serviceManager`。
- 如果旧的 `ukui-system-service-manager` 进程脱离 systemd service cgroup，但仍持有 `org.ukui.serviceManager`，systemd 新拉起的实例会拿不到服务名，表现为持续 `activating (start)`，约 90 秒后 timeout，再进入下一轮重启。
- 常见根因是 D-Bus activation 文件直接使用 `Exec=/usr/bin/ukui-system-service-manager`，没有通过 `SystemdService=ukui-system-service-manager.service` 交给 systemd 管理；当 D-Bus 请求早于 systemd unit 或两者并发时，dbus-daemon 可能直接拉起一个归属 `dbus.service` 的旧进程，造成后续 systemd 实例抢不到同一个 D-Bus 名称。
- 另一类根因是 systemd 单元被 `graphical.target` 拉起，但自身又声明 `After=graphical.target`。这会让 UKUI 会话、面板或搜索服务先启动并请求 `org.ukui.serviceManager`，而服务管理器尚未就绪，表现为 `com.ukui.search.qt.systemdbus` 和 `org.ukui.serviceManager` activation timeout。
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
- `systemctl show ukui-system-service-manager.service -p After -p Before -p WantedBy` 显示同时存在 `WantedBy=graphical.target` 和 `After=graphical.target`，启动日志中又能看到 `ukui-panel` 或 `ukui-search-app-data-service` 先请求 `org.ukui.serviceManager`，随后 D-Bus activation timeout。

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

## 启动顺序竞态修复

如果 D-Bus activation 文件已经包含 `SystemdService=ukui-system-service-manager.service`，但登录阶段仍出现 activation timeout，应检查 unit 排序：

```bash
systemctl cat ukui-system-service-manager.service
systemctl show ukui-system-service-manager.service \
  -p FragmentPath -p DropInPaths -p After -p Before -p Wants -p WantedBy --no-pager
systemd-analyze critical-chain ukui-system-service-manager.service
```

如果原始单元同时满足以下特征，说明服务容易和桌面会话发生启动顺序竞态：

- `[Install]` 中 `WantedBy=graphical.target`。
- `[Unit]` 中存在 `After=graphical.target`。
- 启动日志中 `ukui-panel`、`ukui-search-app-data-service` 或 `com.ukui.search.qt.systemdbus` 早于 `ukui-system-service-manager.service` 请求 `org.ukui.serviceManager`。

优先用 `/etc/systemd/system/` 下的完整覆盖单元修复排序，不直接修改 `/usr/lib/systemd/system/` 的包文件：

```ini
[Unit]
Description=UKUI System Service Manager
Wants=dbus.socket
After=basic.target dbus.socket
Before=graphical.target

[Service]
Type=dbus
BusName=org.ukui.serviceManager
ExecStart=/usr/bin/ukui-system-service-manager
Restart=on-failure
RestartSec=5s

[Install]
#WantedBy=multi-user.target
WantedBy=graphical.target
```

写入后重新加载并重新生成 enable 链接：

```bash
pkexec systemctl daemon-reload
pkexec systemctl reenable ukui-system-service-manager.service
pkexec systemctl restart ukui-system-service-manager.service
```

不要只依赖 drop-in 里的空 `After=` 清理依赖。部分 systemd 版本或依赖类型下，`systemctl show` 仍可能保留原始 `After=graphical.target`；如果出现这种情况，不要留下同时 `After=graphical.target` 和 `Before=graphical.target` 的矛盾配置，改用完整覆盖单元并再次验证。

回滚方式：

```bash
pkexec rm -f /etc/systemd/system/ukui-system-service-manager.service
pkexec systemctl daemon-reload
pkexec systemctl reenable ukui-system-service-manager.service
pkexec systemctl restart ukui-system-service-manager.service
```

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

如果修复的是启动顺序竞态，还要验证：

```bash
systemctl show ukui-system-service-manager.service \
  -p FragmentPath -p After -p Before -p ActiveState -p SubState --no-pager
systemd-analyze critical-chain ukui-system-service-manager.service
readlink -f /etc/systemd/system/graphical.target.wants/ukui-system-service-manager.service
```

预期结果：

- `FragmentPath` 指向 `/etc/systemd/system/ukui-system-service-manager.service`。
- `After` 中不再包含 `graphical.target`。
- `Before` 中包含 `graphical.target`。
- `critical-chain` 显示服务只等待 `basic.target`、`dbus.socket` 等基础目标，不再等待图形目标。
- 重启后日志中 `ukui-system-service-manager.service` 应早于或不晚于桌面会话对 `org.ukui.serviceManager` 的首次请求完成启动。

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
