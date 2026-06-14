# KylinOS Desktop V11 通用系统维护

此文档适用于所有 KylinOS Desktop V11 系统级问题。即使具体问题尚未被其他 reference 覆盖，也应先读取本文件，确认维护模式、系统保护边界和最小诊断闭环。

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
5. 修改完成后验证功能和状态。
6. 如果产生新的可复用经验，更新 `SKILL.md` 或新增/扩展 `references/*.md`。

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

## 未覆盖问题的经验沉淀

如果实际解决的是当前 skill 尚未覆盖的系统问题：

1. 新增合适的 `references/<topic>.md`，或扩展最接近的现有 reference。
2. 在 `SKILL.md` 的“参考文档”中补充入口和触发场景。
3. 文档使用中文，避免写入当前用户专属路径、用户名或一次性状态。
4. 使用 `$HOME`、`<user>`、`<app-id>`、`<desktop-id>`、`<service-name>` 等通用占位符。
5. 最终回复中说明经验已记录到哪个文档；如果没有新增可复用经验，说明原因。
