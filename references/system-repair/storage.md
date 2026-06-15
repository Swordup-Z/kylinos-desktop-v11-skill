# 系统问题修复：存储与挂载

## 适用场景

- 根分区空间不足、DATA 分区未按预期使用。
- `/home` 挂载位置、backup 分区、overlay/KARE 合并视图判断。
- 离线分区调整前的风险边界。

## 先读知识章节

- [`../../knowledge/system-repair/storage/layout.md`](../../knowledge/system-repair/storage/layout.md)

## 最小诊断

```bash
findmnt -T "$HOME"
findmnt
lsblk -f
df -hT
```
