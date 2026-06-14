# Codex 用户级配置

此文档记录当前桌面系统上 Codex 的用户级配置经验，尤其是默认 full access、全局规则文件、用户问题 skill 入口与系统级修复权限的边界。若需要同时初始化 Claude Code、opencode 等工具的全局提示词，读取 [agent-global-prompts.md](agent-global-prompts.md)。

## 目录

- 配置位置
- 默认 full access
- 终端复制与滚动历史
- 权限边界
- 常用检查
- 全局用户问题 skill 初始化
- Kylin Desktop V11 经验沉淀

## 配置位置

Codex 用户级配置文件通常在：

```bash
$HOME/.codex/config.toml
```

Codex 用户级全局规则文件通常在：

```bash
$HOME/.codex/AGENTS.md
```

查看当前配置：

```bash
sed -n '1,220p' "$HOME/.codex/config.toml"
sed -n '1,220p' "$HOME/.codex/AGENTS.md"
```

## 默认 full access

若希望 Codex 默认以 full access 文件系统权限启动，在 `$HOME/.codex/config.toml` 中设置：

```toml
sandbox_mode = "danger-full-access"
```

如果希望隐藏 full access 提示，可配置：

```toml
[notice]
hide_full_access_warning = true
```

可以在 TUI 状态栏显示当前权限：

```toml
[tui]
status_line = ["model-with-reasoning", "context-remaining", "five-hour-limit", "thread-title", "weekly-limit", "permissions"]
```

## 终端复制与滚动历史

如果 Codex 在终端输出内容后，鼠标难以选中复制前面的输出，先区分是 Codex TUI 的 alternate screen 行为，还是终端滚动策略导致的问题。

如果 Codex 空闲时可以正常选中文字，但正在流式输出内容时无法稳定选中，通常不是终端滚动开关问题，而是 TUI 持续重绘、输出滚动或刷新当前视图导致鼠标选区被打断。先检查终端模拟器滚动设置，再减少 Codex TUI 自身的动态刷新。

优先检查终端模拟器的滚动设置。若终端启用了“击键时滚动”或“输出时滚动”等类似选项，按键输入或新输出可能让视图自动跳回底部，导致回看历史输出时难以稳定选中复制。可以在终端设置中关闭这些自动滚动选项，再重新打开 Codex 验证鼠标选择是否恢复正常。

可以用普通 shell 命令隔离是否为 Codex 专属问题：

```bash
bash -lc 'i=0; while true; do printf "\rworking %06d" "$i"; i=$((i+1)); sleep 0.05; done'
```

运行后尝试鼠标选中文字，按 `Ctrl+C` 停止。如果该命令运行时也无法稳定选中，说明问题不是 Codex 独有，而是当前终端/VTE 对持续重绘同一行内容时的选区处理限制。Codex working 动画、spinner、状态栏刷新和部分 TUI 重绘都属于类似场景。

若用户明确要求“保留 Codex working 动画，同时 working 时也能稳定用鼠标选中文字”，优先测试更换终端模拟器，而不是修改 Codex 配置。已验证 Tabby 在 Codex 输出/working 时可以继续选中文字；这说明问题可由终端模拟器选区实现差异解决。切换终端后保留 Codex 默认动画配置即可。

终端层可以验证软件流控 workaround。若 `stty -a` 显示 `ixon`，且 `stop = ^S`、`start = ^Q`，可以在持续输出时按 `Ctrl+S` 暂停终端输出，完成鼠标选择/复制后按 `Ctrl+Q` 恢复输出：

```bash
script -q -c 'stty -a' /dev/null | tr ';' '\n' | rg 'ixon|start|stop'
```

该方法不改变 Codex 配置，也不关闭动画，只是在需要选择文字时临时冻结终端输出。如果用户不想临时冻结输出，优先使用已验证支持持续输出时选择文字的终端模拟器，例如 Tabby。

如果终端滚动设置已经正常，但仍使用 VTE/mate-terminal 类终端，在当前 Codex 版本和该终端组合下没有发现可同时满足“保留 working 动画”和“持续输出时稳定鼠标选择”的独立 Codex 配置。动画、spinner、状态刷新和流式输出都会导致 TUI 重绘；只要重绘发生，VTE/mate-terminal 的终端选区就可能被刷新打断。

不要为了绕过该问题直接关闭全局动画或创建专门的“复制友好”profile，除非用户明确接受“牺牲动画效果换取更稳定选择”的取舍。若用户要求两者都保留，应保留默认动画配置，并优先切换到已验证可用的终端模拟器。

若需要验证全局配置是否可解析，运行：

```bash
codex doctor --summary
```

如果只是需要复制最近一次完整回复，使用 Codex 内置复制：

```text
/copy
Ctrl+O
```

注意：`/copy` 和 `Ctrl+O` 复制的是最近一次已完成的 Codex 输出；如果当前 turn 仍在运行，通常不会复制正在生成中的未完成内容。

如果明确要求“Codex working 时也能用鼠标选择历史文字”，且关闭动画后仍不稳定，默认全屏 TUI 模式通常很难保证。此时用本次会话级别的 inline 模式启动，而不是先改全局配置：

