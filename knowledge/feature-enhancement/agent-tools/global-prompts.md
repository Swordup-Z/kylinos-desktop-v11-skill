# 多工具全局提示词与 skill 路由

此文档用于初始化 Codex、Claude Code、opencode 等 AI 编程工具的用户级全局提示词，使其在处理 KylinOS Desktop V11 系统问题时按需加载共享经验库 `$HOME/.os-fix-skill/SKILL.md`，而不是把全部经验一次性塞入上下文。

## 目录

- 设计原则
- 常见全局提示词文件
- 通用全局提示词模板
- 工具特定初始化
- 初始化验证

## 设计原则

- 全局提示词只做轻量路由：识别问题域、要求先读取 skill 入口、按需读取引用文档、修复后沉淀经验。
- 只要用户问题属于 KylinOS Desktop V11 桌面系统维护场景，就加载 `$HOME/.os-fix-skill/SKILL.md`；即使问题尚未被当前 skill 的专门 reference 覆盖，也应读取通用系统维护 reference。普通代码开发、文档编辑、Git 操作或其他无关任务不要加载该 skill，避免无用 token 消耗和上下文膨胀。
- skill 本体放在 `$HOME/.os-fix-skill/`，作为多个 AI 工具共用的本机经验库；不要只放到某个工具的内置 skills 目录。文档内部使用 `$HOME`、`<user>`、`<app-id>` 等占位符，不写死具体用户名。
- 独立工具或应用开发放在 `$HOME/desktop-develop`（通常是 `/data/usershare/desktop-develop` 的便捷入口）下；全局提示词只负责把开发请求路由到工作区或最近项目的 `AGENTS.md`，具体项目规则由项目目录维护。
- 使用渐进式披露：先读 `SKILL.md`，判断任务类型是系统问题修复还是系统功能增强，再按 `references/system-repair/<scenario>.md` 或 `references/feature-enhancement/<scenario>.md` 读取具体场景；如果 reference 指向 `knowledge/` 章节，再按需读取对应章节。不要预加载所有 reference 或 knowledge。
- 如果工具原生支持 `SKILL.md` 发现机制，可以同时把该 skill 安装/同步到工具支持的全局 skills 目录；如果不支持，则依靠全局提示词显式要求读取 `$HOME/.os-fix-skill/SKILL.md`。
- 系统级修复规则不依赖具体工具：修改 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区、KSaf 策略等之前，必须先运行 `mm-cli -s` 并确认维护模式。

## 常见全局提示词文件

不同工具的用户级入口可能不同，初始化前应以当前工具官方文档为准。常见路径：

```text
Codex:       $HOME/.codex/AGENTS.md
Claude Code: $HOME/.claude/CLAUDE.md
opencode:    $HOME/.config/opencode/AGENTS.md
```

opencode 还支持从多个全局 skills 目录发现 `SKILL.md`，例如：

```text
$HOME/.config/opencode/skills/<skill-name>/SKILL.md
$HOME/.claude/skills/<skill-name>/SKILL.md
$HOME/.agents/skills/<skill-name>/SKILL.md
```

同一台机器同时使用多个工具时，把下面的“通用全局提示词模板”同步到各工具的用户级全局提示词文件中，确保行为一致。

## 通用全局提示词模板

