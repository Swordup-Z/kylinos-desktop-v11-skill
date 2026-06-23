# kylinos-v11-desktop-fix-skill

[English](README.en.md)

这是一个面向 KylinOS Desktop V11 的系统经验库，用来沉淀桌面系统问题修复和系统功能增强的可复用流程。它不是可执行程序，也不绑定某个 AI 工具的内置 skill 目录，而是一组给人和多个 AI 工具共同使用的结构化知识：人按目录查找经验，AI 工具从 `$HOME/.os-fix-skill/SKILL.md` 开始按需渐进式读取。

当前内容覆盖 UKUI、KARE/Kaiming、Clash Verge TUN、应用安装、aTrust/UEM 安全客户端、开机自启动、全局搜索、托盘、输入法、系统服务、维护模式、磐石架构、指纹/图形硬件、分区挂载、本地源码客制化和 AI 工具配置等场景。

## 先安装一个 AI 编程工具

如果还没有可用的 AI 编程工具，先安装 Codex、Claude Code 或 opencode 之一。下面命令优先覆盖常见 Linux/macOS 终端和 Windows PowerShell；其他系统或更多安装方式见对应官方文档。

### Codex

官方文档：

- Codex CLI：https://developers.openai.com/codex/cli
- Codex 快速开始：https://developers.openai.com/codex/quickstart

Linux/macOS 推荐安装命令：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

Windows 推荐在 PowerShell 中安装：

```powershell
powershell -ExecutionPolicy ByPass -c "irm https://chatgpt.com/codex/install.ps1 | iex"
```

无人值守安装：

```powershell
$env:CODEX_NON_INTERACTIVE=1; irm https://chatgpt.com/codex/install.ps1 | iex
```

Windows 可以在 PowerShell 中原生运行 Codex CLI；如果需要更接近 Linux 的原生开发环境，可以在 WSL2 中按 Linux 方式安装和使用。

安装后启动：

```bash
codex
```

### Claude Code

官方文档：

- Claude Code 快速开始：https://docs.anthropic.com/en/docs/claude-code/quickstart
- Claude Code 设置：https://docs.anthropic.com/en/docs/claude-code/setup

推荐安装命令：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

安装后启动：

```bash
claude
```

### opencode

官方文档：

- opencode 文档：https://opencode.ai/docs/
- opencode 下载：https://opencode.ai/download

推荐安装命令：

```bash
curl -fsSL https://opencode.ai/install | bash
```

安装后启动：

```bash
opencode
```

如果系统策略不允许 `curl | sh` 或 `curl | bash`，打开上面的官方页面，按当前系统选择独立安装包、Homebrew、npm 或其他受信任的安装方式。

## 安装本经验库

### 方式一：让 AI 工具安装

把下面这段话发给 Codex、Claude Code、opencode 等工具即可：

```text
请安装这个 KylinOS Desktop V11 系统经验库：

https://github.com/Swordup-Z/kylinos-v11-desktop-fix-skill

要求：
1. 克隆到 $HOME/.os-fix-skill。
2. 根据当前工具类型，把全局提示词配置到用户级文件，例如：
   - Codex: $HOME/.codex/AGENTS.md
   - Claude Code: $HOME/.claude/CLAUDE.md
   - opencode: $HOME/.config/opencode/AGENTS.md
3. 当用户处理 KylinOS Desktop V11、UKUI、KARE/Kaiming、Clash Verge、TUN、维护模式、磐石架构、系统服务、分区挂载、AI 子系统等桌面系统问题时，先读取 $HOME/.os-fix-skill/SKILL.md，再按里面的 references 路由继续读取。
4. 当用户在 $HOME/desktop-develop 或 /data/usershare/desktop-develop 下进行独立工具/应用开发时，先读取对应目录的 AGENTS.md，并按工作区或项目级提示词路由；不要把项目实现要求写入本 skill。
5. 配置完成后告诉我入口文件路径和后续如何使用。
```

### 方式二：手动安装

```bash
cd "$HOME"
git clone https://github.com/Swordup-Z/kylinos-v11-desktop-fix-skill.git "$HOME/.os-fix-skill"
```

入口文件：

```text
$HOME/.os-fix-skill/SKILL.md
```

常见 AI 工具的用户级提示词位置：

```text
Codex:       $HOME/.codex/AGENTS.md
Claude Code: $HOME/.claude/CLAUDE.md
opencode:    $HOME/.config/opencode/AGENTS.md
```

系统维护使用固定会话名，例如 `os-fix`。之后遇到系统问题时，恢复同一个会话继续处理：

```bash
codex resume os-fix
claude resume os-fix
opencode resume os-fix
```

## 整体架构

当前 skill 分为两大类：

- **系统问题修复**：系统已有能力异常、失效、报错、不能持久化。例如 TUN 模式失败、开机自启动不生效、托盘隐藏状态丢失、指纹设备断开、系统服务异常。
- **系统功能增强**：系统原本能工作，但需要新增能力、改变默认行为或做本地客制化。例如给 UKUI 全局搜索增加 Bing/Google、自定义命令面板、保存本地源码 patch、配置 AI 工具全局提示词。

两大类使用相同场景分类，便于按“任务类型 + 场景”定位：

```text
system
applications
ukui
network
hardware
storage
agent-tools
source-rebuild
```

