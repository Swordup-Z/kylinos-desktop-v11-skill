# 系统功能增强：存储与工作区

## 适用场景

- 希望把本地源码、构建和 patch 工作区放到 DATA 分区。
- 需要制定分区、挂载或开发工作区的长期使用策略。

## 知识入口

进入存储与工作区索引后，按 DATA 工作区、源码目录、patch、回滚分类或分区挂载策略选择具体知识。

- [`../../knowledge/feature-enhancement/storage/README.md`](../../knowledge/feature-enhancement/storage/README.md)

## 最小诊断

```bash
findmnt -T /data/usershare
df -hT /data/usershare "$HOME"
```
