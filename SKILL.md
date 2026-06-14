---
name: kylinos-desktop-v11-skill
description: 处理 KylinOS Desktop V11 桌面系统上的应用安装与兼容、系统服务、网络代理、KARE 打包应用、UKUI 桌面环境和常见系统集成问题。适用于系统级修复、维护模式、磐石架构、AppImage/libfuse、第三方 apt 源、Clash Verge Rev TUN 模式安装失败、/dev/net/tun 缺失、clash-verge-service 安装失败、KARE 应用路径异常、代理核心 verge-mihomo 丢失或路径不一致、UKUI 开机自启动项不生效或设置界面不显示、UKUI 全局搜索结果来源、需要重新编译系统源码包的修复评估、指纹/生物识别驱动恢复、图形驱动/devfreq 调频异常等麒麟桌面 V11 维护场景。
---

# KylinOS Desktop V11

这是 KylinOS Desktop V11 桌面环境问题的技能合集。只要用户问题属于当前桌面操作系统维护范围，就先读取本入口；再识别问题所属模块，读取对应参考文档。如果没有命中专门 reference，至少读取通用系统维护文档。

## 使用原则

- 只要用户问题明确属于 KylinOS Desktop V11 桌面系统维护范围，就应使用本 skill；普通代码开发、文档编辑、Git 操作或与桌面系统无关的问题不应加载本 skill。
- 如果问题未命中某个专门 reference，也要读取 [references/system-maintenance.md](references/system-maintenance.md)，再继续诊断。
- 遵循渐进式披露：先读本入口判断场景；再只读取命中的 `references/*.md`；不要把未命中的 reference 预加载进上下文。
- 新增经验时优先落到最小匹配场景的 reference。只有维护模式、安全边界、通用诊断闭环这类跨场景底座知识，才写入 [references/system-maintenance.md](references/system-maintenance.md)。
- 如果问题需要重新编译系统源码包或替换系统共享库解决，不要写入通用维护文档；先读取对应场景 reference，再读取 [knowledge/source-rebuild/README.md](knowledge/source-rebuild/README.md) 及其子分类知识。
- 先诊断，再改系统。读取日志、服务状态、设备节点、应用实际路径后再执行提权命令。
- 修复系统问题时，默认以“重启后仍然有效”的持久化修复为目标。可以先做运行时止血，但必须继续判断是否需要修复配置文件、systemd/D-Bus 激活关系、包安装状态、设备节点持久规则、用户级设置后端或开机启动链路，并在验证中说明哪些部分是临时生效、哪些部分已持久化。
- 不要删除、移动或覆盖用户已有的可执行文件、配置文件、订阅文件、代理核心或 systemd 单元，除非用户明确要求。
- 每次问题确认修复完成后，必须主动把新增的可复用诊断步骤、修复步骤、风险点或系统特性记录到本 skill 的 `SKILL.md` 或对应 `references/` 文档，并在最终回复中说明记录位置。
- 如果实际解决的是当前 skill 尚未覆盖的 KylinOS Desktop V11 系统问题，应新增合适的 `references/*.md` 或扩展现有参考文档，并在 `SKILL.md` 的“参考文档”中补充入口。
- 在本 skill 仓库执行 `git commit` 前，必须检查 `README.md` 和 `README.en.md` 是否需要同步；如果变更影响安装方式、核心基础要求、支持的问题类型、参考文档入口、安全边界、全局提示词或公开使用流程，应在同次提交中更新 README。
- 涉及 `/usr`、`/etc`、`/opt`、`/dev`、systemd、设备节点、网络路由、代理核心复制、系统包安装/卸载等系统级修复时，必须先检查维护模式并说明影响。
- 系统级修复前运行 `mm-cli -s`；只有确认当前是 maintain mode 才能继续实际修改系统路径、系统服务或系统包。
- 如果当前不是维护模式，不要继续系统级修复。应让用户执行 `sudo mm-cli -o`，或经用户授权后执行 `pkexec mm-cli -o`；随后提醒用户重启系统，重启后重新打开 Codex 再继续问题修复。
- 通过命令行安装程序前，注意 Kylin Desktop V11 可能会被系统保护/磐石架构阻拦。需要先切换到维护模式，安装完成后再退出维护模式。
- KARE 打包应用可能存在宿主机路径和 KARE 内部路径不一致的问题；不要假设应用内看到的路径就是宿主机真实路径。
- 优先保留用户已经恢复正常的工作状态。遇到“之前手动修复过”的路径，要先验证再决定是否改动。
- UKUI 设置界面显示的开机自启动项不完全等同于 `~/.config/autostart` 文件列表；它还可能受 `org.ukui.control-center` 的 `autoapp-list` 和 `sort-app-list` 过滤。
- UKUI 开机自启动项不在设置界面显示时，优先检查 `.desktop` 的 `Icon=` 是否能在宿主系统解析到；KARE/Kaiming 应用常见问题是图标路径指向应用内部路径。

