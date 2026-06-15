# kylinos-desktop-v11-skill

[English](README.en.md)

用于沉淀和复用 KylinOS Desktop V11 桌面系统问题的诊断、修复与验证经验，覆盖应用安装与包管理、UKUI、KARE/Kaiming、Clash Verge TUN、开机自启动、维护模式、磐石架构、系统服务、图形/频率、托盘、全局搜索、需要源码重编译的系统组件修复评估、AI 子系统、分区挂载、overlay、系统噪声清理和 AI 工具全局提示词等场景。

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
3. 在全局提示词中加入规则：处理 KylinOS Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、磐石架构、系统保护、分区、挂载、overlay、AI 子系统等桌面系统问题时，先读取 $HOME/kylinos-desktop-v11-skill/SKILL.md，再按其中“参考文档”选择性读取 references/*.md；如果 reference 指向 knowledge/ 下的具体知识章节，再按需读取对应 knowledge；如果没有命中专门 reference，至少读取 references/system-maintenance.md；如果当前任务不是桌面系统问题，不要加载该 skill。
4. 系统级修复前必须先运行 mm-cli -s 检查维护模式；非维护模式只允许诊断，不要实际修改 /usr、/etc、/opt、系统包、系统服务、设备节点、分区或 KSaf 策略。
5. 问题确认修复后，如果产生新的可复用经验，应更新到该 skill 的 SKILL.md、references/*.md 路由或 knowledge/ 下的具体章节；如果该问题原本未被当前 skill 覆盖，应新增合适的 reference 作为分类入口，并把详细经验沉淀到 knowledge/。
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
处理 KylinOS Desktop V11、UKUI、KARE、Kaiming、Clash Verge、系统服务、开机自启动、TUN、维护模式、磐石架构、系统保护、分区、挂载、overlay、AI 子系统等桌面操作系统问题时，先读取 `$HOME/kylinos-desktop-v11-skill/SKILL.md`，再按其中“参考文档”选择性读取对应 `references/*.md`。如果 reference 指向 `knowledge/` 下的具体知识章节，再按需读取对应 knowledge。如果没有命中专门 reference，至少读取 `references/system-maintenance.md`。如果当前任务不是桌面系统问题，不要加载该 skill；不要一次性预加载全部 reference 或 knowledge。

系统级修复前必须先运行 `mm-cli -s` 检查维护模式。只有确认当前是 maintain mode，才允许修改 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区、KSaf 策略等。

问题确认修复完成后，如果产生新的可复用诊断步骤、修复步骤、风险点或系统特性，应更新到 `$HOME/kylinos-desktop-v11-skill/SKILL.md`、对应 `references/*.md` 路由或 `knowledge/` 下的具体章节。

如果实际解决的是当前 skill 尚未覆盖的 KylinOS Desktop V11 系统问题，应新增合适的 `references/*.md` 作为分类入口，并把详细经验沉淀到 `knowledge/` 下的具体章节；再在 `SKILL.md` 的“参考文档”中补充入口。
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

AI 工具应先读取 `SKILL.md`，再按需读取相关 `references/*.md`；如果 reference 指向 `knowledge/` 章节，再继续读取对应知识文件，然后按“诊断 -> 修复 -> 验证 -> 记录经验”的流程处理。

## 目录结构与路由路径

这个仓库按渐进式披露组织，避免 AI 工具一开始就加载过多上下文。

```text
kylinos-desktop-v11-skill/
├── SKILL.md                  # 总入口：判断问题大类和选择最小 reference
├── references/               # 场景分类和路由入口，类似词典目录
│   ├── system-maintenance.md  # 通用维护模式、安全边界和最小闭环
│   ├── ukui-search.md         # UKUI 全局搜索分类入口
│   └── ...
├── knowledge/                # 具体问题处理章节
│   ├── README.md             # knowledge 与 references 的分工说明
│   ├── system/               # 系统维护、安全边界、系统噪声
│   ├── applications/         # 应用安装、KARE 边界
│   ├── ukui/                 # UKUI 自启动、搜索、托盘、服务
│   ├── network/              # Clash Verge / TUN
│   ├── hardware/             # 指纹、图形、频率
│   ├── storage/              # 分区、挂载、overlay
│   ├── agent-tools/          # Codex/Claude/opencode 全局提示词
│   └── source-rebuild/       # 源码重编译通用流程和具体案例
├── README.md                 # 中文说明
└── README.en.md              # 英文说明
```

推荐加载路径：

```text
用户问题
  -> SKILL.md
  -> references/<最小匹配场景>.md
  -> knowledge/<分类>/<具体章节>.md（只有 reference 指向或问题需要深度处理时才读取）
```

例如处理“UKUI 全局搜索默认搜索引擎写死，需要添加 Bing/Google”：

```text
SKILL.md
  -> references/ukui-search.md
  -> references/source-rebuild.md
  -> knowledge/source-rebuild/README.md
  -> knowledge/source-rebuild/ukui-search-web-engine.md
```

新增经验时也按这个结构落位：`references/` 只放分类入口、最小诊断和指向关系；详细背景、源码定位、修复步骤、验证、回滚和清理规则写入 `knowledge/` 下的具体章节。

### References 与 Knowledge 路由

README 同时介绍 `references/` 和 `knowledge/`：前者是入口和索引，后者是解决思路和步骤。常用路由如下：

| 场景 | Reference 入口 | Knowledge 章节 |
| --- | --- | --- |
| 通用系统维护、维护模式、磐石架构边界 | [`references/system-maintenance.md`](references/system-maintenance.md) | [`knowledge/system/system-maintenance.md`](knowledge/system/system-maintenance.md) |
| 系统体检噪声清理 | [`references/system-health-noise.md`](references/system-health-noise.md) | [`knowledge/system/system-health-noise.md`](knowledge/system/system-health-noise.md) |
| 应用安装、AppImage、第三方 apt 源 | [`references/application-installation.md`](references/application-installation.md) | [`knowledge/applications/application-installation.md`](knowledge/applications/application-installation.md) |
| KARE 与宿主机边界 | [`references/kare-namespace.md`](references/kare-namespace.md) | [`knowledge/applications/kare-namespace.md`](knowledge/applications/kare-namespace.md) |
| Clash Verge / TUN | [`references/clash-verge-tun.md`](references/clash-verge-tun.md) | [`knowledge/network/clash-verge-tun.md`](knowledge/network/clash-verge-tun.md) |
| UKUI 开机自启动 | [`references/ukui-autostart.md`](references/ukui-autostart.md) | [`knowledge/ukui/autostart.md`](knowledge/ukui/autostart.md) |
| UKUI 全局快捷键 | [`references/ukui-keybindings.md`](references/ukui-keybindings.md) | [`knowledge/ukui/keybindings.md`](knowledge/ukui/keybindings.md) |
| UKUI 全局搜索 | [`references/ukui-search.md`](references/ukui-search.md) | [`knowledge/ukui/search.md`](knowledge/ukui/search.md) |
| 源码重编译类修复 | [`references/source-rebuild.md`](references/source-rebuild.md) | [`knowledge/source-rebuild/README.md`](knowledge/source-rebuild/README.md)、[`knowledge/source-rebuild/ukui-search-web-engine.md`](knowledge/source-rebuild/ukui-search-web-engine.md) |
| UKUI 右侧托盘 | [`references/ukui-system-tray.md`](references/ukui-system-tray.md) | [`knowledge/ukui/system-tray.md`](knowledge/ukui/system-tray.md) |
| UKUI 系统服务管理器 | [`references/ukui-system-service-manager.md`](references/ukui-system-service-manager.md) | [`knowledge/ukui/system-service-manager.md`](knowledge/ukui/system-service-manager.md) |
| AI 子系统清理 | [`references/kylin-ai-subsystem.md`](references/kylin-ai-subsystem.md) | [`knowledge/ukui/kylin-ai-subsystem.md`](knowledge/ukui/kylin-ai-subsystem.md) |
| 指纹/生物识别 | [`references/biometric-fingerprint.md`](references/biometric-fingerprint.md) | [`knowledge/hardware/biometric-fingerprint.md`](knowledge/hardware/biometric-fingerprint.md) |
| 图形、频率与硬件稳定性 | [`references/graphics-frequency.md`](references/graphics-frequency.md) | [`knowledge/hardware/graphics-frequency.md`](knowledge/hardware/graphics-frequency.md) |
| 分区、挂载、overlay | [`references/storage-layout.md`](references/storage-layout.md) | [`knowledge/storage/layout.md`](knowledge/storage/layout.md) |
| Codex 配置 | [`references/codex-config.md`](references/codex-config.md) | [`knowledge/agent-tools/codex-config.md`](knowledge/agent-tools/codex-config.md) |
| 多 AI 工具全局提示词 | [`references/agent-global-prompts.md`](references/agent-global-prompts.md) | [`knowledge/agent-tools/global-prompts.md`](knowledge/agent-tools/global-prompts.md) |

## 核心基础要求

使用这个 skill 处理系统问题时，AI 工具必须遵守以下基础要求：

- 只要任务涉及 KylinOS Desktop V11 桌面系统维护场景，就先读取 [`SKILL.md`](SKILL.md)，再根据其中“参考文档”按需读取具体 `references/*.md`；不要一次性预加载所有 reference。
- `references/` 作为场景分类和路由入口，`knowledge/` 作为具体问题处理章节；reference 指向 knowledge 时才继续读取对应章节。
- 如果没有命中专门 reference，至少读取通用系统维护文档 [`references/system-maintenance.md`](references/system-maintenance.md)。
- 如果问题需要重新编译系统源码包、替换系统共享库、评估 ABI/SONAME/依赖/RPATH 风险，或保存本地客制化源码、构建目录和回滚包索引，先读取源码重编译分类入口 [`references/source-rebuild.md`](references/source-rebuild.md)，再按它指向的 `knowledge/source-rebuild/` 章节继续处理。
- 普通代码开发、文档编辑、Git 操作或其他无关任务不要加载该 skill。
- 按“诊断 -> 修复 -> 验证 -> 沉淀经验”的闭环处理问题。
- 系统问题默认以持久化修复为目标；临时止血后，还要确认重启、重新登录、服务重拉起或应用重启后是否仍然有效。
- 不要把恢复官方包、删除本地定制、回滚源码修改或重装组件作为默认第一步；应先建立日志、调用链、包校验和复现证据。只有证据指向用户定制，或用户确认做 A/B 验证且已有备份回滚路径时，才临时恢复官方版本。
- workaround、watchdog、定时重启、自动重拉起等兜底方案只能作为临时恢复手段；应优先定位和修复 root cause。
- 执行系统级修复前必须运行 `mm-cli -s` 检查维护模式；非维护模式只允许诊断、读取状态、模拟安装/卸载等非破坏操作。
- 如果当前不是维护模式，应先进入维护模式并要求用户重启；修复完成后，应退出维护模式并要求用户再次重启回到 normal mode。
- 不要删除、移动或覆盖用户已有的可执行文件、配置文件、订阅文件、代理核心、systemd 单元或用户数据，除非用户明确要求且已验证影响。
- 问题确认修复后，如果产生新的可复用诊断步骤、修复步骤、风险点或系统特性，应更新到 `SKILL.md`、对应 `references/*.md` 路由或 `knowledge/` 下的具体章节。
- 如果实际解决的是当前 skill 尚未覆盖的 KylinOS Desktop V11 系统问题，应新增合适的 `references/*.md` 作为分类入口，并把详细经验沉淀到 `knowledge/` 下的具体章节；再在 `SKILL.md` 的“参考文档”中补充入口。
- 在本仓库执行 `git commit` 前，必须检查 `README.md` 和 `README.en.md` 是否需要同步；如果变更影响安装方式、核心基础要求、支持的问题类型、参考文档入口、安全边界、全局提示词或公开使用流程，应在同次提交中更新 README。
- 执行任何 `git commit` 时，提交作者、提交正文和提交 trailer 不得包含 AI 相关署名或协作生成信息。

## 能处理的问题

当前 skill 已沉淀过以下问题类型。`references/` 是分类入口，`knowledge/` 是具体知识章节；AI 工具应按需读取，不要一次性加载全部文档。

### 系统维护与安全边界

- 维护模式检查、进入/退出维护模式、`mm-cli -s` / `mm-cli -o` / `mm-cli -c -a` 使用边界：[`references/system-maintenance.md`](references/system-maintenance.md)
- 磐石架构下命令行安装、写 `/usr`、`/etc`、`/opt`、systemd、设备节点前的安全流程：[`references/system-maintenance.md`](references/system-maintenance.md)
- 未覆盖的新系统问题如何按“诊断 -> 修复 -> 验证 -> 经验沉淀”闭环处理：[`references/system-maintenance.md`](references/system-maintenance.md)

### 系统体检与噪声清理

- 全盘体检后的系统噪声清理，包括 `motd-news.service`、缺失 `pam_gnome_keyring.so`、rsyslog 旧式 `$IMJournalStateFile` 指令：[`references/system-health-noise.md`](references/system-health-noise.md)

### 应用安装与包管理

- 宿主机命令行安装、KARE 环境误装判断、应用入口是否来自 KARE 或宿主机：[`references/application-installation.md`](references/application-installation.md)
- AppImage 用户级安装、ARM64/x86-64 架构检查、桌面入口、用户级图标主题缓存和 UKUI 开始菜单图标异常：[`references/application-installation.md`](references/application-installation.md)
- AppImage 缺少 `libfuse.so.2`、`libfuse2` 安装与验证：[`references/application-installation.md`](references/application-installation.md)
- 第三方 apt 源残留、公钥缺失、`NO_PUBKEY`、用户明确删除应用后的源配置清理：[`references/application-installation.md`](references/application-installation.md)

### KARE 与宿主机边界

- KARE namespace、应用内 hostname 显示 `kare`、宿主机 hostname 验证和 KARE base 环境风险：[`references/kare-namespace.md`](references/kare-namespace.md)
- KARE 桌面入口覆盖、开始菜单固定项仍指向 KARE、宿主机原生入口验证：[`references/kare-namespace.md`](references/kare-namespace.md)
- 从 KARE 环境误启动 UKUI 面板后的恢复与 namespace 验证：[`references/kare-namespace.md`](references/kare-namespace.md)

### 网络代理与 Clash Verge

- Clash Verge Rev TUN 模式安装失败、`/dev/net/tun` 缺失、TUN 设备持久化：[`references/clash-verge-tun.md`](references/clash-verge-tun.md)
- `clash-verge-service` 安装、启动、状态验证和权限问题：[`references/clash-verge-tun.md`](references/clash-verge-tun.md)
- `verge-mihomo` 路径不一致、核心丢失、KARE shadow/upper 路径恢复，以及代理组消失后的排查：[`references/clash-verge-tun.md`](references/clash-verge-tun.md)

### UKUI 桌面与系统服务

- UKUI 开机自启动不生效、设置界面不显示新增启动项、原始 `.desktop` 修复、图标解析、`sort-app-list` / `statusMap` 异常：[`references/ukui-autostart.md`](references/ukui-autostart.md)
- UKUI 全局快捷键冲突、设置界面提示快捷键被系统占用、全局搜索快捷键、`Alt+Space` 与窗口菜单冲突：[`references/ukui-keybindings.md`](references/ukui-keybindings.md)
- UKUI 全局搜索结果来源、应用商店未安装应用结果、软件商店搜索 D-Bus 插件屏蔽与回滚：[`references/ukui-search.md`](references/ukui-search.md)
- UKUI 全局搜索默认互联网搜索引擎写死、需要通过源码级修改添加 Bing/Google 或应用商店结果开关等选项时的源码匹配、构建、ABI 风险评估和本地客制化源码索引：[`references/source-rebuild.md`](references/source-rebuild.md)
- UKUI 右侧托盘小图标顺序和隐藏区不持久、`systemTray.json`、`orderedItems`、`separateIndex`：[`references/ukui-system-tray.md`](references/ukui-system-tray.md)
- `ukui-system-service-manager.service` 反复 timeout、`QDBusError("", "")`、`org.ukui.serviceManager` 被孤儿进程占用、启动顺序竞态导致的面板/任务栏异常、D-Bus activation 持久化修复：[`references/ukui-system-service-manager.md`](references/ukui-system-service-manager.md)
- 任务栏/托盘 AI 助手、AI 子系统、Kaiming AI 助手卸载边界和残留清理：[`references/kylin-ai-subsystem.md`](references/kylin-ai-subsystem.md)

### 指纹与生物识别

- `GW_Fingerprint_PA` 指纹驱动恢复、Pixelauth T350P 包安装、`biometric-authentication.service` 验证、驱动已注册但设备未发现的诊断：[`references/biometric-fingerprint.md`](references/biometric-fingerprint.md)

### 图形、频率与硬件相关稳定性

- 图形驱动、GPU/显示频率、`devfreq` 调频失败、`failed to set <driver> frequency`：[`references/graphics-frequency.md`](references/graphics-frequency.md)
- Phytium FTG / `PHYT0048:00` 等硬件强相关图形稳定性问题的诊断和 UKUI 电源管理策略处理：[`references/graphics-frequency.md`](references/graphics-frequency.md)
- 无 NVIDIA 硬件但系统反复探测 NVIDIA、`NVRM: No NVIDIA GPU found`、NVIDIA suspend/resume hook 处理边界：[`references/graphics-frequency.md`](references/graphics-frequency.md)

### 存储、分区与 overlay

- 根分区、DATA 分区、`/home` 实际挂载位置、空间占用判断：[`references/storage-layout.md`](references/storage-layout.md)
- 磐石架构、ostree、overlay、KARE 合并视图的判断方式：[`references/storage-layout.md`](references/storage-layout.md)
- 根分区扩容、backup 分区缩小、DATA 分区调整前的诊断边界和风险判断：[`references/storage-layout.md`](references/storage-layout.md)

### AI 工具配置与经验复用

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

## 附录：安装 AI 编程工具

本 skill 可以被 Codex、Claude Code、opencode 等 AI 编程工具读取。以下只记录常用官方安装入口；安装前建议以官方文档为准。

### Codex CLI

官方文档：

```text
https://developers.openai.com/codex/cli
```

macOS/Linux 常用安装方式：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | sh
```

非交互安装：

```bash
curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_NON_INTERACTIVE=1 sh
```

也可以使用 npm：

```bash
npm install -g @openai/codex
```

验证和启动：

```bash
codex --version
codex
```

### Claude Code

官方文档：

```text
https://code.claude.com/docs/en/setup
```

macOS/Linux/WSL 推荐安装方式：

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

也可以使用 npm，要求 Node.js 18 或更高版本：

```bash
npm install -g @anthropic-ai/claude-code
```

验证和启动：

```bash
claude --version
claude doctor
claude
```

注意：Claude Code 官方文档提示不要使用 `sudo npm install -g`，否则可能带来权限和安全问题。若使用 apt/dnf/apk 等系统包方式安装，在 KylinOS Desktop V11 上应先遵守维护模式规则。

### opencode

官方文档：

```text
https://opencode.ai/docs/
```

常用安装方式：

```bash
curl -fsSL https://opencode.ai/install | bash
```

也可以使用 npm：

```bash
npm install -g opencode-ai
```

验证和启动：

```bash
opencode --version
opencode
```

### KylinOS Desktop V11 注意事项

- 如果安装方式只写入用户目录，通常不需要维护模式。
- 如果安装方式会写 `/usr`、`/etc`、系统包源、系统服务或通过 apt/dnf/apk 安装，应先执行 `mm-cli -s` 确认维护模式。
- 如果当前不是维护模式，应先进入维护模式并重启，再继续系统级安装。
- 安装完成后，把本仓库 README 中的全局提示词片段加入对应工具的用户级全局提示词文件。

## 许可证

MIT
