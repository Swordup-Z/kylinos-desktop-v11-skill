---
name: kylinos-desktop-v11-skill
description: 处理 KylinOS Desktop V11 桌面系统上的应用安装与兼容、系统服务、网络代理、KARE 打包应用、UKUI 桌面环境和常见系统集成问题。适用于系统级修复、维护模式、磐石架构、AppImage/libfuse、第三方 apt 源、Clash Verge Rev TUN 模式安装失败、/dev/net/tun 缺失、clash-verge-service 安装失败、KARE 应用路径异常、代理核心 verge-mihomo 丢失或路径不一致、UKUI 开机自启动项不生效或设置界面不显示、UKUI 全局搜索结果来源、需要重新编译系统源码包的修复评估、指纹/生物识别驱动恢复、图形驱动/devfreq 调频异常等麒麟桌面 V11 维护场景。
---

# KylinOS Desktop V11

这是 KylinOS Desktop V11 桌面环境问题的技能合集。只要用户问题属于当前桌面操作系统维护范围，就先读取本入口；再先判断任务类型是“系统问题修复”还是“系统功能增强”，随后按相同场景分类读取对应 reference。如果没有命中专门 reference，系统问题修复至少读取 `references/system-repair/system.md`，系统功能增强至少读取 `references/feature-enhancement/system.md`。

## 使用原则