## 目录结构

```text
$HOME/.os-fix-skill/
├── SKILL.md
├── references/
│   ├── README.md
│   ├── system-repair/
│   │   ├── README.md
│   │   ├── system.md
│   │   ├── applications.md
│   │   ├── ukui.md
│   │   ├── network.md
│   │   ├── hardware.md
│   │   ├── storage.md
│   │   ├── agent-tools.md
│   │   └── source-rebuild.md
│   └── feature-enhancement/
│       ├── README.md
│       ├── system.md
│       ├── applications.md
│       ├── ukui.md
│       ├── network.md
│       ├── hardware.md
│       ├── storage.md
│       ├── agent-tools.md
│       └── source-rebuild.md
├── knowledge/
│   ├── README.md
│   ├── system-repair/
│   └── feature-enhancement/
├── scripts/
│   └── cleanup-kylin-ai.sh
├── README.md
└── README.en.md
```

`references/` 是场景入口和策略路由层，包含适用场景、简短说明、知识入口和最小诊断。`knowledge/<type>/<scenario>/README.md` 是场景内索引，负责把问题继续路由到具体章节。具体 `<topic>.md` 保存背景、诊断、修复或增强步骤、验证、回滚和清理规则。通过源码修改实现的可复用功能还会在同场景 `patches/<feature-id>/` 下保存 patch 集和 `PATCHSET.md` 元数据。

固定加载链路：

```text
需求类型
-> 实际场景 reference
-> 场景 knowledge README
-> 具体细分 knowledge
```

## 路由示例

Clash Verge TUN 模式失败：

```text
SKILL.md
-> references/system-repair/network.md
-> knowledge/system-repair/network/README.md
-> knowledge/system-repair/network/proxy-tun.md
```

UKUI 全局搜索显示软件商店未安装应用：

```text
SKILL.md
-> references/system-repair/ukui.md
-> knowledge/system-repair/ukui/README.md
-> knowledge/system-repair/ukui/search.md
```

给 UKUI 全局搜索增加自定义命令面板：

```text
SKILL.md
-> references/feature-enhancement/ukui.md
-> knowledge/feature-enhancement/ukui/README.md
-> knowledge/feature-enhancement/ukui/search-command-provider.md
```

配置 Codex/Claude/opencode 自动加载本经验库：

```text
SKILL.md
-> references/feature-enhancement/agent-tools.md
-> knowledge/feature-enhancement/agent-tools/README.md
-> knowledge/feature-enhancement/agent-tools/global-prompts.md
```

## 当前覆盖范围

### 系统问题修复

- 维护模式、磐石架构、系统级修改边界。
- 应用安装、AppImage、第三方 apt 源、KARE/Kaiming 隔离。
- aTrust/UEM 安全客户端、虚拟网络组件和第三方内核模块残留。
- Clash Verge TUN、`/dev/net/tun`、代理服务和代理核心路径。
- UKUI 开机自启动、全局搜索异常、快捷键、系统托盘、输入法、面板/任务栏、打开方式文件选择器。
- 桌面 AI 组件、AI 子系统和残留清理。
- 指纹/生物识别、图形频率、硬件稳定性。
- 根分区、DATA 分区、`/home` 挂载、overlay、Kaiming/KARE 和 ostree 空间占用判断。

### 系统功能增强

- UKUI 全局搜索搜索引擎增强。
- UKUI 全局搜索自定义命令 provider 和图形化命令配置。
- UKUI 托盘输入法状态角标等桌面交互增强。
- 本地源码客制化工作区、commit、patch、构建产物清理策略。
- 可复用源码 patch 集、上游仓库、基线节点和冲突迁移策略。
- AI 工具全局提示词、权限配置和多工具加载规则。
- DATA 分区用于本地源码和构建工作的目录策略。

## 安全边界

KylinOS Desktop V11 上的系统级修改通常需要维护模式。涉及 `/usr`、`/etc`、`/opt`、系统包、systemd、设备节点、分区、KSaf 或系统服务时，应先确认维护模式：

```bash
mm-cli -s
```

进入维护模式：

```bash
sudo mm-cli -o
```

退出维护模式并保存：

```bash
sudo mm-cli -c -a
```

切换维护模式后通常需要重启。具体操作流程以 `SKILL.md` 和对应 reference/knowledge 章节为准。

## 独立工具

空间清理、Kaiming/KARE 应用层治理、ostree 占用审计这类任务建议使用独立应用承载，而不是把大段脚本或项目开发要求直接塞进 knowledge。若本机存在独立开发工作区，优先从项目目录读取项目级提示词：

```text
$HOME/desktop-develop/kylin-space-guard/AGENTS.md
```

本 skill 只保留系统诊断、安全边界和可复用修复经验；具体 UI、构建、验证、依赖选择和项目实现规则应维护在独立项目内。工具类项目仍必须遵守本 skill 的系统安全边界：不得自动删除 ostree deployment、EFI、GRUB、loader entries、`/etc/fstab` 或分区表。

如果使用本机的开发工作区，入口通常是：

```text
$HOME/desktop-develop/AGENTS.md
```

该文件只做项目路由；具体项目继续读取各自目录下的 `AGENTS.md`。

## License

当前仓库使用 MIT License，见 [LICENSE](LICENSE)。
