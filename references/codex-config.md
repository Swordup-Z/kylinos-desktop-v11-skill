# Codex 配置

## 定位

这是 Codex 用户级配置、默认权限、全局提示词和系统修复边界的分类入口。

## 适用场景

- 配置 Codex 默认 full access。
- 解释 Codex 权限与维护模式/root 权限边界。
- 配置 Codex 全局规则加载本 skill。

## 先读知识章节

- Codex 配置细节：[`../knowledge/agent-tools/codex-config.md`](../knowledge/agent-tools/codex-config.md)
- 多工具全局提示词：[`../knowledge/agent-tools/global-prompts.md`](../knowledge/agent-tools/global-prompts.md)

## 最小诊断

```bash
test -f "$HOME/.codex/AGENTS.md" && sed -n '1,160p' "$HOME/.codex/AGENTS.md"
```
