# 代理与 TUN

## 定位

这是代理客户端 TUN 模式、TUN 设备、代理服务和代理核心路径问题的分类入口。Clash Verge Rev 是当前已沉淀的具体实现。

## 适用场景

- 代理客户端 TUN 模式安装失败。
- `/dev/net/tun` 缺失或不持久。
- 代理服务安装、启动或权限异常。
- 代理核心丢失、路径不一致、代理组消失。
- TUN 虚拟接口被 NetworkManager/麒麟网络管理当成新网络，触发网络发现或防火墙弹窗。

## 先读知识章节

- Clash Verge Rev TUN 具体诊断和修复：[`../knowledge/network/clash-verge-tun.md`](../knowledge/network/clash-verge-tun.md)

## 最小诊断

```bash
mm-cli -s
ls -l /dev/net/tun 2>/dev/null || true
command -v verge-mihomo || true
systemctl status clash-verge-service --no-pager
```
