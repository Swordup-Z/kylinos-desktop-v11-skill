# 系统功能增强：系统基础

## 适用场景

- 希望增强系统维护流程、持久化修复规范或本地客制化工作流。
- 需要把通用策略沉淀到 skill，而不是修复单个当前故障。

## 知识入口

进入系统基础增强索引后，按维护流程增强、本地客制化规则或源码重编译通用策略选择具体知识。

- [`../../knowledge/feature-enhancement/system/README.md`](../../knowledge/feature-enhancement/system/README.md)

## 最小诊断

```bash
mm-cli -s
git -C "$HOME/.os-fix-skill" status --short
```
