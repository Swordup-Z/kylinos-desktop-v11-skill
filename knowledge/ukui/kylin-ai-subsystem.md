# Kylin AI 子系统卸载

此流程用于 Kylin Desktop V11 上清理任务栏/托盘右侧 AI 助手、AI 子系统运行时、Kaiming AI 助手应用残留。

## 目录

- 前置条件
- 诊断
- 安全卸载边界
- 残留清理
- `kylin-ai-memorymap` 文件保护箱残留
- 验证

## 前置条件

这是系统级修复。必须先检查维护模式：

```bash
mm-cli -s
```

只有当前为 maintain mode 时才继续实际卸载。若为 normal mode，先执行：

```bash
sudo mm-cli -o
```

或经用户授权执行：

```bash
pkexec mm-cli -o
```

然后提醒用户重启系统，重启后重新打开 Codex 再继续。

## 诊断

先确认 AI 组件来源：

```bash
ps -ef | rg -i 'kylin-ai|aiassistant|kyai|kytensor|recollect|kylin_ai' | rg -v rg || true
rg -n 'kylin-ai|aiassistant|AI 助手|kyai|kytensor' "$HOME/.config/autostart" /etc/xdg/autostart /usr/share/applications /opt/kaiming/share/applications /var/opt/kaiming/share/applications 2>/dev/null
/opt/kaiming-tools/bin/kaiming list 2>&1 | rg -i 'kylin-ai|aiassistant|assistant|kyai' || true
dpkg -l | rg -i 'kylin-ai|kyai|kytensor|genai|llm-backend|onnxruntime-backend|kyml' || true
```

## 安全卸载边界

优先卸载 Kaiming AI 助手应用：

```bash
pkexec /opt/kaiming-tools/bin/kaiming uninstall -y --delete-data cn.kylin.kylin-aiassistant
```

再模拟卸载右侧 AI 子系统运行时：

```bash
apt-get -s purge kylin-ai-subsystem kylin-ai-runtime kylin-ai-recollect-service
```

确认只卸载这 3 个目标包后再执行：

```bash
pkexec apt-get purge -y kylin-ai-subsystem kylin-ai-runtime kylin-ai-recollect-service
```

如果 AI 服务进程仍被会话管理器拉起，可模拟卸载服务包：

```bash
apt-get -s purge kyai-data-management-service kylin-ai-document-qa-service kylin-ai-document-service kylin-ai-vector-engine kylin-ai-subsystem-plugin kylin-ai-subsystem-modelconfig kylin-ai-abstract-models kylin-ai-engine-plugins kylin-ai-python-env
```

确认不会卸载 `ukui-panel`、`ukui-widget-system-tray`、`peony`、`ukui-desktop-environment` 等桌面核心组件后再执行：

```bash
pkexec apt-get purge -y kyai-data-management-service kylin-ai-document-qa-service kylin-ai-document-service kylin-ai-vector-engine kylin-ai-subsystem-plugin kylin-ai-subsystem-modelconfig kylin-ai-abstract-models kylin-ai-engine-plugins kylin-ai-python-env
```

不要直接清理所有 `libkyai*`、`libkysdk-genai*`、`kytensor*`、`llm-backend`、`onnxruntime-backend`、`kyml` 等库。实测这类广泛清理可能牵连 `ukui-panel`、系统托盘、Peony 文件管理器、`ukui-desktop-environment` 等核心桌面组件。

## 残留清理

删除用户级无效自启动项：

```bash
rm -f "$HOME/.config/autostart/kylin-aiassistant-autostart.desktop"
```

删除 AI 助手用户数据目录时只删除对应应用目录：

```bash
pkexec rm -rf "$HOME/.var/app/cn.kylin.kylin-aiassistant"
```

如果卸载前已经启动的旧进程仍存在，可按实际 PID 终止：

```bash
ps -ef | rg -i 'kylin-ai|aiassistant|kyai|kytensor|recollect|kylin_ai' | rg -v rg
pkexec kill <pid...>
```

## `kylin-ai-memorymap` 文件保护箱残留

卸载 AI 助手/AI 子系统后，用户目录下可能仍有 `$HOME/.box/kylin-ai-memorymap`。这通常不是普通目录，而是麒麟文件保护箱/box 机制创建的挂载点，可能由 `$HOME/.box/kylin-ai-memorymap/.data` 通过 eCryptfs 挂载到保护箱目录本身。不要直接对挂载点或 `.data` 执行 `rm -rf`。

先诊断：

