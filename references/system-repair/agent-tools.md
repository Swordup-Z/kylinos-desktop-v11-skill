# 系统问题修复：AI 工具边界

## 适用场景

- AI 工具执行系统修复时权限不足、维护模式/root 权限边界不清。
- 修复流程中需要判断哪些操作只能诊断、哪些必须维护模式。

## 先读知识章节

- [`../../knowledge/system-repair/agent-tools/README.md`](../../knowledge/system-repair/agent-tools/README.md)

## 最小诊断

```bash
id
mm-cli -s
```
