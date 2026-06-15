# KylinOS Desktop V11 指纹与生物识别

此文档适用于 KylinOS Desktop V11 上的指纹驱动恢复、生物识别服务诊断、UKUI 指纹管理器不显示设备、驱动已注册但设备未发现等问题。

## 目录

- 基础流程
- 诊断命令
- `GW_Fingerprint_PA`
- 驱动已注册但设备未发现
- 设置界面显示“断开”
- 残留驱动配置噪音
- 硬件型号与驱动包
- 卸载风险

## 基础流程

1. 先确认当前在宿主机 namespace，不在 KARE 环境内。
2. 安装或卸载指纹驱动前，先检查维护模式。
3. 先确认硬件是否被系统枚举，再选择驱动包。
4. 安装驱动后验证包状态、驱动注册、服务状态和设备列表。
5. 退出维护模式并重启后，再做最终硬件枚举和录入验证。

## 诊断命令

```bash
hostname
readlink /proc/$$/ns/mnt
readlink /proc/$$/ns/uts
mm-cli -s
lsusb
dpkg -l | rg -i 'biometric|fingerprint|fprint|pixelauth|goodix|gigadevice'
biometric-auth-client get-driver-list
biometric-auth-client get-device-list
systemctl status biometric-authentication.service --no-pager
journalctl -u biometric-authentication.service -n 120 --no-pager
```

`biometric-device-discover` 需要 root 权限：

```bash
sudo biometric-device-discover
```

或在图形授权环境中：

```bash
pkexec biometric-device-discover
```

## `GW_Fingerprint_PA`

`GW_Fingerprint_PA` 对应 Kylin 仓库中的 Pixelauth T350P 指纹驱动包：

```bash
biometric-fingerprint-driver-pixelauth-t350p
```

安装前先确认处于维护模式，并确认当前 shell 位于宿主机 namespace。安装：

```bash
sudo apt-get install biometric-fingerprint-driver-pixelauth-t350p
```

或：

```bash
pkexec apt-get install -y biometric-fingerprint-driver-pixelauth-t350p
```

该包会安装：

```text
/usr/lib/biometric-authentication/drivers/pixelauth_t350p.so
/etc/biometric-auth/extra.conf.d/pixelauth-t350p.json
/etc/udev/rules.d/pixelauth-t350p.rules
```

安装脚本会执行：

```bash
biometric-config-tool add-driver GW_Fingerprint_PA /usr/lib/biometric-authentication/drivers/pixelauth_t350p.so
systemctl restart biometric-authentication.service
service udev restart
```

验证驱动注册：

```bash
dpkg -l biometric-fingerprint-driver-pixelauth-t350p
biometric-auth-client get-driver-list | rg 'GW_Fingerprint_PA|驱动名|启用'
systemctl status biometric-authentication.service --no-pager
```

预期 `get-driver-list` 中出现 `GW_Fingerprint_PA`，状态为启用。

## 驱动已注册但设备未发现

如果 `GW_Fingerprint_PA` 已注册并启用，但：

```bash
biometric-auth-client get-device-list
```

仍未显示对应设备，先检查 USB 枚举。Pixelauth T350P 配置中常见设备 ID 包括：

```text
2f0a:8050
33a7:2636
```

udev 规则中还可能包含：

```text
2f0a:1055
2f0a:1058
2f0a:8020
2f0a:8050
33a7:2636
```

诊断：

```bash
lsusb
journalctl -u biometric-authentication.service -n 120 --no-pager | rg -i 'GW_Fingerprint_PA|pixelauth|pabio|device|设备|0x'
```

如果 `lsusb` 没有上述设备 ID，通常不是驱动注册问题，而是硬件未被当前系统枚举。优先尝试：

- 重启系统后重新检查。
- 在 BIOS/固件设置中确认指纹设备未被禁用。
- 若设备是可插拔 USB 指纹模块，重新插拔后检查 `lsusb` 和 biometric 日志。

