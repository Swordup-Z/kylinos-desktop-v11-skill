# 系统问题修复：系统基础

## 适用场景

- 维护模式、磐石架构、系统级修改边界。
- systemd、D-Bus activation、系统服务异常。
- 全盘体检后的低风险噪声清理，例如 motd、PAM 残留、rsyslog 旧配置。

## 按子场景读取

- 维护模式、磐石架构、系统级修复边界：[`../../knowledge/system-repair/system/maintenance.md`](../../knowledge/system-repair/system/maintenance.md)
- 系统体检噪声、motd、PAM、rsyslog 残留：[`../../knowledge/system-repair/system/health-noise.md`](../../knowledge/system-repair/system/health-noise.md)
- 桌面服务启动顺序、D-Bus activation、服务管理器：[`../../knowledge/system-repair/ukui/system-service-manager.md`](../../knowledge/system-repair/ukui/system-service-manager.md)

## 最小诊断

```bash
mm-cli -s
systemctl --failed --no-pager
journalctl -b -p warning..alert --no-pager | tail -n 120
```
