# 存储、分区与 overlay

## 定位

这是根分区、DATA 分区、`/home` 挂载、磐石架构、ostree、overlay 和 KARE 合并视图的分类入口。

## 适用场景

- 判断 `/home` 实际挂载位置。
- DATA 分区为空但根分区空间不足。
- 根分区后紧邻 backup 分区，需要缩小 backup 并扩大根分区。
- 解释大量 overlay 挂载是否实际使用。
- 评估根分区扩容或 DATA 分区调整风险。

## 先读知识章节

- 存储布局和 overlay 具体诊断：[`../knowledge/storage/layout.md`](../knowledge/storage/layout.md)

## 最小诊断

```bash
findmnt / /home /data 2>/dev/null || true
df -hT
lsblk -f
```
