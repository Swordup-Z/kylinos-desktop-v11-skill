# 图形驱动与频率问题

此文档用于处理 KylinOS Desktop V11 上的图形驱动、GPU/显示频率、`devfreq` 调频、图形相关内核日志和硬件强相关稳定性问题。

这类问题经常与具体 CPU/GPU/SoC、内核模块、固件、ACPI 设备名和驱动版本强相关。文档中的设备名只能作为示例；在其他硬件上必须先识别真实设备，再套用同类流程。

## 目录

- 适用场景
- 基础诊断
- 维护模式边界
- Phytium FTG / devfreq 调频失败示例
- 无 NVIDIA 硬件但 NVIDIA 驱动反复探测
- 修复后验证

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

这说明当前硬件的图形驱动在动态调频路径上失败。若该错误与卡死、黑屏、图形异常时间接近，先不要默认把所有 `devfreq` 场景全局固定到 `performance`，否则会破坏“均衡/省电/性能”电源模式语义。优先保留 `simple_ondemand`，只抬高可疑 GPU/总线节点的 `min_freq` 下限；只有 A/B 验证下限策略仍会复现卡死，或用户明确接受更高功耗/发热取舍时，才考虑将特定节点或特定场景固定到 `performance`。

如果卡死发生在把 KARE 打包的 Firefox/Zen 类浏览器复制为宿主原生运行之后，且日志同时出现大量 `ES30:texture(id=0) is incomplete`、`NewRenderer::Run is slow`、`GraphicsCriticalError`，随后紧跟 `failed to set ftg frequency:-15` 或 `devfreq PHYT0048:00: dvfs failed`，优先怀疑浏览器硬件加速触发 FTG 图形栈问题。此时不要只回滚到 KARE；可以先保留宿主原生启动以解决 profile 单实例和文件关联问题，但在 wrapper 和 profile 中禁用硬件图形路径：

```sh
#!/bin/sh
export MOZ_X11_EGL=0
export MOZ_ENABLE_WAYLAND=0
export MOZ_WEBRENDER=0
export MOZ_DISABLE_GPU_SANDBOX=1
export LIBGL_ALWAYS_SOFTWARE=1
exec /opt/<browser>/zen "$@"
```

同时在 Firefox/Zen profile 的 `user.js` 中固定软件渲染，防止配置界面或升级后重新启用硬件加速：

```js
user_pref("layers.acceleration.disabled", true);
user_pref("gfx.webrender.force-disabled", true);
user_pref("gfx.webrender.software", true);
user_pref("media.hardware-video-decoding.enabled", false);
user_pref("webgl.disabled", true);
```

验证时先确认没有旧 KARE 浏览器进程占用同一 profile，再启动宿主原生入口。成功时，日志里不应再持续出现 `ES30:texture` 和新的 `PHYT0048` devfreq 错误；本地 HTML 或链接再次打开时，只应短暂出现转发进程或新增内容进程，不应创建第二个主浏览器进程。

若历史日志中还出现类似：

```text
[ftg340]: GPU[0] core0 hang, automatic recovery.
```

则问题更接近 FTG 驱动或内核图形栈稳定性，而不是单纯电源模式选择。此时应先确认当前运行内核、FTG 包版本和仓库候选版本，再评估官方更新是否覆盖图形模块、`linux-modules-extra` 和用户态 FTG 库：

```bash
uname -r
dpkg -l 'linux-image*' 'linux-modules-extra*' ftg340-v11 | rg '^(ii|hi)'
apt-cache policy linux-image-generic linux-modules-extra-$(uname -r) ftg340-v11
modinfo ftg340 2>/dev/null | sed -n '1,20p'
```

如果仓库中存在同发行通道的更新版本，且卡死证据明确落在 FTG/DVFS 路径，优先使用发行版官方包更新驱动和内核模块栈。这是根因方向的修复；抬高 `min_freq` 只是规避低频切换抖动的兜底策略，不应替代官方驱动修复。安装或更新内核、`linux-modules-extra`、FTG 驱动包时必须处于维护模式，且不要中断正在运行的 `apt`/`dpkg`/DKMS 流程。