```markdown
# 全局 AI Agent 规则

## Kylin Desktop V11 系统问题经验入口

- 当用户处理 KylinOS Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、磐石架构、系统保护、分区、挂载、overlay、AI 子系统等桌面操作系统问题时，默认使用 `$HOME/.os-fix-skill/SKILL.md` 作为经验入口。
- 如果当前任务不是上述桌面系统问题，例如普通代码开发、文档编辑、Git 操作、业务需求分析或通用软件问题，不要读取该 skill，也不要预加载其中的 `references/` 或 `knowledge/`。
- 开始处理上述问题前，先读取 `$HOME/.os-fix-skill/SKILL.md`，判断任务类型是系统问题修复还是系统功能增强，再按其中“参考文档路由”选择性读取 `references/system-repair/<scenario>.md` 或 `references/feature-enhancement/<scenario>.md`。如果 reference 指向 `knowledge/` 下的具体章节，再按需读取对应 knowledge。如果没有命中专门 reference，系统问题修复至少读取 `$HOME/.os-fix-skill/references/system-repair/system.md`，系统功能增强至少读取 `$HOME/.os-fix-skill/references/feature-enhancement/system.md`。不要在没有需要时预加载全部 reference 或 knowledge。
- 当当前工作目录位于 `$HOME/desktop-develop` 或 `/data/usershare/desktop-develop` 下，且任务是独立工具或应用开发时，先读取最近的项目级 `AGENTS.md`。如果在工作区根目录，先读取 `$HOME/desktop-develop/AGENTS.md` 并按其中路由进入具体项目；不要把项目实现写到工作区根目录或 `$HOME/.os-fix-skill`。
- 如果本地 skill 已读取但没有覆盖用户的系统问题，在自行探索修复前，先尽力同步 `$HOME/.os-fix-skill` 的 GitHub 仓库，查看是否已有新增经验。同步前先确认该目录是 git 仓库且工作树无本地改动；只使用 `git fetch`、`git status -sb`、`git pull --ff-only` 这类非破坏流程。若本地有未提交改动、分支分叉、网络不可用或 fast-forward 失败，不要强制覆盖，也不要把同步失败作为阻塞错误；继续基于当前资料、模型能力和通用系统维护经验诊断。
- 处理问题时遵循“先诊断、再修改、最后验证”：先读取状态、日志、挂载、服务、配置和实际路径，再执行提权或修改命令。
- 执行系统级修复前必须检查维护模式：运行 `mm-cli -s`。只有确认当前是 maintain mode，才允许修改 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区、KSaf 策略等。
- 如果当前不是维护模式，不要继续系统级修复。应让用户执行 `sudo mm-cli -o`，或在用户授权后执行 `pkexec mm-cli -o`；随后提醒用户重启系统，重启后重新打开当前 AI 工具再继续。
- 切换维护模式并重启前，只允许做诊断、读取状态、模拟安装/卸载等非破坏操作；不要执行实际安装、卸载、写系统路径或改系统服务。
- 不要删除、移动或覆盖用户已有的可执行文件、配置文件、订阅文件、代理核心、systemd 单元或用户数据，除非用户明确要求且已验证影响。
- 问题确认修复完成后，主动判断是否产生新的可复用诊断步骤、修复步骤、风险点或系统特性；有则立即更新到 `$HOME/.os-fix-skill/SKILL.md`、对应 `references/system-repair/` 或 `references/feature-enhancement/` 路由，以及 `knowledge/system-repair/` 或 `knowledge/feature-enhancement/` 章节，不等用户追问。
- 如果实际解决的是当前 skill 尚未覆盖的 KylinOS Desktop V11 系统问题，应新增合适的 `references/system-repair/<scenario>.md` 或 `references/feature-enhancement/<scenario>.md` 作为分类入口，并把详细经验沉淀到同任务类型、同场景的 `knowledge/` 章节；再在 `SKILL.md` 的“参考文档路由”中补充入口。
- 执行任何 `git commit` 时，提交作者、提交正文和提交 trailer 不得包含 AI 相关署名或协作生成信息，例如 `Co-authored-by: Claude`、`Co-authored-by: Codex`、`Generated with ...`、`AI-assisted`、`🤖` 等。
- 最终回复中说明本次经验是否已记录；如果已记录，给出对应 skill 文档路径；如果没有记录，说明原因是没有新增可复用经验。
- 经验文档使用中文。避免写入当前用户专属路径、用户名或一次性状态；需要出现用户目录时使用 `$HOME`、`<user>`、`<app-id>`、`<desktop-id>` 等通用占位符。
```

## 工具特定初始化

也可以把下面这段提示词直接发给 AI 工具，让它自行拉取 GitHub 仓库并初始化全局提示词：

