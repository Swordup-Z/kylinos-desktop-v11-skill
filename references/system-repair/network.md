# 系统问题修复：网络与代理

## 适用场景

- Clash Verge Rev TUN 模式失败。
- `/dev/net/tun` 缺失、代理服务安装失败、代理核心路径异常。
- 网络模式弹窗、TUN 虚拟连接触发网络发现提示等代理相关系统集成问题。

## 知识入口

进入网络与代理索引后，按代理、TUN、`/dev/net/tun`、网络发现弹窗或代理核心路径继续读取具体知识。

- [`../../knowledge/system-repair/network/README.md`](../../knowledge/system-repair/network/README.md)

## 最小诊断

```bash
mm-cli -s
ls -l /dev/net/tun 2>/dev/null || true
systemctl status clash-verge-service --no-pager 2>/dev/null || true
ip link
```