- 只要用户问题明确属于 KylinOS Desktop V11 桌面系统维护范围，就应使用本 skill；普通代码开发、文档编辑、Git 操作或与桌面系统无关的问题不应加载本 skill。
- 如果问题未命中某个专门 reference，系统问题修复读取 [references/system-repair/system.md](references/system-repair/system.md)，系统功能增强读取 [references/feature-enhancement/system.md](references/feature-enhancement/system.md)，再继续诊断。
- 如果当前本地 skill 已读取但没有覆盖用户的系统问题，在自行探索修复前，先尽力同步上游 GitHub 仓库，查看是否已有新增经验。同步前确认 `$HOME/kylinos-desktop-v11-skill` 是 git 仓库且工作树无本地改动；只使用 `git fetch`、`git status -sb`、`git pull --ff-only` 这类非破坏流程。若本地有未提交改动、分支分叉、网络不可用或 fast-forward 失败，不要强制覆盖，也不要把同步失败作为阻塞错误；继续基于当前资料、模型能力和通用系统维护经验诊断。
- 遵循渐进式披露：先读本入口判断场景；再只读取命中的 `references/system-repair/<scenario>.md` 或 `references/feature-enhancement/<scenario>.md`；如果 reference 指向 `knowledge/` 下的章节，再继续读取对应知识文件。不要把未命中的 reference 或 knowledge 预加载进上下文。
- `references/` 定位为任务类型 + 场景分类的路由入口和快速诊断索引。一级目录只有两类：`system-repair/` 和 `feature-enhancement/`；二级文件按相同场景命名，例如 `ukui.md`、`network.md`、`source-rebuild.md`。命名和路由规则见 [references/README.md](references/README.md)。
- `knowledge/` 定位为可复用的具体章节。一级目录同样只有两类：`system-repair/` 和 `feature-enhancement/`；二级目录与 references 使用相同场景分类。结构说明见 [knowledge/README.md](knowledge/README.md)。
- 新增经验时先判断任务类型，再落到最小匹配场景的 `knowledge/<system-repair|feature-enhancement>/<scenario>/` 章节；若还没有对应章节，新增章节后从同场景 reference 链接过去。维护模式、安全边界、通用诊断闭环属于 `system-repair/system/`；本地源码客制化和功能新增属于 `feature-enhancement/source-rebuild/` 或对应功能场景。
- 如果问题需要重新编译系统源码包、替换系统共享库，或保存本地客制化源码、patch、构建/回滚临时目录索引，不要写入通用维护文档；修复类先读取 [references/system-repair/source-rebuild.md](references/system-repair/source-rebuild.md)，增强类先读取 [references/feature-enhancement/source-rebuild.md](references/feature-enhancement/source-rebuild.md)。
- 先诊断，再改系统。读取日志、服务状态、设备节点、应用实际路径后再执行提权命令。
- 修复系统问题时，默认以“重启后仍然有效”的持久化修复为目标。先做运行时止血时，必须继续判断是否需要修复配置文件、systemd/D-Bus 激活关系、包安装状态、设备节点持久规则、用户级设置后端或开机启动链路，并在验证中说明哪些部分是临时生效、哪些部分已持久化。
- 不要删除、移动或覆盖用户已有的可执行文件、配置文件、订阅文件、代理核心或 systemd 单元，除非用户明确要求。
- 不要把“恢复官方包、删除本地定制、回滚源码修改、重装组件”作为默认第一步。遇到用户已有定制、源码重编译产物、手工修复或已验证可用的改动时，先保留现场并建立证据链；只有日志、校验、依赖关系、调用链或 A/B 验证明确指向该定制，且已备份并获得用户确认后，才临时恢复官方版本或回滚定制。
- 优先从最直接的根因修复入手；workaround、watchdog、定时重启、自动重拉起等兜底方案只能在根因暂时无法确认、用户需要临时恢复可用性或明确接受时使用，并要标注为临时方案。
- 每次问题确认修复完成后，必须主动把新增的可复用诊断步骤、修复步骤、风险点或系统特性记录到本 skill 的 `SKILL.md`、对应 `references/` 路由或 `knowledge/` 章节，并在最终回复中说明记录位置。
- 如果实际解决的是当前 skill 尚未覆盖的 KylinOS Desktop V11 系统问题，应新增合适的 `references/system-repair/<scenario>.md` 或 `references/feature-enhancement/<scenario>.md` 作为分类入口，并把详细处理经验沉淀到同任务类型、同场景的 `knowledge/` 章节；再在 `SKILL.md` 的“参考文档路由”中补充入口。
- 在本 skill 仓库执行 `git commit` 前，必须检查 `README.md` 和 `README.en.md` 是否需要同步；如果变更影响安装方式、核心基础要求、支持的问题类型、参考文档入口、安全边界、全局提示词或公开使用流程，应在同次提交中更新 README。
- 涉及 `/usr`、`/etc`、`/opt`、`/dev`、systemd、设备节点、网络路由、代理核心复制、系统包安装/卸载等系统级修复时，必须先检查维护模式并说明影响。
- 系统级修复前运行 `mm-cli -s`；只有确认当前是 maintain mode 才能继续实际修改系统路径、系统服务或系统包。
- 如果当前不是维护模式，不要继续系统级修复。在有图形/Polkit 环境且当前 AI 工具可执行命令时，应优先主动执行 `pkexec mm-cli -o` 触发授权弹窗；授权成功后提醒用户重启系统，重启后重新打开当前 AI 工具再继续问题修复。只有无法触发授权、命令失败或用户不希望授权时，才让用户手工执行 `sudo mm-cli -o`。
- 通过命令行安装程序前，注意 Kylin Desktop V11 可能会被系统保护/磐石架构阻拦。需要先切换到维护模式，安装完成后再退出维护模式。
- KARE 打包应用可能存在宿主机路径和 KARE 内部路径不一致的问题；不要假设应用内看到的路径就是宿主机真实路径。
- 优先保留用户已经恢复正常的工作状态。遇到“之前手动修复过”的路径，要先验证再决定是否改动。
- UKUI 设置界面显示的开机自启动项不完全等同于 `~/.config/autostart` 文件列表；它还可能受 `org.ukui.control-center` 的 `autoapp-list` 和 `sort-app-list` 过滤。
- UKUI 开机自启动项不在设置界面显示时，优先检查 `.desktop` 的 `Icon=` 是否能在宿主系统解析到；KARE/Kaiming 应用常见问题是图标路径指向应用内部路径。

## 参考文档路由

先判断任务类型，再按相同场景读取最小 reference；只有未命中时才读取该类型下的 `system.md`。

### 系统问题修复

用于“系统已有行为异常、失效、报错、不能持久化”的问题：