```bash
codex --no-alt-screen
codex resume --no-alt-screen <session-name>
```

该模式会禁用本次 TUI 的 alternate screen，把内容保留在普通终端 scrollback 中；在终端已关闭输出自动滚动时，更符合“运行中仍可回看并选择文字”的需求。

如果终端设置已经正常，继续按 Codex TUI 层排查。部分 VTE/mate-terminal 类终端在 TUI 程序启用鼠标模式时，普通鼠标拖选可能会被应用捕获；先尝试按住 `Shift` 再用鼠标拖选。

如果需要回看并手动选择较长输出，在 Codex TUI 内使用：

```text
/raw
```

`/raw` 会切换 raw scrollback 模式，使终端选择和复制更接近原始输出。

不要在未确认终端滚动设置、TUI 鼠标选择行为和用户偏好前直接修改 Codex 的 `[tui] alternate_screen` 全局配置；不同 Codex 版本该配置可能是字符串枚举而不是布尔值，修改后必须用 Codex 自身的配置诊断确认可解析。

## 权限边界

`danger-full-access` 只表示 Codex 的文件系统沙箱不再限制普通用户可访问的路径；它不等于 root 权限，也不会绕过系统认证、Polkit、`pkexec`、`sudo`、磐石架构保护或维护模式要求。

涉及 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区、KSaf 策略等系统级修复时，仍必须先按主 skill 规则检查：

```bash
mm-cli -s
```

只有当前为维护模式时，才继续系统级修改。需要 root 的操作仍使用 `pkexec` 或 `sudo`，并在最终回复中说明执行过的权限动作。

## 常用检查

```bash
rg -n 'sandbox_mode|approval|approvals_reviewer|status_line|hide_full_access_warning|alternate_screen' "$HOME/.codex/config.toml"
```

如果用户说“默认不是 full access”或“换目录后权限不对”，优先检查 `$HOME/.codex/config.toml` 是否是用户级配置，而不是只检查当前目录的 `AGENTS.md`。

## 全局用户问题 skill 初始化

如果希望 Codex 在任意工作目录处理 KylinOS Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、磐石架构等问题时，都默认读取用户问题 skill，可在 `$HOME/.codex/AGENTS.md` 写入全局规则。示例：

```markdown
# 全局 Codex 规则

## Kylin Desktop V11 经验沉淀

- 处理当前桌面操作系统相关问题时，默认使用 `$HOME/kylinos-desktop-v11-skill/SKILL.md` 作为经验入口。
- 开始处理 Kylin Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、系统保护/磐石架构等问题前，先读取该 `SKILL.md`，再按其中的引用文档继续读取对应 `references/*.md`。
- 问题确认修复完成后，必须主动判断是否产生新的可复用诊断步骤、修复步骤、风险点或系统特性；有则立即更新到该 skill 合集的 `SKILL.md` 或 `references/` 下的对应文档，不等用户追问。
- 最终回复中应说明本次经验是否已记录；如果已记录，给出对应 skill 文档路径；如果没有记录，说明原因是没有新增可复用经验。
- 经验文档应使用中文，避免写入当前用户专属路径、用户名或一次性状态；需要出现用户目录时使用 `$HOME`、`<user>`、`<app-id>`、`<desktop-id>` 等通用占位符。
- 桌面系统经验优先沉淀为可复用流程，不要把临时日志、长篇命令输出、聊天过程或只适用于单次现场的细节写入 skill。
- 涉及系统路径、服务、设备节点、维护模式、KARE/Kaiming 容器路径、UKUI 设置后端等内容时，记录“先诊断、再修改、最后验证”的最小闭环。
- 执行系统级修复前，必须先检查维护模式：运行 `mm-cli -s`，确认当前是 maintain mode 后才能继续修改 `/usr`、`/etc`、`/opt`、系统包、系统服务或设备节点。
- 如果当前不是维护模式，不要继续系统级修复。应让用户执行 `sudo mm-cli -o`，或经用户授权后执行 `pkexec mm-cli -o`；随后明确提醒用户重启系统，重启后重新打开 Codex 再继续修复。
- 切换维护模式并重启前，只允许做诊断、读取状态、模拟安装/卸载等非破坏操作；不要执行实际安装、卸载、写系统路径或改系统服务。
```

`$HOME/.codex/AGENTS.md` 是用户级全局规则，换目录启动 Codex 也应生效；项目目录下的 `AGENTS.md` 只对该目录及其子目录工作区更合适。若两者都存在，桌面系统经验入口应保持一致，避免一个指向 `$HOME/kylinos-desktop-v11-skill/SKILL.md`，另一个指向过期路径。

初始化检查：

```bash
test -f "$HOME/.codex/config.toml" && rg -n 'sandbox_mode|status_line|hide_full_access_warning' "$HOME/.codex/config.toml"
test -f "$HOME/.codex/AGENTS.md" && rg -n 'kylinos-desktop-v11-skill|mm-cli -s|磐石架构' "$HOME/.codex/AGENTS.md"
test -f "$HOME/kylinos-desktop-v11-skill/SKILL.md" && sed -n '1,80p' "$HOME/kylinos-desktop-v11-skill/SKILL.md"
```
