# 指纹与生物识别

## 定位

这是指纹驱动、`GW_Fingerprint_PA`、Pixelauth T350P 和生物识别服务的分类入口。

## 适用场景

- 设置界面指纹状态断开。
- 已安装驱动但设备未被识别。
- 需要恢复或验证指纹驱动和服务。

## 先读知识章节

- 指纹驱动和生物识别具体诊断：[`../knowledge/hardware/biometric-fingerprint.md`](../knowledge/hardware/biometric-fingerprint.md)

## 最小诊断

```bash
systemctl status biometric-authentication.service --no-pager
lsusb
dpkg -l | rg -i 'finger|biometric|pixelauth|gw_' || true
```
