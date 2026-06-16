# 系统问题修复：存储与挂载

## 适用场景

- 根分区空间不足、DATA 分区未按预期使用。
- `/home` 挂载位置、backup 分区、overlay/KARE 合并视图判断。
- 离线分区调整前的风险边界。

## 知识入口

进入存储与挂载索引后，按分区、挂载、DATA、`/home`、backup、overlay 或空间占用继续读取具体知识。

- [`../../knowledge/system-repair/storage/README.md`](../../knowledge/system-repair/storage/README.md)

## 最小诊断

```bash
findmnt -T "$HOME"
findmnt
lsblk -f
df -hT
```