更新后必须验证包状态、DKMS、ostree 启动入口和回退入口：

```bash
dpkg --audit
sudo apt-get check
dkms status -k <new-kernel-version>
rg -n '<new-kernel-version>|<old-kernel-version>|vmlinuz|initramfs' /boot/loader.0 /boot/grub/grub.cfg 2>/dev/null
ls -lh /boot /boot/ostree/* 2>/dev/null
systemctl --failed --no-pager
```

KylinOS Desktop V11 的 ostree 启动链可能由内核 postinst 脚本更新，例如输出 `ostree update kernel success`。不要手工移动 `/boot/ostree` 下的镜像，也不要在未确认启动入口前删除旧内核；旧内核回退入口保留正常时，更利于后续排障。

如果用户描述的是“系统很卡、显示不流畅、打开托盘或菜单慢”，不一定会同时出现新的内核错误。也要检查 UKUI 电源管理是否在空闲低负载场景把 CPU 频率压得过低：

```bash
journalctl --since '10 minutes ago' --no-pager | rg -i 'ukui-powermanagement-service|SceneChanged|CpuMaxFreq|CpuMinFreq|setCore|policy'
for cpu in /sys/devices/system/cpu/cpu[0-9]*/cpufreq; do
  echo "== $cpu =="
  cat "$cpu/scaling_governor" 2>/dev/null || true
  cat "$cpu/scaling_min_freq" 2>/dev/null || true
  cat "$cpu/scaling_max_freq" 2>/dev/null || true
  cat "$cpu/cpuinfo_max_freq" 2>/dev/null || true
done
```

若日志显示场景切到 `idle#idle_low_Load` 后，Balance 模式使用 `CpuMaxFreq=min`、`CpuMinFreqPercentage=1`，可能导致恢复交互时明显卡顿。可以在维护模式下只修正该场景，而不是全局禁用电源管理：

```bash
pkexec sed -i.bak-<date> \
  -e 's/^idlelowloadBalanceCpuMaxFreq=min$/idlelowloadBalanceCpuMaxFreq=max/' \
  -e 's/^idlelowloadBalanceCpuMinFreqPercentage=1$/idlelowloadBalanceCpuMinFreqPercentage=50/' \
  /usr/share/ukui/ukui-power-manager/upm-hardware-global.conf
```

修改后重启或重新激活 `ukui-powermanagement-service`，再验证 CPU 最低/最高频率。注意：设置界面显示的电源模式仍可能是“平衡”档；它表示高层策略档位，不等于底层 CPU/GPU governor 必须是省电策略。

如果已经修改配置文件，但日志仍显示旧值，例如 `idlelowloadBalanceCpuMaxFreq` 仍是 `min`，优先怀疑运行中的 `ukui-powermanagement-service` 缓存了旧配置。先确认真实进程，再用完整命令行匹配重启，避免 `pgrep -x` 因进程名超过 15 字符而匹配失败：

```bash
pgrep -af '^/usr/bin/ukui-powermanagement-service$'
sudo kill $(pgrep -f '^/usr/bin/ukui-powermanagement-service$')
sudo /usr/bin/ukui-powermanagement-service
```

先确认设备节点和可用 governor：

```bash
cat /sys/class/devfreq/<devfreq-device>/governor
cat /sys/class/devfreq/<devfreq-device>/available_governors
cat /sys/class/devfreq/<devfreq-device>/available_frequencies
```

如果 `<devfreq-device>` 支持 `performance`，可以把它作为短时 A/B 验证手段，确认问题是否来自动态调频切换；验证时要说明这不是默认持久化方案：

```bash
echo performance | sudo tee /sys/class/devfreq/<devfreq-device>/governor
cat /sys/class/devfreq/<devfreq-device>/governor
```

如果运行时设置后很快又变回 `simple_ondemand` 或 `powersave`，不要立刻叠加 systemd 定时器或启动脚本。应先检查是否被 UKUI 电源管理覆盖：

```bash
journalctl --since '10 minutes ago' --no-pager | rg -i 'ukui-powermanagement-service|SceneChanged|Devfreq|devfreq|policy'
rg -n 'DevfreqPolicy=' /usr/share/ukui/ukui-power-manager /etc 2>/dev/null
```

