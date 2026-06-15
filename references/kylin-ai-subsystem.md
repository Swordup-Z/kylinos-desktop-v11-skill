# Kylin AI 子系统

## 定位

这是任务栏/托盘 AI 助手、AI 子系统和 Kaiming AI 助手残留清理的分类入口。

## 适用场景

- 桌面右下角 AI 助手需要卸载或隐藏。
- `kylin-ai-runtime`、Kaiming AI 助手残留。
- 设置项里 AI 子系统残留但已不可用。

## 先读知识章节

- AI 子系统卸载边界和残留清理：[`../knowledge/ukui/kylin-ai-subsystem.md`](../knowledge/ukui/kylin-ai-subsystem.md)

## 最小诊断

```bash
ps -ef | rg -i 'ai|kylin-ai|kaiming' | rg -v rg || true
dpkg -l | rg -i 'kylin-ai|ai-runtime' || true
```
