# 系统问题修复：系统基础

## 适用场景

- 维护模式、磐石架构、系统级修改边界。
- systemd、D-Bus activation、系统服务异常。
- 全盘体检后的低风险噪声清理，例如 motd、PAM 残留、rsyslog 旧配置。

## 知识入口

进入系统基础索引后，按维护模式、系统保护、系统体检噪声或桌面服务启动链路继续读取具体知识。

- [`../../knowledge/system-repair/system/README.md`](../../knowledge/system-repair/system/README.md)

## 最小诊断

```bash
mm-cli -s
systemctl --failed --no-pager
journalctl -b -p warning..alert --no-pager | tail -n 120
```