```text
请帮我安装这个 KylinOS Desktop V11 系统问题处理 skill：

https://github.com/Swordup-Z/kylinos-v11-desktop-fix-skill

要求：
1. 将仓库克隆到 $HOME/.os-fix-skill，作为 Codex、Claude Code、opencode 等工具共用的本机经验库。
2. 根据当前工具类型，更新用户级全局提示词文件：
   - Codex: $HOME/.codex/AGENTS.md
   - Claude Code: $HOME/.claude/CLAUDE.md
   - opencode: $HOME/.config/opencode/AGENTS.md
3. 在全局提示词中加入规则：处理 KylinOS Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、磐石架构、系统保护、分区、挂载、overlay、AI 子系统等桌面系统问题时，先读取 $HOME/.os-fix-skill/SKILL.md，判断任务类型是系统问题修复还是系统功能增强，再按其中“参考文档路由”选择性读取 references/system-repair/<scenario>.md 或 references/feature-enhancement/<scenario>.md；如果 reference 指向 knowledge/ 下的具体知识章节，再按需读取对应 knowledge；如果没有命中专门 reference，系统问题修复至少读取 references/system-repair/system.md，系统功能增强至少读取 references/feature-enhancement/system.md；如果当前任务不是桌面系统问题，不要加载该 skill。
4. 当当前工作目录位于 $HOME/desktop-develop 或 /data/usershare/desktop-develop 下，且任务是独立工具或应用开发时，先读取最近的项目级 AGENTS.md；如果在工作区根目录，先读取 $HOME/desktop-develop/AGENTS.md 并按其中路由进入具体项目。不要把项目实现写到工作区根目录或 $HOME/.os-fix-skill。
5. 如果本地 skill 已读取但没有覆盖当前系统问题，在自行探索修复前，先尽力同步 $HOME/.os-fix-skill 的 GitHub 仓库：先确认它是 git 仓库且工作树无本地改动，再使用 git fetch、git status -sb、git pull --ff-only 查看是否有新增经验；不要用 reset、rebase 或强制覆盖本地改动。同步失败不阻塞问题处理，继续用当前资料、模型能力和通用经验诊断。
6. 系统级修复前必须先运行 mm-cli -s 检查维护模式；非维护模式只允许诊断，不要实际修改 /usr、/etc、/opt、系统包、系统服务、设备节点、分区或 KSaf 策略。
7. 问题确认修复后，如果产生新的可复用经验，应更新到该 skill 的 SKILL.md、references/system-repair/ 或 references/feature-enhancement/ 路由，以及 knowledge/system-repair/ 或 knowledge/feature-enhancement/ 下的具体章节；如果该问题原本未被当前 skill 覆盖，应新增合适的 reference 作为分类入口，并把详细经验沉淀到同任务类型、同场景的 knowledge 章节。
8. 执行任何 git commit 时，提交作者、提交正文和提交 trailer 不得包含 AI 相关署名或协作生成信息。
9. 安装完成后验证：读取 $HOME/.os-fix-skill/SKILL.md，并告诉我后续处理 KylinOS Desktop V11 系统问题时会先使用哪个 skill 入口。
```

Codex：

```bash
mkdir -p "$HOME/.codex"
${EDITOR:-vi} "$HOME/.codex/AGENTS.md"
```

Claude Code：

```bash
mkdir -p "$HOME/.claude"
${EDITOR:-vi} "$HOME/.claude/CLAUDE.md"
```

opencode：

```bash
mkdir -p "$HOME/.config/opencode"
${EDITOR:-vi} "$HOME/.config/opencode/AGENTS.md"
```

如果工具支持通过配置文件引用额外 instruction 文件，全局提示词文件可保持很短，只引用 `$HOME/.os-fix-skill/SKILL.md`。但不要依赖符号链接或非官方导入语法，除非该工具文档明确支持。

## 初始化验证

```bash
test -f "$HOME/.os-fix-skill/SKILL.md" && sed -n '1,80p' "$HOME/.os-fix-skill/SKILL.md"
test -f "$HOME/.codex/AGENTS.md" && rg -n '\\.os-fix-skill|mm-cli -s|磐石架构' "$HOME/.codex/AGENTS.md"
test -f "$HOME/.claude/CLAUDE.md" && rg -n '\\.os-fix-skill|mm-cli -s|磐石架构' "$HOME/.claude/CLAUDE.md"
test -f "$HOME/.config/opencode/AGENTS.md" && rg -n '\\.os-fix-skill|mm-cli -s|磐石架构' "$HOME/.config/opencode/AGENTS.md"
test -f "$HOME/desktop-develop/AGENTS.md" && rg -n 'kylin-space-guard|computer-use|\\.os-fix-skill' "$HOME/desktop-develop/AGENTS.md"
```

验证问题：

```text
我现在要处理 Kylin Desktop V11 的 TUN/自启动/维护模式问题，你会先读取哪个 skill 入口？
```

预期回答应指向 `$HOME/.os-fix-skill/SKILL.md`，并说明会先判断系统问题修复或系统功能增强，再按需读取对应 `references/system-repair/` 或 `references/feature-enhancement/`；如果 reference 指向 `knowledge/`，再读取对应知识章节。
