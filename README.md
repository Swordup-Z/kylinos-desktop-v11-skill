# kylinos-desktop-v11-skill

[English](README.en.md)

用于沉淀和复用 KylinOS Desktop V11 桌面系统问题的诊断、修复与验证经验，覆盖 UKUI、KARE/Kaiming、TUN、开机自启动、维护模式、磐石架构、系统服务、分区挂载和 overlay 等场景。

## 安装方式

这个仓库不是一个直接运行的程序，而是一组给 AI 编程工具读取的“系统问题处理经验”。推荐用法是：把仓库放到用户目录，然后在 Codex、Claude Code、opencode 等工具的全局提示词里告诉它们遇到 KylinOS Desktop V11 系统问题时先读取这里的 `SKILL.md`。

### 方式一：让 AI 工具自动安装

你也可以直接把下面这段话发给 Codex、Claude Code、opencode 等工具，让它自己拉取仓库并完成配置：

```text
请帮我安装这个 KylinOS Desktop V11 系统问题处理 skill：

https://github.com/Swordup-Z/kylinos-desktop-v11-skill

要求：
1. 将仓库克隆到 $HOME/kylinos-desktop-v11-skill。
2. 根据当前工具类型，更新用户级全局提示词文件：
   - Codex: $HOME/.codex/AGENTS.md
   - Claude Code: $HOME/.claude/CLAUDE.md
   - opencode: $HOME/.config/opencode/AGENTS.md
3. 在全局提示词中加入规则：处理 KylinOS Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、磐石架构、系统保护、分区、挂载、overlay、AI 子系统等桌面系统问题时，先读取 $HOME/kylinos-desktop-v11-skill/SKILL.md，再按其中“参考文档”选择性读取 references/*.md；如果没有命中专门 reference，至少读取 references/system-maintenance.md；如果当前任务不是桌面系统问题，不要加载该 skill。
4. 系统级修复前必须先运行 mm-cli -s 检查维护模式；非维护模式只允许诊断，不要实际修改 /usr、/etc、/opt、系统包、系统服务、设备节点、分区或 KSaf 策略。
5. 问题确认修复后，如果产生新的可复用经验，应更新到该 skill 的 SKILL.md 或 references/*.md；如果该问题原本未被当前 skill 覆盖，应新增合适的 reference 并在 SKILL.md 中补充入口。
6. 执行任何 git commit 时，提交作者、提交正文和提交 trailer 不得包含 AI 相关署名或协作生成信息。
7. 建议后续处理系统问题时专门使用一个固定会话名，例如 os-fix；如果当前 AI 工具支持恢复命令，后续可用 <tool> resume os-fix 恢复同一个系统修复上下文。
8. 安装完成后验证：读取 $HOME/kylinos-desktop-v11-skill/SKILL.md，并告诉我后续处理 KylinOS Desktop V11 系统问题时会先使用哪个 skill 入口。
```

### 方式二：手动安装

#### 1. 克隆到用户目录

```bash
cd "$HOME"
git clone https://github.com/Swordup-Z/kylinos-desktop-v11-skill.git
```

克隆后入口文件应位于：

```bash
$HOME/kylinos-desktop-v11-skill/SKILL.md
```

#### 2. 配置 AI 工具的全局提示词

把下面这段加入你使用的工具的用户级全局提示词文件：