在 KylinOS Desktop V11/UKUI 中，`ukui-powermanagement-service` 可能会按场景把 `devfreq` governor 改回配置文件里的策略。此时更合适的持久化修复是修改 UKUI 电源管理策略源，而不是写一个和它抢状态的 systemd oneshot；但修改时应尽量保留电源模式语义，不要把 Balance、Performance、Powersave 全部改成同一个策略。

修改前先备份。只有用户明确接受“所有电源模式都牺牲功耗换稳定性”时，才考虑把全局 `[devfreqPolicy]` 段全部改为 `performance`：

```bash
sudo sed -i.bak-<date> -e '/^\[devfreqPolicy\]/,/^\[/ s/^\([^#][^=]*DevfreqPolicy=\).*/\1performance/' /usr/share/ukui/ukui-power-manager/upm-hardware-global.conf
```

如果日志显示匹配了厂商硬件扩展，例如：

```text
extend config path: "/usr/share/ukui/ukui-power-manager/upm-hardware-extend.d/<vendor>.config"
```

还要检查该扩展文件是否包含 `DevfreqPolicy`、GPU 频率或功耗相关覆盖项。只有确认扩展文件没有覆盖，或已经按同样原则调整后，再验证。部分长城/飞腾设备会加载 `upm-hardware-extend.d/GreatWall.config`，该文件可能只包含背光或首启休眠策略；若没有频率相关键，不需要修改扩展文件。

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

若用户描述为“鼠标跟手，但窗口拖动、托盘、菜单或动画看起来掉帧”，而 CPU 频率下限已经较高，优先做 `devfreq` A/B 验证。掉帧时常见状态是 GPU 或显示总线相关节点处于最低档，例如 `cur_freq` 等于 `min_freq`，且 governor 为 `simple_ondemand`。将相关节点临时切到较高档后若立即流畅，说明问题更接近 GPU/显示总线动态调频策略，不应继续盲目提高 CPU 频率下限。

```bash
for d in /sys/class/devfreq/*; do
  echo "== $d =="
  cat "$d/name" 2>/dev/null || true
  cat "$d/governor" 2>/dev/null || true
  cat "$d/cur_freq" 2>/dev/null || true
  cat "$d/min_freq" 2>/dev/null || true
  cat "$d/max_freq" 2>/dev/null || true
  cat "$d/available_governors" 2>/dev/null || true
done
```

运行时 A/B 先不要直接固定最高档。优先保留 `simple_ondemand` 动态调频，只抬高 `min_freq` 下限；从较低下限开始测试，如果仍掉帧，再逐档提高。示例频率必须替换成当前设备 `available_frequencies` 中存在的值：

```bash
echo <gpu-floor-freq> | sudo tee /sys/class/devfreq/<gpu-dev>/min_freq
echo simple_ondemand | sudo tee /sys/class/devfreq/<gpu-dev>/governor
echo <bus-floor-freq> | sudo tee /sys/class/devfreq/<bus-dev>/min_freq
echo simple_ondemand | sudo tee /sys/class/devfreq/<bus-dev>/governor
```

如果低一档仍有掉帧，不要立刻回到固定 `performance`；继续提高最低频率下限，直到找到“够流畅但仍可动态调频”的最低可接受档位。只有在所有合理下限都无法解决、或硬件驱动动态调频本身会触发错误时，才考虑固定 `performance`。

如果 `/usr/share/ukui/ukui-power-manager/upm-hardware-global.conf` 已配置了期望策略，但切换 UKUI 电源模式后 `/sys/class/devfreq/*` 没有按预期变化，说明当前版本电源后端没有把策略实际下发到这些节点。此时不再反复修改 CPU 或同一配置值；可以使用 systemd oneshot 在开机和唤醒后应用“动态调频 + 最低频率下限”的硬件策略兜底，并在说明中标注功耗取舍。