```bash
boxadm -l
boxadm -i kylin-ai-memorymap
findmnt -R "$HOME/.box/kylin-ai-memorymap" -o TARGET,SOURCE,FSTYPE,PROPAGATION,OPTIONS
lsof +D "$HOME/.box/kylin-ai-memorymap" 2>/dev/null || true
ps -ef | rg -i 'kylin-ai-memorymap|memorymap|kylin-ai|aiassistant|kyai|kytensor|recollect|kylin_ai' | rg -v rg || true
/opt/kaiming-tools/bin/kaiming list 2>&1 | rg -i 'memorymap|kylin-ai|aiassistant|assistant|kyai' || true
dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\t${Version}\n' 'kylin-ai-memorymap*' 'cn.kylin.kylin-ai-memorymap*' 2>/dev/null || true
```

如果 `boxadm -l` 仍显示 `kylin-ai-memorymap`，但 Kaiming/dpkg 没有对应应用或包、没有相关进程、`lsof` 没有打开文件，可以判断为 AI memorymap 的用户级保护箱残留。清理时优先使用 box 工具：

```bash
boxadm -r kylin-ai-memorymap
boxadm -l
findmnt -R "$HOME/.box/kylin-ai-memorymap" 2>/dev/null || true
```

`boxadm -r` 在维护模式下可能输出多条 `GLib-GIO-CRITICAL`、`AddMatch()`、`GetNameOwner()` 或“连接已关闭”告警；只要最终返回 `boxadm: kylin-ai-memorymap 已删除` 且退出码为 0，不应仅凭这些告警判断失败。随后必须验证：

```bash
boxadm -l
findmnt -R "$HOME/.box/kylin-ai-memorymap" 2>/dev/null || true
ls -ld "$HOME/.box" "$HOME/.box/kylin-ai-memorymap" "$HOME/.box/kylin-ai-memorymap/.data" 2>/dev/null || true
mount | rg 'kylin-ai-memorymap|\.box|ecryptfs' || true
rg -n '/home/[^[:space:]"]+/\.box/kylin-ai-memorymap|\.box/kylin-ai-memorymap|kylin-ai-memorymap/\.data|\.box_ecrypt\.conf' /etc/ksaf/policy "$HOME/.box" 2>/dev/null || true
```

验证通过的状态是：`boxadm -l` 不再列出 `kylin-ai-memorymap`，`findmnt` 和 `mount` 没有相关挂载，`$HOME/.box/kylin-ai-memorymap` 和 `.data` 不存在，KSaf 策略中没有该保护箱路径级规则。策略文件里可能仍有 `cn.kylin.kylin-ai-memorymap` 这类应用/包名白名单，不能把它和保护箱路径残留混为一谈。

如果清理动作会修改 `/etc/ksaf/policy`、系统服务或其他系统路径，仍按通用规则先检查维护模式；非维护模式只做诊断，提示用户进入维护模式并重启后继续。

## 验证

```bash
ps -ef | rg -i 'kylin-ai|aiassistant|kyai|kytensor|recollect|kylin_ai' | rg -v rg || true
/opt/kaiming-tools/bin/kaiming list 2>&1 | rg -i 'kylin-ai|aiassistant|assistant|kyai' || true
dpkg-query -W -f='${db:Status-Abbrev} ${binary:Package}\t${Version}\n' | rg -i '^(ii|rc)\s+(kylin-ai-subsystem|kylin-ai-runtime|kylin-ai-recollect-service|kyai-data-management-service|kylin-ai-document-qa-service|kylin-ai-document-service|kylin-ai-vector-engine|kylin-ai-subsystem-plugin|kylin-ai-subsystem-modelconfig|kylin-ai-abstract-models|kylin-ai-engine-plugins|kylin-ai-python-env)\b|cn.kylin.kylin-aiassistant' || true
ls -l "$HOME/.config/autostart/kylin-aiassistant-autostart.desktop" /etc/xdg/autostart/kylin-aiassistant-autostart.desktop /etc/xdg/autostart/kylin-ai-runtime.desktop /opt/kaiming/share/applications/kylin-aiassistant.desktop /opt/kaiming/bin/kylin-aiassistant /opt/kaiming/bin/cn.kylin.kylin-aiassistant "$HOME/.var/app/cn.kylin.kylin-aiassistant" 2>/dev/null || true
```

完成系统修改后，退出维护模式并保存：

```bash
mm-cli -c -a
```

如果普通用户执行返回 `Permission denied: Exit maintain mode as root`，改用：

```bash
pkexec mm-cli -c -a
```

随后提醒用户重启系统。
