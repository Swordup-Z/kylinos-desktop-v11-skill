# 系统功能增强：网络与代理

## 适用场景

- 希望调整代理、TUN、网络发现提示等系统集成行为。
- 当前没有独立增强章节时，由场景索引判断是否需要复用修复知识。

## 知识入口

进入网络与代理增强索引后，先确认是否已有独立增强章节；没有独立增强章节时，只在实际依赖代理、TUN 或网络发现边界时复用修复知识。

- [`../../knowledge/feature-enhancement/network/README.md`](../../knowledge/feature-enhancement/network/README.md)

## 最小诊断

```bash
ip link
nmcli connection show 2>/dev/null || true
```
