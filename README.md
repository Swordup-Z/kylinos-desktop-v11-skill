# kylinos-desktop-v11-skill

[English](README.en.md)

用于沉淀和复用 KylinOS Desktop V11 桌面系统问题的诊断、修复与验证经验，覆盖 UKUI、KARE/Kaiming、TUN、开机自启动、维护模式、磐石架构、系统服务、分区挂载和 overlay 等场景。

## 使用方式

把 `SKILL.md` 作为经验入口：

```bash
sed -n '1,160p' "$HOME/kylinos-desktop-v11-skill/SKILL.md"
```

如果要让 Codex、Claude Code、opencode 等 AI 编程工具自动使用这个 skill，请配置用户级全局提示词，把 KylinOS Desktop V11 系统问题路由到本仓库。参考：

```text
references/agent-global-prompts.md
```

推荐的渐进式加载流程：

```text
SKILL.md -> 相关 references/*.md -> 诊断 -> 修复 -> 验证 -> 沉淀可复用经验
```

## 安全边界

KylinOS Desktop V11 上的系统级修复可能需要维护模式。修改 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区或 KSaf 策略前，先检查：

```bash
mm-cli -s
```

只有确认当前是维护模式后，才继续系统级修改。

## 许可证

MIT
