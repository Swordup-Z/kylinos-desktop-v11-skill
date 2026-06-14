# 图形驱动与频率问题

此文档用于处理 KylinOS Desktop V11 上的图形驱动、GPU/显示频率、`devfreq` 调频、图形相关内核日志和硬件强相关稳定性问题。

这类问题经常与具体 CPU/GPU/SoC、内核模块、固件、ACPI 设备名和驱动版本强相关。文档中的设备名只能作为示例；在其他硬件上必须先识别真实设备，再套用同类流程。

## 适用场景

- 系统卡死前后出现图形、DRM、GPU、`devfreq`、频率设置失败日志。
- 内核日志出现类似 `failed to set <driver> frequency`、`devfreq <device>: dvfs failed`。
- 机器没有 NVIDIA GPU，但日志反复出现 `NVRM: No NVIDIA GPU found` 或 NVIDIA 模块探测。
- 图形问题疑似与动态调频、休眠恢复、错误驱动包或不存在硬件的驱动 hook 有关。

## 基础诊断

先读取硬件和日志，不要直接套用某台机器的设备名：

```bash
lspci -nnk
ls /sys/class/devfreq
journalctl -k -b --no-pager | rg -i 'drm|gpu|devfreq|frequency|nvrm|nvidia|ftg'
journalctl --list-boots
```

如果问题发生在过去某次启动，先定位 boot id，再读取该次内核日志：

```bash
journalctl -k -b <boot-id> --no-pager | rg -i 'drm|gpu|devfreq|frequency|nvrm|nvidia|panic|oom|hung|blocked'
```

对每个可疑 `devfreq` 节点读取状态：

```bash
for d in /sys/class/devfreq/*; do
  echo "== $d =="
  cat "$d/name" 2>/dev/null || true
  cat "$d/governor" 2>/dev/null || true
  cat "$d/available_governors" 2>/dev/null || true
  cat "$d/cur_freq" 2>/dev/null || true
  cat "$d/min_freq" 2>/dev/null || true
  cat "$d/max_freq" 2>/dev/null || true
  cat "$d/available_frequencies" 2>/dev/null || true
done
```

## 维护模式边界

只读取日志、硬件状态、`/sys` 当前值属于诊断；写入 `/etc`、`/usr/share`、创建 systemd 单元、禁用系统服务、修改 modprobe 配置或卸载驱动包属于系统级修复。

系统级修复前必须先确认维护模式：

```bash
mm-cli -s
```

只有确认当前是 maintain mode 后，才继续写系统路径或修改系统服务。修复完成后需要退出维护模式并重启验证。

## Phytium FTG / devfreq 调频失败示例

现象示例：

```text
failed to set ftg frequency:-15
devfreq PHYT0048:00: dvfs failed with (-15) error
```

这说明当前硬件的图形驱动在动态调频路径上失败。若该错误与卡死、黑屏、图形异常时间接近，可以先采用保守策略：把对应 GPU `devfreq` governor 固定到 `performance`，减少动态频率切换。

先确认设备节点和可用 governor：

```bash
cat /sys/class/devfreq/<devfreq-device>/governor
cat /sys/class/devfreq/<devfreq-device>/available_governors
cat /sys/class/devfreq/<devfreq-device>/available_frequencies
```

如果 `<devfreq-device>` 支持 `performance`，可以做运行时验证：

```bash
echo performance | sudo tee /sys/class/devfreq/<devfreq-device>/governor
cat /sys/class/devfreq/<devfreq-device>/governor
```

如果运行时设置后很快又变回 `simple_ondemand` 或 `powersave`，不要立刻叠加 systemd 定时器或启动脚本。应先检查是否被 UKUI 电源管理覆盖：

```bash
journalctl --since '10 minutes ago' --no-pager | rg -i 'ukui-powermanagement-service|SceneChanged|Devfreq|devfreq|policy'
rg -n 'DevfreqPolicy=' /usr/share/ukui/ukui-power-manager /etc 2>/dev/null
```

在 KylinOS Desktop V11/UKUI 中，`ukui-powermanagement-service` 可能会按场景把 `devfreq` governor 改回配置文件里的策略。此时更合适的持久化修复是修改 UKUI 电源管理策略源，而不是写一个和它抢状态的 systemd oneshot。

修改前先备份。例如只把全局 `[devfreqPolicy]` 段的策略改为 `performance`：

```bash
sudo sed -i.bak-<date> -e '/^\[devfreqPolicy\]/,/^\[/ s/^\([^#][^=]*DevfreqPolicy=\).*/\1performance/' /usr/share/ukui/ukui-power-manager/upm-hardware-global.conf
```

如果日志显示匹配了厂商硬件扩展，例如：

```text
extend config path: "/usr/share/ukui/ukui-power-manager/upm-hardware-extend.d/<vendor>.config"
```

还要检查该扩展文件是否包含 `DevfreqPolicy`、GPU 频率或功耗相关覆盖项。只有确认扩展文件没有覆盖，或已经按同样原则调整后，再验证。