- 系统基础、维护模式、系统服务、体检噪声：读取 [references/system-repair/system.md](references/system-repair/system.md)。
- 应用安装失败、AppImage、KARE/Kaiming 隔离：读取 [references/system-repair/applications.md](references/system-repair/applications.md)。
- UKUI 自启动、全局搜索异常、托盘、快捷键、AI 组件、面板/任务栏：读取 [references/system-repair/ukui.md](references/system-repair/ukui.md)。
- 代理、TUN、Clash Verge、网络弹窗：读取 [references/system-repair/network.md](references/system-repair/network.md)。
- 指纹、生物识别、图形频率、硬件稳定性：读取 [references/system-repair/hardware.md](references/system-repair/hardware.md)。
- 分区、挂载、DATA、`/home`、overlay、空间不足：读取 [references/system-repair/storage.md](references/system-repair/storage.md)。
- AI 工具权限与系统修复边界：读取 [references/system-repair/agent-tools.md](references/system-repair/agent-tools.md)。
- 必须源码重编译才能修复的系统问题：读取 [references/system-repair/source-rebuild.md](references/system-repair/source-rebuild.md)。

### 系统功能增强

用于“系统原本能工作，但需要新增能力、改变默认行为或本地客制化”的任务：

- 系统维护流程、持久化策略、本地客制化规则增强：读取 [references/feature-enhancement/system.md](references/feature-enhancement/system.md)。
- 应用安装体验、桌面入口、用户级安装方式增强：读取 [references/feature-enhancement/applications.md](references/feature-enhancement/applications.md)。
- UKUI 全局搜索、搜索引擎、自定义命令、托盘等增强：读取 [references/feature-enhancement/ukui.md](references/feature-enhancement/ukui.md)。
- 网络策略、代理集成行为增强：读取 [references/feature-enhancement/network.md](references/feature-enhancement/network.md)。
- 硬件能力恢复后的可选增强记录：读取 [references/feature-enhancement/hardware.md](references/feature-enhancement/hardware.md)。
- DATA 工作区、分区使用和本地开发空间策略：读取 [references/feature-enhancement/storage.md](references/feature-enhancement/storage.md)。
- AI 工具全局提示词、权限、自动加载 skill：读取 [references/feature-enhancement/agent-tools.md](references/feature-enhancement/agent-tools.md)。
- 源码级功能增强、本地 patch 保存、构建和清理策略：读取 [references/feature-enhancement/source-rebuild.md](references/feature-enhancement/source-rebuild.md)。

## 通用检查

处理 Kylin/KARE 应用问题时，先收集这些信息：

```bash
uname -a
id
command -v <应用命令> || true
ps -ef | rg -i '<应用关键字>' | rg -v rg || true
systemctl status <服务名> --no-pager
```

KARE 应用常见路径：

```bash
/opt/kare/usr/bin
/opt/kare-applications/shadow/upper/usr/bin
/opt/kare-applications/shadow/merge/usr/bin
```

如果问题涉及应用日志，优先从用户目录下的 `~/.local/share`、`~/.config`、`~/.cache` 查找实际应用数据目录。

## 命令行安装与维护模式

在 Kylin Desktop V11 上通过命令行安装程序、写入系统路径或修改系统服务前，先检查当前模式：

```bash
mm-cli -s
```

只有输出表明当前是 maintain mode 时，才继续实际系统级修改。如果当前是 normal mode，不要继续修复；先进入维护模式：

```bash
sudo mm-cli -o
```

优先由当前 AI 工具在用户授权后执行，触发图形授权弹窗：

```bash
pkexec mm-cli -o
```

如果无法触发授权弹窗、命令失败或用户不希望授权，再让用户手工执行 `sudo mm-cli -o`。

执行后需要重启系统，重启后重新打开当前 AI 工具再继续系统级修复。

完成安装或系统修改后，退出维护模式并保存修改：

```bash
mm-cli -c -a
```

退出维护模式后通常也需要重启系统。不要把系统长期留在维护模式。执行安装前后都应向用户说明当前模式切换、重启要求和影响。

具体应用安装、AppImage、KARE 环境误装和第三方 apt 源处理步骤不要堆在本入口中；按需读取 [references/system-repair/applications.md](references/system-repair/applications.md) 或 [references/feature-enhancement/applications.md](references/feature-enhancement/applications.md)。
