# 系统问题修复：硬件与驱动

## 适用场景

- 指纹/生物识别设备断开、驱动缺失、认证服务异常。
- GPU、显示频率、devfreq、休眠唤醒或硬件强相关稳定性问题。

## 先读知识章节

- [`../../knowledge/system-repair/hardware/biometric-fingerprint.md`](../../knowledge/system-repair/hardware/biometric-fingerprint.md)
- [`../../knowledge/system-repair/hardware/graphics-frequency.md`](../../knowledge/system-repair/hardware/graphics-frequency.md)

## 最小诊断

```bash
lsusb
lspci 2>/dev/null || true
systemctl status biometric-authentication --no-pager 2>/dev/null || true
journalctl -b -p warning..alert --no-pager | tail -n 120
```
