# 系统功能增强：AI 工具配置

## 适用场景

- Codex、Claude Code、opencode 等工具的全局提示词。
- 默认权限、full access、系统问题 skill 自动加载和渐进式披露。
- 让 AI 工具在系统问题修复完成后自动沉淀经验。

## 先读知识章节

- [`../../knowledge/feature-enhancement/agent-tools/README.md`](../../knowledge/feature-enhancement/agent-tools/README.md)

## 最小诊断

```bash
test -f "$HOME/.codex/config.toml" && sed -n '1,160p' "$HOME/.codex/config.toml"
test -f "$HOME/AGENTS.md" && sed -n '1,200p' "$HOME/AGENTS.md"
```