运行中的 `ukui-powermanagement-service` 可能缓存旧配置。可在评估影响后重启该 DBus 后端，或要求用户重启后验证。若选择当前会话重启，先确认服务由 D-Bus 激活：

```bash
busctl --system list | rg -i 'ukui.powermanagement|powermanagement'
busctl --system status org.ukui.powermanagement
```

然后重启进程并确认它重新注册 D-Bus 名称。不同系统的 D-Bus 访问策略不同，如果普通用户不能直接激活，可按该系统原始命令恢复服务：

```bash
sudo kill <ukui-powermanagement-service-pid>
sudo /usr/bin/ukui-powermanagement-service
```

如果没有 UKUI 电源管理覆盖，或目标系统没有等价的电源策略后端，才考虑使用 systemd oneshot 作为兜底。示例中必须把设备名替换成实际节点：

```ini
[Unit]
Description=Pin GPU devfreq governor to performance
DefaultDependencies=no
After=sysinit.target
Before=graphical.target
ConditionPathExists=/sys/class/devfreq/<devfreq-device>/governor

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/sh -c 'echo performance > /sys/class/devfreq/<devfreq-device>/governor'

[Install]
WantedBy=graphical.target
```

兜底单元安装并启用：

```bash
sudo install -m 0644 <service-file> /etc/systemd/system/<service-name>.service
sudo systemctl daemon-reload
sudo systemctl enable --now <service-name>.service
```

验证：

```bash
cat /sys/class/devfreq/<devfreq-device>/governor
cat /sys/class/devfreq/<devfreq-device>/cur_freq
systemctl status <service-name>.service --no-pager
```

风险和取舍：

- `performance` 通常会增加功耗和发热，笔记本可能影响续航。
- 这是稳定性优先的规避策略，不等同于修复驱动本身的 bug。
- 如果后续厂商内核或驱动更新修复了 DVFS，可评估恢复默认 governor。
- 如果改了 UKUI 电源管理配置，应保留 `.bak-<date>` 备份；回滚时恢复原文件，重启 `ukui-powermanagement-service` 或重启系统。

## 无 NVIDIA 硬件但 NVIDIA 驱动反复探测

若 `lspci -nnk` 没有 NVIDIA GPU，但内核日志反复出现：

```text
NVRM: No NVIDIA GPU found.
```

同时系统安装了 NVIDIA 驱动包或启用了 NVIDIA 休眠/恢复 hook，可以先做保守屏蔽，而不是直接卸载包。

诊断：

```bash
lspci -nnk | rg -i 'nvidia|vga|3d|display'
dpkg -l | rg -i 'nvidia|libnvidia|xserver-xorg-video-nvidia'
systemctl is-enabled nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
rg -n 'nvidia' /etc/modprobe.d /usr/lib/modprobe.d 2>/dev/null
```

如果确认当前硬件没有 NVIDIA GPU，可新增 modprobe 配置：

```conf
# No NVIDIA GPU is present on this system. Prevent unnecessary NVIDIA
# kernel module probes from tainting the kernel and polluting graphics logs.
blacklist nvidia
blacklist nvidia_drm
blacklist nvidia_modeset
blacklist nvidia_uvm
blacklist nvidia_peermem

install nvidia /bin/false
install nvidia_drm /bin/false
install nvidia_modeset /bin/false
install nvidia_uvm /bin/false
install nvidia_peermem /bin/false
```

并禁用 NVIDIA 休眠/恢复 hook：

```bash
sudo systemctl disable --now nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
```

验证：

```bash
modprobe -n -v nvidia
modprobe -n -v nvidia_drm
modprobe -n -v nvidia_modeset
modprobe -n -v nvidia_uvm
modprobe -n -v nvidia_peermem
systemctl is-enabled nvidia-suspend.service nvidia-resume.service nvidia-hibernate.service
rg '^nvidia' /proc/modules
```

注意：

- 如果以后更换到带 NVIDIA GPU 的硬件，必须删除上述屏蔽配置并重新启用需要的服务。
- 不建议默认卸载 NVIDIA 包；包依赖、厂商软件源和图形栈文件可能有额外关系。
- 如果重启后仍然有用户态程序触发 NVIDIA GLVND/Vulkan JSON，可再检查 `/usr/share/glvnd/egl_vendor.d/`、`/usr/share/vulkan/icd.d/` 和 `/usr/share/vulkan/implicit_layer.d/`，但移动包文件属于更强侵入性操作，应先评估。

## 修复后验证

完成图形/频率修复后，至少验证：

```bash
systemctl --failed --no-pager
journalctl -k --since '10 minutes ago' --no-pager | rg -i 'drm|gpu|devfreq|frequency|nvrm|nvidia|ftg'
```

如果修改了 governor 或驱动探测规则，还要验证重启后是否仍然生效：

```bash
cat /sys/class/devfreq/<devfreq-device>/governor
modprobe -n -v <blocked-module>
```

若原问题是偶发卡死，不能仅凭当前日志消失判断彻底修复。应记录修复点和观察窗口；下次复现时优先对比同一时间段的 `journalctl -k`、`journalctl -b <boot-id>` 和电源/强制重启痕迹。
