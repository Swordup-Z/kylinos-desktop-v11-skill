# UKUI 开机自启动

此流程用于 Kylin Desktop V11/UKUI 上“开机自启动项已添加但不启动”或“设置界面不显示新增启动项”的问题。

## 目录

- 关键结论
- 检查当前状态
- 修复原始 XDG 自启动项
- 让 UKUI 设置界面显示新增项
- 设置页全空但后端有数据

## 关键结论

- XDG 自启动文件应放在当前用户的 `~/.config/autostart/` 下，文件名保持稳定且无空格，例如 `<app-id>.desktop`。
- UKUI 控制中心不一定直接展示 `~/.config/autostart/` 中的全部文件。实测普通用户自定义项可能进入 D-Bus `statusMap`，但仍不在设置界面显示。
- UKUI 自启动插件会解析 `Icon=` 并构建 `QPixmap`；`Icon` 为空或无法解析时，即使条目已进入 `statusMap`，设置界面也可能直接跳过该项。
- `org.ukui.control-center autoapp-list` 更像系统项过滤列表，不要把新应用盲目追加进去；否则后端可能把对应系统项跳过。
- `org.ukui.control-center sort-app-list` 只是已显示条目的排序/状态列表。前端可能在刷新时自动改回它实际接受的条目。
- 如果设置页显示全空，但 D-Bus `statusMap` 仍有条目，优先检查 `sort-app-list` 是否被清成 `@as []`；空排序列表可能导致前端不渲染任何自启动项。
- 优先修复应用原始 `.desktop` 的 `Exec=`、`Icon=`、`Hidden=` 等字段，保持 XDG/UKUI 原生自启动链路。
- 设置界面添加应用失败时，重点检查被复制出来的 `.desktop` 是否仍引用容器内路径或不可解析图标。

## 检查当前状态

```bash
ls -la "$HOME/.config/autostart"
gsettings get org.ukui.control-center autoapp-list
gsettings get org.ukui.control-center sort-app-list
busctl --user get-property org.ukui.ukcc.session /Autoboot org.ukui.ukcc.session.Autoboot statusMap
busctl --user get-property org.ukui.ukcc.session /Autoboot org.ukui.ukcc.session.Autoboot appList
systemctl --user list-unit-files | rg '<app-id>|autostart'
```

检查目标 `.desktop` 中不要有禁用字段：

```bash
rg -n '^(Hidden|X-GNOME-Autostart-enabled|X-UKUI-Autostart-enabled|NoDisplay|OnlyShowIn|NotShowIn|Exec|Name)=' "$HOME/.config/autostart/<app-id>.desktop"
```

如果存在 `Hidden=true`，该项会被视为关闭。不要直接删除用户已有文件，先确认它是不是用户主动关闭的结果。

## 修复原始 XDG 自启动项

优先找到应用自己的 `.desktop`，再复制到当前用户自启动目录或修复已有用户覆盖文件：

```bash
find /usr/share/applications /etc/xdg/autostart "$HOME/.local/share/applications" -name '*.desktop' | rg '<app-id>|<app-name>'
mkdir -p "$HOME/.config/autostart"
cp '<source>.desktop' "$HOME/.config/autostart/<desktop-id>.desktop"
```

修复后的 `~/.config/autostart/<desktop-id>.desktop` 应保持原始 `Exec=` 逻辑，只修正宿主机不可用的字段：

```ini
[Desktop Entry]
Type=Application
Name=<display-name>
Icon=<icon-name-or-absolute-path>
Exec=<original-start-command>
StartupNotify=false
Terminal=false
Categories=Utility;
Hidden=false
```

`Exec=` 尽量沿用原始 desktop 中的启动命令。KARE 应用通常是 `/usr/bin/kare run ...`。Kaiming 应用优先检查是否存在 `/opt/kaiming/bin/<app-id>` 这种宿主机导出入口；它会携带应用分支、架构等参数，通常比手写 `kaiming run ...` 更贴近应用导出的启动方式。

Kaiming 应用如果包内自启动项是 `/opt/apps/<app-id>/files/bin/<command> autostart`，宿主机自启动项可优先转换为：

```ini
Exec=/opt/kaiming/bin/<app-id> autostart
```

