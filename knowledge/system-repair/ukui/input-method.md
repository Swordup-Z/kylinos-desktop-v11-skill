# UKUI 输入法与 Fcitx5 托盘异常

此流程用于处理 KylinOS Desktop V11 上输入法托盘图标显示异常、点击打不开、Fcitx5 主程序缺失、默认输入法不符合预期等问题。

## 典型现象

- 右下角输入法图标还在，但显示成键盘或英文图标，点击后打不开输入法菜单。
- `ps` 显示有 `fcitx5`，但 `/proc/<pid>/exe` 指向 `/usr/bin/fcitx5 (deleted)`。
- `dpkg -l` 显示 `fcitx5` 为 `rc`，而 `fcitx5-data`、`fcitx5-modules` 等依赖包仍为 `ii`。
- 安装第三方客户端失败后，`fcitx5` 主包被卸载，系统安装了 `fcitx-bin`、`fcitx-data` 等 Fcitx4 包，导致托盘只能显示部分输入法状态。
- 用户希望使用 fcitx5 版搜狗输入法，但 profile 仍默认指向讯飞或其他输入法。

## 诊断

先确认主程序、包状态、当前输入法和托盘项：

```bash
ps -ef | rg -i 'fcitx5|iflyime|sogou|ime|input' | rg -v rg
readlink -f /proc/<fcitx5-pid>/exe 2>/dev/null || true
ls -l /usr/bin/fcitx5 /proc/<fcitx5-pid>/exe 2>/dev/null || true
dpkg -l | rg -i '^(ii|rc)\s+(fcitx5|fcitx|com.sogou.ime.ng.fcitx5.kylin|com.iflytek.iflyime)\b'
fcitx5-remote -n 2>&1 || true
sed -n '1,160p' "$HOME/.config/fcitx5/profile"
```

查看托盘注册项：

```bash
for item in $(busctl --user get-property org.kde.StatusNotifierWatcher /StatusNotifierWatcher org.kde.StatusNotifierWatcher RegisteredStatusNotifierItems | sed -E 's/^as [0-9]+ //; s/"//g'); do
  svc=${item%%/*}
  path=/${item#*/}
  echo "== $svc $path"
  busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem Id 2>/dev/null || true
  busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem Title 2>/dev/null || true
  busctl --user get-property "$svc" "$path" org.kde.StatusNotifierItem IconName 2>/dev/null || true
done
```

## 恢复 Fcitx5 主程序

如果 `/usr/bin/fcitx5` 缺失，或运行中的进程显示为 `/usr/bin/fcitx5 (deleted)`，应恢复 `fcitx5` 主程序包。安装系统包属于系统级修复，先确认维护模式：

```bash
mm-cli -s
```

只有 maintain mode 下才执行实际安装：

```bash
apt-get -s install fcitx5
pkexec apt-get install -y fcitx5
```

安装完成后确认：

```bash
command -v fcitx5 fcitx5-remote fcitx5-configtool
dpkg --audit
dpkg -l | rg -i '^(ii|rc)\s+(fcitx5|fcitx|com.sogou.ime.ng.fcitx5.kylin)\b'
```

`fcitx` 或旧输入法包显示 `rc` 通常表示只剩配置文件，不代表仍在运行。不要仅因 `rc` 状态就盲目清理；先确认当前用户实际需要的输入法。

如果问题出现在第三方客户端安装失败之后，先检查是否被依赖解析替换成 Fcitx4：

```bash
dpkg -l | rg -i '^(ii|iU|iF|rc)\s+(fcitx5$|fcitx-bin|fcitx-data|com.sogou.ime.ng.fcitx5.kylin)\b'
readlink -f /proc/<fcitx5-pid>/exe 2>/dev/null || true
apt-get -s install fcitx5
```

如果模拟结果只会卸载 `fcitx-bin`、`fcitx-data` 并恢复 `fcitx5`，且不会卸载当前需要的输入法包，可以执行：

```bash
pkexec apt-get install -y fcitx5
fcitx5-remote -e 2>/dev/null || true
pkill -x fcitx5 2>/dev/null || true
fcitx5 -d
```

随后用 `fcitx5-remote -n`、`busctl --user` 的托盘项和 `dpkg --audit` 验证。不要因为 apt 提示旧 Fcitx4 相关包可 `autoremove` 就立即清理；先确认输入法、托盘和用户词库行为恢复正常。

## 切换默认输入法

fcitx5 版搜狗输入法的常见包名和输入法 ID：

```text
com.sogou.ime.ng.fcitx5.kylin
```

如果该包已安装，可以把它设置为当前输入法：

```bash
fcitx5-remote -s com.sogou.ime.ng.fcitx5.kylin
fcitx5-remote -n
```

如果要持久设为默认输入法，优先使用 `fcitx5-configtool`。需要手工改 profile 时，先让 fcitx5 退出，避免运行中的 fcitx5 在退出时覆盖手工修改：

```bash
fcitx5-remote -e
```

然后编辑 `$HOME/.config/fcitx5/profile`，把 `DefaultIM` 设为目标输入法 ID，并确保该输入法在当前 group 的 `Items` 中。例如：

```ini
[Groups/0]
Name=默认
Default Layout=us
DefaultIM=com.sogou.ime.ng.fcitx5.kylin

[Groups/0/Items/0]
Name=keyboard-us
Layout=

[Groups/0/Items/1]
Name=com.sogou.ime.ng.fcitx5.kylin
Layout=
```

再启动：

```bash
fcitx5 -d
```

## 验证

```bash
fcitx5-remote --check
fcitx5-remote -n
ps -ef | rg -i 'fcitx5|iflyime|sogou' | rg -v rg
sed -n '1,100p' "$HOME/.config/fcitx5/profile"
```

托盘项的 `Title` 应显示目标输入法，例如搜狗输入法通常显示 `Sogou IME NG for Kylin`，`IconName` 包含 `fcitx5-com.sogou.ime.ng.fcitx5.kylin`。

如果托盘仍不刷新，但 `fcitx5-remote -n` 已正确，可只重启 `ukui-panel` 刷新托盘显示：

```bash
pkill -x ukui-panel
```

不要在没有证据时删除整个 `$HOME/.config/fcitx5`；这会丢失用户词库、分组和输入法偏好。
