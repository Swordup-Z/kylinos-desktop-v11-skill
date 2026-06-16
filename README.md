# kylinos-desktop-v11-skill

[English](README.en.md)

这是一个面向 KylinOS Desktop V11 的系统经验库，用来沉淀桌面系统问题修复和系统功能增强的可复用流程。它不是可执行程序，而是一组给人和 AI 工具共同使用的结构化知识：人按目录查找经验，AI 工具从 `SKILL.md` 开始按需渐进式读取。

当前内容覆盖 UKUI、KARE/Kaiming、Clash Verge TUN、应用安装、开机自启动、全局搜索、托盘、输入法、系统服务、维护模式、磐石架构、指纹/图形硬件、分区挂载、本地源码客制化和 AI 工具配置等场景。

## 安装方式

### 方式一：让 AI 工具安装

把下面这段话发给 Codex、Claude Code、opencode 等工具即可：

```text
请安装这个 KylinOS Desktop V11 系统经验库：

https://github.com/Swordup-Z/kylinos-desktop-v11-skill

要求：
1. 克隆到 $HOME/kylinos-desktop-v11-skill。
2. 根据当前工具类型，把全局提示词配置到用户级文件，例如：
   - Codex: $HOME/.codex/AGENTS.md
   - Claude Code: $HOME/.claude/CLAUDE.md
   - opencode: $HOME/.config/opencode/AGENTS.md
3. 当用户处理 KylinOS Desktop V11、UKUI、KARE/Kaiming、Clash Verge、TUN、维护模式、磐石架构、系统服务、分区挂载、AI 子系统等桌面系统问题时，先读取 $HOME/kylinos-desktop-v11-skill/SKILL.md，再按里面的 references 路由继续读取。
4. 配置完成后告诉我入口文件路径和后续如何使用。
```

### 方式二：手动安装

```bash
cd "$HOME"
git clone https://github.com/Swordup-Z/kylinos-desktop-v11-skill.git
```

入口文件：

```text
$HOME/kylinos-desktop-v11-skill/SKILL.md
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
kylinos-desktop-v11-skill/
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
- Clash Verge TUN、`/dev/net/tun`、代理服务和代理核心路径。
- UKUI 开机自启动、全局搜索异常、快捷键、系统托盘、输入法、面板/任务栏。
- 桌面 AI 组件、AI 子系统和残留清理。
- 指纹/生物识别、图形频率、硬件稳定性。
- 根分区、DATA 分区、`/home` 挂载、overlay、空间占用。

### 系统功能增强

- UKUI 全局搜索搜索引擎增强。
- UKUI 全局搜索自定义命令 provider 和图形化命令配置。
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

## License

当前仓库使用 MIT License，见 [LICENSE](LICENSE)。