不要在设备未枚举时反复安装多个无关指纹驱动包；先确认硬件 ID，再匹配驱动。

## 设置界面显示“断开”

UKUI 设置里的“断开”通常表示驱动已被 `biometric-authentication.service` 加载，但驱动没有发现匹配的设备。判断顺序：

1. `biometric-auth-client get-driver-list` 中确认目标驱动存在且为启用。
2. `biometric-auth-client get-device-list` 中确认是否出现同名或同驱动 ID 的设备。
3. `journalctl -u biometric-authentication.service -b --no-pager` 中检查目标驱动是否出现 `ops_configure` 成功、`ops_driver_init` 成功、随后 `not find device` 或 `ops_discover` 返回未发现设备。
4. 用 `lsusb` 和 `journalctl -k -b --no-pager` 核对当前内核是否枚举到该驱动支持的 VID:PID。

如果服务日志显示目标驱动配置成功、初始化成功，但设备列表没有目标设备，且内核日志/`lsusb` 也没有对应 VID:PID，应优先按硬件枚举问题处理：重启到 normal mode、检查 BIOS/固件中的指纹开关、确认排线/模块供电、再根据实际 VID:PID 匹配驱动。

历史日志中 `biometric-authenticationd` 可能会记录任意 USB 插拔事件，例如 `provid:<VID>_<PID> insert/remove`。这类记录不能直接证明该 USB 设备是指纹模块；需要结合 `lsusb`、`/var/log/kern.log`、`/var/log/syslog`、`/usr/share/misc/usb.ids`、存储审计日志或设备路径判断设备类型。外接 U 盘、手机、摄像头、蓝牙、鼠标等也可能出现在 USB 插拔日志里。

## 残留驱动配置噪音

`/etc/biometric-auth/biometric-drivers.conf` 中可能残留指向 `/opt/biometric/drivers` 的旧驱动项。如果这些文件不是任何已安装包提供的文件，或缺少对应的 `extra` 目录/JSON 配置，服务日志可能出现某些驱动配置失败。

诊断：

```bash
sed -n '1,260p' /etc/biometric-auth/biometric-drivers.conf
dpkg -S /opt/biometric/drivers/<driver>.so /usr/lib/biometric-authentication/drivers/extra/<driver-extra>.so 2>/dev/null || true
journalctl -u biometric-authentication.service -b --no-pager | rg -i '驱动配置失败|extra|not find device|<driver-name>'
```

残留驱动配置失败会制造日志噪音，但不等同于 `GW_Fingerprint_PA` 驱动失败。只有确认残留项不属于当前硬件、且有备份和维护模式后，才考虑禁用或移除残留驱动配置。不要把清理残留配置当成硬件未枚举问题的修复。

## 硬件型号与驱动包

硬件型号只能作为线索，不能替代设备枚举结果。可先记录整机型号和 BIOS 版本：

```bash
hostnamectl status
```

例如某些长城整机可能在仓库中同时出现 GreatWall 人脸检测驱动、Pixelauth 指纹驱动、FocalTech 指纹驱动或 GigaDevice 指纹驱动。包名或整机厂商相似不代表一定匹配当前指纹模块；应优先使用当前内核枚举到的 USB/ACPI/I2C/SPI 设备 ID 来选驱动。

查找候选驱动包时只作为参考：

```bash
apt-cache search 'fingerprint|pixelauth|goodix|gigadevice|greatwall|biometric'
apt-cache show <candidate-package>
```

如果候选包描述的是人脸检测、UKEY、虹膜、指静脉或外设 SDK，不应作为指纹模块驱动安装。无法确认硬件 ID 时，不要批量安装多个候选驱动。

## 卸载风险

`biometric-fingerprint-driver-pixelauth-t350p` 的卸载脚本会尝试按 `GW_Fingerprint_PA` 清理已录入的指纹特征。因此除非确认要移除该驱动，不要随意执行 `apt remove` 或 `apt purge`。卸载前应备份和确认用户指纹数据影响。