```markdown
处理 KylinOS Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、磐石架构、系统保护、分区、挂载、overlay、AI 子系统等桌面操作系统问题时，先读取 `$HOME/kylinos-desktop-v11-skill/SKILL.md`，再按其中“参考文档”选择性读取对应 `references/*.md`。如果没有命中专门 reference，至少读取 `references/system-maintenance.md`。如果当前任务不是桌面系统问题，不要加载该 skill；不要一次性预加载全部 reference。

系统级修复前必须先运行 `mm-cli -s` 检查维护模式。只有确认当前是 maintain mode，才允许修改 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区、KSaf 策略等。

问题确认修复完成后，如果产生新的可复用诊断步骤、修复步骤、风险点或系统特性，应更新到 `$HOME/kylinos-desktop-v11-skill/SKILL.md` 或对应 `references/*.md`。

如果实际解决的是当前 skill 尚未覆盖的 KylinOS Desktop V11 系统问题，应新增合适的 `references/*.md` 或扩展现有参考文档，并在 `SKILL.md` 的“参考文档”中补充入口。
```

常见全局提示词文件位置：

```text
Codex:       $HOME/.codex/AGENTS.md
Claude Code: $HOME/.claude/CLAUDE.md
opencode:    $HOME/.config/opencode/AGENTS.md
```

更完整的多工具配置模板见：

```text
references/agent-global-prompts.md
```

#### 3. 验证配置是否生效

在你的 AI 工具里问：

```text
我现在要处理 KylinOS Desktop V11 的 TUN/自启动/维护模式问题，你会先读取哪个 skill 入口？
```

预期回答应指向：

```text
$HOME/kylinos-desktop-v11-skill/SKILL.md
```

#### 4. 实际使用

建议给系统问题处理专门准备一个固定会话，例如 `os-fix`。这样系统状态、已做过的诊断、维护模式切换、已修复问题和经验沉淀记录都能保留在同一个上下文里。

如果你使用的 AI 工具支持命名会话或恢复会话，后续可以用类似下面的命令继续同一个系统修复会话：

```bash
<tool> resume os-fix
```

例如：

```bash
codex resume os-fix
claude resume os-fix
opencode resume os-fix
```

以后直接描述系统问题即可，例如：

```text
Clash Verge 无法安装 TUN 模式，请帮我诊断。
```

AI 工具应先读取 `SKILL.md`，再按需读取相关 `references/*.md`，然后按“诊断 -> 修复 -> 验证 -> 记录经验”的流程处理。

## 核心基础要求

使用这个 skill 处理系统问题时，AI 工具必须遵守以下基础要求：

- 只要任务涉及 KylinOS Desktop V11 桌面系统维护场景，就先读取 [`SKILL.md`](SKILL.md)，再根据其中“参考文档”按需读取具体 `references/*.md`；不要一次性预加载所有 reference。
- 如果没有命中专门 reference，至少读取通用系统维护文档 [`references/system-maintenance.md`](references/system-maintenance.md)。
- 普通代码开发、文档编辑、Git 操作或其他无关任务不要加载该 skill。
- 按“诊断 -> 修复 -> 验证 -> 沉淀经验”的闭环处理问题。
- 系统问题默认以持久化修复为目标；临时止血后，还要确认重启、重新登录、服务重拉起或应用重启后是否仍然有效。
- 执行系统级修复前必须运行 `mm-cli -s` 检查维护模式；非维护模式只允许诊断、读取状态、模拟安装/卸载等非破坏操作。
- 如果当前不是维护模式，应先进入维护模式并要求用户重启；修复完成后，应退出维护模式并要求用户再次重启回到 normal mode。
- 不要删除、移动或覆盖用户已有的可执行文件、配置文件、订阅文件、代理核心、systemd 单元或用户数据，除非用户明确要求且已验证影响。
- 问题确认修复后，如果产生新的可复用诊断步骤、修复步骤、风险点或系统特性，应更新到 `SKILL.md` 或对应 `references/*.md`。
- 如果实际解决的是当前 skill 尚未覆盖的 KylinOS Desktop V11 系统问题，应新增合适的 `references/*.md` 或扩展现有参考文档，并在 `SKILL.md` 的“参考文档”中补充入口。
- 执行任何 `git commit` 时，提交作者、提交正文和提交 trailer 不得包含 AI 相关署名或协作生成信息。

## 能处理的问题

- 通用系统维护、维护模式、系统级修复边界、未覆盖问题的最小闭环：[`references/system-maintenance.md`](references/system-maintenance.md)
- UKUI 右侧托盘小图标、StatusNotifier 图标顺序/隐藏区重启后不保留、`systemTray.json`、`orderedItems`、`separateIndex`：[`references/ukui-system-tray.md`](references/ukui-system-tray.md)
- 图形驱动、GPU/显示频率、`devfreq` 调频失败、`failed to set <driver> frequency`、无 NVIDIA 硬件但 NVIDIA 驱动反复探测等硬件强相关图形稳定性问题：[`references/graphics-frequency.md`](references/graphics-frequency.md)
- `ukui-system-service-manager.service` 反复 timeout、`QDBusError("", "")`、`org.ukui.serviceManager` 被孤儿进程占用、UKUI 系统服务管理器异常：[`references/ukui-system-service-manager.md`](references/ukui-system-service-manager.md)
- Clash Verge Rev TUN 模式、`clash-verge-service`、`/dev/net/tun`、`verge-mihomo` 路径或核心丢失问题：[`references/clash-verge-tun.md`](references/clash-verge-tun.md)
- UKUI 开机自启动不生效、设置界面不显示新增启动项、`sort-app-list` / `statusMap` 异常：[`references/ukui-autostart.md`](references/ukui-autostart.md)
- 任务栏/托盘 AI 助手、AI 子系统、Kaiming AI 助手、`kylin-ai-memorymap` 文件保护箱残留清理：[`references/kylin-ai-subsystem.md`](references/kylin-ai-subsystem.md)
- 根分区、DATA 分区、`/home` 挂载、磐石架构/ostree/overlay/KARE 合并视图、空间占用判断：[`references/storage-layout.md`](references/storage-layout.md)
- Codex 用户级配置、默认 full access、权限显示、维护模式/root 权限边界：[`references/codex-config.md`](references/codex-config.md)
- Codex、Claude Code、opencode 等多工具全局提示词入口、自动安装提示词、渐进式披露加载模板：[`references/agent-global-prompts.md`](references/agent-global-prompts.md)

## 安全边界

KylinOS Desktop V11 上的系统级修复通常需要维护模式。修改 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区或 KSaf 策略前，必须先检查当前模式：

```bash
mm-cli -s
```

如果当前已经是维护模式，才继续实际系统级修改。

如果当前不是维护模式，不要继续修改系统。先进入维护模式：

```bash
sudo mm-cli -o
```

或在图形/Polkit 环境中执行：

```bash
pkexec mm-cli -o
```

执行后需要重启系统，重启后重新打开 AI 工具再继续修复。在进入维护模式并重启前，只允许做诊断、读取状态、模拟安装/卸载等非破坏操作。

问题修复并验证完成后，应保存修改并退出维护模式：

```bash
sudo mm-cli -c -a
```

或：

```bash
pkexec mm-cli -c -a
```

退出维护模式后通常也需要再次重启系统，重启后才会回到 normal mode。不要把系统长期留在维护模式。

## 许可证

MIT
