# KylinOS Desktop V11 通用系统维护

此文档适用于所有 KylinOS Desktop V11 系统级问题。即使具体问题尚未被其他 reference 覆盖，也应先读取本文件，确认维护模式、系统保护边界和最小诊断闭环。

## 目录

- 适用场景
- 基础流程
- 维护模式检查
- 退出维护模式
- 诊断优先
- 持久化修复优先
- 场景化参考文档
- 未覆盖问题的经验沉淀

## 适用场景

- 用户问题涉及系统服务、系统包、设备节点、网络路由、系统路径、桌面环境、KARE/Kaiming、分区挂载、磐石架构、KSaf 策略或系统保护。
- 用户要通过命令行安装、卸载或修复应用，并且操作可能写入 `/usr`、`/etc`、`/opt`、`/dev`、systemd 单元、分区或系统策略。
- 问题不在当前 skill 的专门 reference 中，但明确属于 KylinOS Desktop V11 桌面系统维护范围。

普通代码开发、文档编辑、Git 操作、业务需求分析或与当前桌面操作系统无关的问题，不需要读取本 reference。

## 基础流程

1. 先确认问题是否属于 KylinOS Desktop V11 系统问题。
2. 读取状态和日志，优先做非破坏诊断。
3. 如果需要系统级修改，先检查维护模式。
4. 只有确认处于 maintain mode 后，才执行系统级修改。
5. 优先做持久化修复：临时止血后，继续确认重启、重新登录、服务重拉起或应用重启后是否仍然有效。
6. 修改完成后验证功能和状态，并说明哪些修复是运行时生效、哪些已写入持久配置。
7. 如果产生新的可复用经验，更新 `SKILL.md` 或新增/扩展 `references/*.md`。

## 维护模式检查

执行任何系统级修复前，先运行：

```bash
mm-cli -s
```

只有输出表明当前是 maintain mode，才允许修改 `/usr`、`/etc`、`/opt`、系统包、系统服务、设备节点、分区或 KSaf 策略。

如果当前不是维护模式，不要继续系统级修复。可以让用户执行：

```bash
sudo mm-cli -o
```

或在用户授权后执行：

```bash
pkexec mm-cli -o
```

进入维护模式后需要重启系统，重启后重新打开 AI 工具再继续修复。在进入维护模式并重启前，只允许诊断、读取状态、查看日志、模拟安装/卸载等非破坏操作。

应用安装、AppImage、KARE 环境误装、第三方 apt 源和公钥问题属于安装/包管理知识，应读取 [application-installation.md](application-installation.md)，不要把具体安装步骤继续追加到本文档。

## 退出维护模式

系统级修改完成并验证后，退出维护模式并保存修改：

```bash
sudo mm-cli -c -a
```

或：

```bash
pkexec mm-cli -c -a
```

退出维护模式后通常还需要重启系统。重启后再确认系统已回到 normal mode。

`mm-cli -c -a` 的效果是“保存维护模式改动，并安排后续回到 normal mode”。在已启动的维护模式会话里，即使命令成功，`mm-cli -s` 仍可能继续显示 maintain；日志中可能同时出现 `Maintain mode has been deactivated with all packages saved` 和 `current system status: maintain`，这通常表示当前会话仍保持维护模式，下一次重启后才会进入 normal mode。验证时以重启后的 `mm-cli -s` 为准。

在部分环境中，`mm-cli -c -a` 前台可能返回“退出维护模式失败”，但后台日志已经写入下一次启动进入 normal mode。遇到这种不一致时，不要反复执行破坏性操作，先查日志确认真实状态：

```bash
journalctl -b --no-pager | rg -i 'mm-cli|maintain mode|normal mode|Next time'
mm-cli -s
```

如果日志包含类似 `Next time will in normal mode`，说明当前启动仍显示 maintain mode 是预期现象，需要重启后再验证 `mm-cli -s` 是否变为 normal mode。

## 诊断优先

通用诊断命令：

```bash
uname -a
id
mm-cli -s
systemctl --failed --no-pager
```

如果问题涉及某个应用或服务，再按实际对象检查：

```bash
command -v <app-command> || true
ps -ef | rg -i '<keyword>' | rg -v rg || true
systemctl status <service-name> --no-pager
journalctl -u <service-name> -n 100 --no-pager
```

不要在没有确认影响前删除、覆盖或移动用户已有的可执行文件、配置文件、订阅文件、代理核心、systemd 单元或用户数据。

## 持久化修复优先

系统问题不应只停留在当前会话的临时状态修复。常见判断方式：

- systemd 服务异常：除了 `restart` 运行时恢复，还要检查 unit、drop-in、D-Bus activation、enable 状态、依赖关系和重启后行为。
- 设备节点或内核模块异常：除了手动创建节点或加载模块，还要检查 udev 规则、modules-load、sysctl、内核参数或包安装状态。
- 桌面设置异常：除了直接改 JSON/gsettings/dconf，还要确认设置界面、用户级配置后端和应用重启后是否一致。
- 开机自启动异常：除了手动启动应用，还要确认 `.desktop`、UKUI 设置后端、图标解析、隐藏项和登录后自启动链路。
- 系统保护/磐石架构问题：除了进入维护模式安装或修复，还要确认退出维护模式、重启后状态仍然存在。

如果只能做临时止血，应明确告诉用户剩余的持久化风险和下一步验证方式。

## 场景化参考文档

本文档只保留系统级修复的底座规则。具体场景应继续按需读取对应 reference：

- 应用安装、AppImage、KARE 环境误装、第三方 apt 源和公钥问题：读取 [application-installation.md](application-installation.md)。
- KARE namespace、应用内 hostname 显示 `kare`、从 KARE 误启动 UKUI 面板、开始菜单固定项仍指向 KARE：读取 [kare-namespace.md](kare-namespace.md)。
- 全盘体检后的系统噪声清理、`motd-news.service`、PAM 残留引用、rsyslog 旧式配置：读取 [system-health-noise.md](system-health-noise.md)。

## 未覆盖问题的经验沉淀

如果实际解决的是当前 skill 尚未覆盖的系统问题：

1. 新增合适的 `references/<topic>.md`，或扩展最接近的现有 reference。
2. 在 `SKILL.md` 的“参考文档”中补充入口和触发场景。
3. 文档使用中文，避免写入当前用户专属路径、用户名或一次性状态。
4. 使用 `$HOME`、`<user>`、`<app-id>`、`<desktop-id>`、`<service-name>` 等通用占位符。
5. 最终回复中说明经验已记录到哪个文档；如果没有新增可复用经验，说明原因。
