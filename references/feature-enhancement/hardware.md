# 系统功能增强：硬件能力

## 适用场景

- 硬件问题恢复后，需要沉淀能力启用、硬件相关源码改造或增强策略。
- 当前没有独立增强章节时，由场景索引判断是否需要复用修复知识。

## 知识入口

进入硬件能力索引后，先确认是否已有独立增强章节；没有独立增强章节时，只在实际依赖驱动或硬件稳定性边界时复用修复知识。

- [`../../knowledge/feature-enhancement/hardware/README.md`](../../knowledge/feature-enhancement/hardware/README.md)

## 最小诊断

```bash
lsusb
lspci 2>/dev/null || true
```