## 参考文档路由

先按问题场景选择最小 reference；只有未命中时才读取通用系统维护文档。

### 基础边界

- 维护模式、系统级修复边界、持久化修复原则、未覆盖问题的最小闭环：读取 [references/system-maintenance.md](references/system-maintenance.md)。
- 全盘体检后的系统噪声清理、`motd-news.service`、PAM 残留引用、rsyslog 旧式配置：读取 [references/system-health-noise.md](references/system-health-noise.md)。
- 涉及重新编译系统源码包、构建补丁、替换系统共享库、评估 ABI/SONAME/依赖/RPATH 风险：先读取具体场景 reference，再读取 [knowledge/source-rebuild/README.md](knowledge/source-rebuild/README.md)。

### 应用与 KARE

- 应用安装、宿主机/KARE 安装边界、AppImage 用户级安装、`libfuse.so.2` 缺失、第三方 apt 源残留或公钥缺失：读取 [references/application-installation.md](references/application-installation.md)。
- KARE namespace、应用内 hostname 显示 `kare`、开始菜单固定项仍指向 KARE、从 KARE 环境误启动 UKUI 面板：读取 [references/kare-namespace.md](references/kare-namespace.md)。

### UKUI 桌面

- UKUI 开机自启动不生效、设置界面不显示新增启动项：读取 [references/ukui-autostart.md](references/ukui-autostart.md)。
- UKUI 全局快捷键、快捷键提示被系统占用、全局搜索快捷键、`Alt+Space` 与窗口菜单冲突：读取 [references/ukui-keybindings.md](references/ukui-keybindings.md)。
- UKUI 全局搜索结果来源、软件商店未安装应用结果、`com.kylin.softwarecenter.getsearchresults` D-Bus 插件：读取 [references/ukui-search.md](references/ukui-search.md)。
- UKUI 全局搜索默认互联网搜索引擎写死、希望添加 Bing/Google 等需要源码级修改的场景：读取 [references/ukui-search.md](references/ukui-search.md)，再读取 [knowledge/source-rebuild/ukui-search-web-engine.md](knowledge/source-rebuild/ukui-search-web-engine.md)。
- UKUI 右侧托盘小图标、StatusNotifier 图标顺序/隐藏区重启后不保留、`systemTray.json`、`orderedItems`、`separateIndex`：读取 [references/ukui-system-tray.md](references/ukui-system-tray.md)。
- `ukui-system-service-manager.service` 反复 timeout、`QDBusError("", "")`、`org.ukui.serviceManager` 被孤儿进程占用：读取 [references/ukui-system-service-manager.md](references/ukui-system-service-manager.md)。
- 任务栏/托盘 AI 助手或 AI 子系统卸载、`kylin-ai-runtime`、Kaiming AI 助手残留：读取 [references/kylin-ai-subsystem.md](references/kylin-ai-subsystem.md)。

### 网络、硬件与存储

- Clash Verge Rev TUN 模式、`clash-verge-service`、`/dev/net/tun`、`verge-mihomo` 路径问题：读取 [references/clash-verge-tun.md](references/clash-verge-tun.md)。
- 指纹/生物识别驱动、`GW_Fingerprint_PA`、Pixelauth T350P、`biometric-authentication.service`、驱动已注册但设备未发现：读取 [references/biometric-fingerprint.md](references/biometric-fingerprint.md)。
- 图形驱动、GPU/显示频率、`devfreq`、`failed to set <driver> frequency`、`NVRM: No NVIDIA GPU found`、硬件强相关图形稳定性问题：读取 [references/graphics-frequency.md](references/graphics-frequency.md)。
- 根分区、DATA 分区、`/home` 挂载、磐石架构/ostree/overlay/KARE 合并视图、空间占用判断：读取 [references/storage-layout.md](references/storage-layout.md)。

### AI 工具配置

- Codex 用户级配置、默认 full access、权限显示和与维护模式/root 权限的边界：读取 [references/codex-config.md](references/codex-config.md)。
- Codex、Claude Code、opencode 等多工具全局提示词入口、用户问题 skill 路由和渐进式披露加载模板：读取 [references/agent-global-prompts.md](references/agent-global-prompts.md)。

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

或由 Codex 在用户授权后执行：

```bash
pkexec mm-cli -o
```

执行后需要重启系统，重启后重新打开 Codex 再继续系统级修复。

完成安装或系统修改后，退出维护模式并保存修改：

```bash
mm-cli -c -a
```

退出维护模式后通常也需要重启系统。不要把系统长期留在维护模式。执行安装前后都应向用户说明当前模式切换、重启要求和影响。

具体应用安装、AppImage、KARE 环境误装和第三方 apt 源处理步骤不要堆在本入口中；按需读取 [references/application-installation.md](references/application-installation.md)。
