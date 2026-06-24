# kylinos-v11-desktop-fix-skill

[English](README.en.md)

这是一个面向 KylinOS Desktop V11 的系统修复经验库，用来沉淀桌面系统已有能力异常、失效、报错、不能持久化、安装失败或系统服务损坏时的可复用修复流程。它不是可执行程序，也不绑定某个工具的内置目录；入口文件为 `$HOME/.os-fix-skill/SKILL.md`，详细内容按 `references/` 和 `knowledge/` 渐进展开。

内容覆盖 UKUI、KARE/Kaiming、Clash Verge TUN、应用安装、aTrust/UEM 安全客户端、开机自启动、全局搜索、托盘、输入法、系统服务、维护模式、磐石架构、指纹/图形硬件、分区挂载和桌面 AI 子系统残留等场景。

系统功能增强、本地客制化、默认行为调整和源码级功能新增由功能增强经验库维护。

## 先安装一个 AI 编程工具

如果还没有可用的 AI 编程工具，先安装 Codex、Claude Code 或 opencode 之一。下面命令面向 KylinOS Desktop V11 这类 Linux 桌面终端；更多安装方式见对应官方文档。

### Codex

官方文档：

- Codex CLI：https://developers.openai.com/codex/cli
- Codex 快速开始：https://developers.openai.com/codex/quickstart

推荐安装命令：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

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

如果系统策略不允许 `curl | sh` 或 `curl | bash`，打开上面的官方页面，按当前 Linux 桌面环境选择独立安装包、npm 或其他受信任的安装方式。

## 安装本经验库

```bash
cd "$HOME"
git clone https://github.com/Swordup-Z/kylinos-v11-desktop-fix-skill.git "$HOME/.os-fix-skill"
```

入口文件是：

```text
$HOME/.os-fix-skill/SKILL.md
```

常见工具的用户级规则文件位置：

```text
Codex:       $HOME/.codex/AGENTS.md
Claude Code: $HOME/.claude/CLAUDE.md
opencode:    $HOME/.config/opencode/AGENTS.md
```

把这些规则文件接入本经验库后，KylinOS Desktop V11 桌面系统修复问题可从 `$HOME/.os-fix-skill/SKILL.md` 进入，再按其中的 `references/system-repair/` 路由继续查阅。功能增强、本地客制化和默认行为调整由 `$HOME/.os-enhance-skill` 维护。

系统维护使用固定会话名，例如 `os-fix`。之后遇到系统问题时，恢复同一个会话继续处理：

```bash
codex resume os-fix
claude resume os-fix
opencode resume os-fix
```

## 整体架构

本仓库面向系统修复场景：系统已有能力异常、失效、报错、不能持久化。例如 TUN 模式失败、开机自启动不生效、托盘隐藏状态丢失、指纹设备断开、系统服务异常。

修复内容按场景分类：

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
│   └── system-repair/
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
│   └── system-repair/
├── scripts/
│   └── cleanup-kylin-ai.sh
├── README.md
└── README.en.md
```

`references/` 是场景入口和策略路由层，包含适用场景、简短说明、知识入口和最小诊断。`knowledge/system-repair/<scenario>/README.md` 是场景内索引，负责把问题继续路由到具体章节。具体 `<topic>.md` 保存背景、诊断、修复步骤、验证、回滚和清理规则。通过源码修改实现的可复用修复还会在同场景 `patches/<fix-id>/` 下保存 patch 集和 `PATCHSET.md` 元数据。

固定加载链路：

```text
修复需求
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

给 UKUI 全局搜索增加自定义命令面板、接入共享经验库等增强任务，可从 `$HOME/.os-enhance-skill/SKILL.md` 进入。

## 当前覆盖范围

- 维护模式、磐石架构、系统级修改边界。
- 应用安装、AppImage、第三方 apt 源、KARE/Kaiming 隔离。
- aTrust/UEM 安全客户端、虚拟网络组件和第三方内核模块残留。
- Clash Verge TUN、`/dev/net/tun`、代理服务和代理核心路径。
- UKUI 开机自启动、全局搜索异常、快捷键、系统托盘、输入法、面板/任务栏、打开方式文件选择器。
- 桌面 AI 组件、AI 子系统和残留清理。
- 指纹/生物识别、图形频率、硬件稳定性。
- 根分区、DATA 分区、`/home` 挂载、overlay、Kaiming/KARE 和 ostree 空间占用判断。

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

空间清理、Kaiming/KARE 应用层治理、ostree 占用审计这类任务适合由独立应用承载。若本机存在独立开发工作区，可从对应项目的规则文件进入：

```text
$HOME/desktop-develop/kylin-space-guard/AGENTS.md
```

本仓库记录系统诊断、安全边界和可复用修复经验；具体 UI、构建、验证、依赖选择和项目实现规则应维护在独立项目内。工具类项目仍必须遵守系统安全边界：不得自动删除 ostree deployment、EFI、GRUB、loader entries、`/etc/fstab` 或分区表。

如果使用本机的开发工作区，入口通常是：

```text
$HOME/desktop-develop/AGENTS.md
```

该文件只做项目路由；具体项目继续读取各自目录下的 `AGENTS.md`。

## License

当前仓库使用 MIT License，见 [LICENSE](LICENSE)。
