# 系统功能增强：网络与代理

## 适用场景

- 希望调整代理、TUN、网络发现提示等系统集成行为。
- 当前没有独立增强章节时，先读取修复章节中的通用边界，再判断是否需要新增功能增强知识。

## 先读知识章节

- [`../../knowledge/feature-enhancement/network/README.md`](../../knowledge/feature-enhancement/network/README.md)

## 最小诊断

```bash
ip link
nmcli connection show 2>/dev/null || true
```