飞腾 `PHYT0048:00` GPU 与 `nocfreq` 总线的常见掉帧现场是：CPU 频率已经在合理区间，但 `PHYT0048:00` 仍停在 `200000` 或 `400000`，`nocfreq` 停在 `600000` 或 `650000`。可先把 GPU 下限试到 `600000`，`nocfreq` 下限试到 `1450000`，并保持 `simple_ondemand`；如果拖动窗口和菜单动画明显改善，再做持久化。若内核日志同时出现 `ftg340` GPU hang 自动恢复，更支持先从 devfreq 策略排查。

排查卡顿时也要区分一次性 IO 噪声。例如 `com.kylin.systembackup` 或 `systembackup-daemon` 可能在短时间内执行大量 `rsync`，日志里会出现持续拷贝用户目录的进度。若守护进程当前 CPU/IO 已空闲，不要直接禁用备份服务；先把它作为短时干扰记录，再继续验证电源和 devfreq 状态。

推荐兜底脚本使用通用遍历，不写死设备名。百分比需要根据现场 A/B 结果调整；例如普通 GPU/总线节点默认取 75% 下限，显示总线类节点可取 80% 下限：

```sh
#!/bin/sh
set -eu

pick_floor_freq() {
  dev="$1"
  percent="$2"
  max_freq="$(cat "$dev/max_freq" 2>/dev/null || true)"
  avail="$(cat "$dev/available_frequencies" 2>/dev/null || true)"
  case "$max_freq" in ''|*[!0-9]*) return 1 ;; esac
  target=$((max_freq * percent / 100))
  chosen=""
  for freq in $avail; do
    case "$freq" in ''|*[!0-9]*) continue ;; esac
    if [ "$freq" -ge "$target" ] && { [ -z "$chosen" ] || [ "$freq" -lt "$chosen" ]; }; then
      chosen="$freq"
    fi
  done
  printf '%s\n' "${chosen:-$target}"
}

for dev in /sys/class/devfreq/*; do
  [ -d "$dev" ] || continue
  [ -r "$dev/available_governors" ] || continue
  [ -w "$dev/governor" ] || continue
  percent=75
  name="$(cat "$dev/name" 2>/dev/null || basename "$dev")"
  case "$name" in nocfreq) percent=80 ;; esac
  if [ -w "$dev/min_freq" ]; then
    floor_freq="$(pick_floor_freq "$dev" "$percent" 2>/dev/null || true)"
    [ -n "$floor_freq" ] && echo "$floor_freq" > "$dev/min_freq"
  fi
  if grep -qw simple_ondemand "$dev/available_governors"; then
    echo simple_ondemand > "$dev/governor"
  fi
done
```

将脚本安装到 `/usr/local/sbin/<name>`，再用 systemd oneshot 在图形会话前应用。若问题与合盖、休眠或唤醒后重新掉帧有关，可额外安装 `/lib/systemd/system-sleep/<name>`，只在 `post/*` 阶段重新执行同一脚本。

```ini
[Unit]
Description=Apply smooth desktop devfreq policy without pinning max frequency
DefaultDependencies=no
After=sysinit.target systemd-udev-settle.service
Before=graphical.target
ConditionDirectoryNotEmpty=/sys/class/devfreq

[Service]
Type=oneshot
ExecStart=/usr/local/sbin/<name>

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
for d in /sys/class/devfreq/*; do
  echo "== $d =="
  cat "$d/name" 2>/dev/null || true
  cat "$d/governor" 2>/dev/null || true
  cat "$d/cur_freq" 2>/dev/null || true
  cat "$d/min_freq" 2>/dev/null || true
  cat "$d/max_freq" 2>/dev/null || true
done
systemctl status <service-name>.service --no-pager
```

风险和取舍：

- 提高 `min_freq` 会增加一定功耗，但通常比固定 `performance` 更省电。
- 固定 `performance` 通常会明显增加功耗和发热，笔记本可能影响续航；除非 A/B 验证下限策略不够用，否则不应作为首选。
- 这是体验优先的硬件策略兜底，不等同于修复驱动或 UKUI 电源后端本身的 bug。
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
- 不要默认卸载 NVIDIA 包；包依赖、厂商软件源和图形栈文件可能有额外关系。
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
