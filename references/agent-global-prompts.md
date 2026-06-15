# AI 工具全局提示词

## 定位

这是 Codex、Claude Code、opencode 等工具全局提示词和 skill 路由规则的分类入口。

## 适用场景

- 给 AI 工具配置 KylinOS Desktop V11 skill 自动加载规则。
- 需要多工具通用提示词模板。
- 初始化或检查全局提示词文件。

## 先读知识章节

- 多工具全局提示词模板和安装提示词：[`../knowledge/agent-tools/global-prompts.md`](../knowledge/agent-tools/global-prompts.md)

## 最小诊断

```bash
ls -l "$HOME/.codex/AGENTS.md" "$HOME/.claude/CLAUDE.md" "$HOME/.config/opencode/AGENTS.md" 2>/dev/null || true
```
