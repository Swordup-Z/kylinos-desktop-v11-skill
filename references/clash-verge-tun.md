# Clash Verge TUN

## 定位

这是 Clash Verge Rev TUN 模式、代理服务和 `verge-mihomo` 路径问题的分类入口。

## 适用场景

- TUN 模式安装失败。
- `/dev/net/tun` 缺失或不持久。
- `clash-verge-service` 安装、启动或权限异常。
- `verge-mihomo` 丢失、路径不一致、代理组消失。

## 先读知识章节

- Clash Verge TUN 具体诊断和修复：[`../knowledge/network/clash-verge-tun.md`](../knowledge/network/clash-verge-tun.md)

## 最小诊断

```bash
mm-cli -s
ls -l /dev/net/tun 2>/dev/null || true
command -v verge-mihomo || true
systemctl status clash-verge-service --no-pager
```