`Icon=` 使用目标系统上可读取的绝对路径，尤其是 KARE/Kaiming 应用。仅写图标主题名时，UKUI 控制中心可能无法在宿主机图标主题中解析。

Kaiming 应用的 `.desktop` 中可能出现容器内路径，例如 `/opt/apps/<app-id>/files/icons/logo.png`。该路径在宿主机上可能不存在；遇到设置界面仍不显示时，先用 `ls`/`file` 验证 `Icon=` 路径是否真实可读，必要时改用 `/usr/share/icons` 或 `/usr/share/kylin-software-center/data/icons` 下的宿主机图标。

如果必须保留 `Icon=<icon-name>` 这种图标主题名，确认宿主系统的图标主题中存在对应文件；例如放到 `/usr/share/icons/hicolor/<size>/apps/<icon-name>.png` 后刷新缓存：

```bash
gtk-update-icon-cache -q /usr/share/icons/hicolor || true
```

验证：

```bash
desktop-file-validate "$HOME/.config/autostart/<app-id>.desktop"
```

## 让 UKUI 设置界面显示新增项

先读取已有列表，不要覆盖掉用户已有内容：

```bash
gsettings get org.ukui.control-center autoapp-list
gsettings get org.ukui.control-center sort-app-list
```

不要盲目修改 `autoapp-list`。如果只是希望调整设置页中已显示条目的顺序，可修改 `sort-app-list`。示例：

```bash
gsettings set org.ukui.control-center sort-app-list "['<app-id>.desktop', '<existing-visible-1>.desktop']"
```

如需排查后端接管状态，可以通过 UKUI 的 D-Bus 接口查看 `statusMap`。其中 `statusMap` 已有条目不代表设置界面一定会显示该条目：

```bash
busctl --user get-property org.ukui.ukcc.session /Autoboot org.ukui.ukcc.session.Autoboot statusMap
```

也可以通过 UKUI 的 D-Bus 接口更新 `appList`，但不要把它当成显示白名单：

```bash
busctl --user call org.ukui.ukcc.session /Autoboot org.ukui.ukcc.session.Autoboot setApplist as <count> <desktop-id-1> <desktop-id-2> <app-id>.desktop
```

更新后关闭并重新打开设置。必要时只重启当前用户的 `org.ukui.ukcc.session` 后端子进程，让它重新读取状态：

```bash
busctl --user status org.ukui.ukcc.session
kill <PID-from-status>
```

随后重新检查：

```bash
busctl --user get-property org.ukui.ukcc.session /Autoboot org.ukui.ukcc.session.Autoboot statusMap
gsettings get org.ukui.control-center sort-app-list
```

如果必须让某个条目在设置界面里像“已关闭的系统项”一样出现，可用 `setAppHiddenInfo` 让 UKUI 写入用户级 `Hidden=true` 覆盖：

```bash
busctl --user call org.ukui.ukcc.session /Autoboot org.ukui.ukcc.session.Autoboot setAppHiddenInfo sb <app-id>.desktop true
```

注意：这会关闭该条目的 XDG 自启动。不要为了“让界面显示”而长期保留 `Hidden=true`。

## 设置页全空但后端有数据

如果 `~/.config/autostart` 和 `/etc/xdg/autostart` 中有文件，且 `statusMap` 有条目，但设置页一个应用都不显示，检查排序列表：

```bash
gsettings get org.ukui.control-center sort-app-list
busctl --user get-property org.ukui.ukcc.session /Autoboot org.ukui.ukcc.session.Autoboot statusMap
```

如果 `sort-app-list` 是 `@as []`，按 `statusMap` 中实际应显示的桌面文件名恢复。示例：

```bash
gsettings set org.ukui.control-center sort-app-list "['<desktop-id-1>.desktop', '<desktop-id-2>.desktop', '<desktop-id-3>.desktop']"
```

随后关闭设置页，并重启当前用户的 `org.ukui.ukcc.session` 后端：

```bash
busctl --user status org.ukui.ukcc.session
kill <PID-from-status>
setsid ukui-control-center -m autoboot >/tmp/ukui-control-center-autoboot.log 2>&1 &
```
