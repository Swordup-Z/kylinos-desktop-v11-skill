# UKUI 全局搜索

本文档用于处理 KylinOS Desktop V11 上 UKUI 全局搜索相关问题，包括快捷键之外的搜索结果来源、软件商店未安装应用结果、搜索插件和 D-Bus 激活链路。

## 适用场景

- 全局搜索结果中出现应用商店里的未安装应用，用户希望只显示本机应用或本地结果。
- 设置界面的全局搜索选项没有提供对应开关。
- 需要区分文件索引、AI 索引、本机应用索引和软件商店在线/商店结果来源。

快捷键冲突、`Alt+Space` 等问题应读取 [ukui-keybindings.md](ukui-keybindings.md)。

## 先诊断

先确认 UKUI 全局搜索已有公开设置：

```bash
gsettings list-recursively org.ukui.search.settings
```

其中 `ai-index-enable` 只表示 AI 索引服务开关，不等同于“是否显示应用商店里的未安装应用”。如果它已经是 `false`，全局搜索仍显示商店应用，继续检查软件商店搜索插件。

确认软件商店搜索结果提供者：

```bash
sed -n '1,80p' /usr/share/dbus-1/services/com.kylin.softwarecenter.getsearchresults.service
dpkg -S /usr/share/dbus-1/services/com.kylin.softwarecenter.getsearchresults.service /usr/bin/kylin-software-center-plugin-synchrodata
busctl --user list | rg 'com.kylin.softwarecenter.getsearchresults|ukui.search'
ps -ef | rg -i 'ukui-search|software-center|softwarecenter|synchrodata' | rg -v rg
```

常见链路：

```text
UKUI 全局搜索
  -> com.kylin.softwarecenter.getsearchresults
  -> /usr/bin/kylin-software-center-plugin-synchrodata
  -> 返回软件商店应用结果
```

## 用户级屏蔽软件商店搜索结果

如果系统没有提供正式 UI/gsettings 开关，优先使用用户级 D-Bus service 覆盖，不修改 `/usr`，不卸载软件商店本体：

```bash
mkdir -p "$HOME/.local/share/dbus-1/services"
```

创建文件：

```text
$HOME/.local/share/dbus-1/services/com.kylin.softwarecenter.getsearchresults.service
```

内容：

```ini
[D-BUS Service]
Name=com.kylin.softwarecenter.getsearchresults
Exec=/bin/false
```

重载当前用户 D-Bus 配置：

```bash
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
```

退出已启动的旧软件商店搜索插件：

```bash
pkill -f /usr/bin/kylin-software-center-plugin-synchrodata
```

如果当前全局搜索窗口仍显示旧结果，可让搜索前台按自身参数退出，下一次快捷键打开时会重新拉起：

```bash
ukui-search --quit
ukui-search-service --quit
```

## 验证

确认软件商店搜索插件没有常驻：

```bash
ps -ef | rg -i 'kylin-software-center-plugin-synchrodata|ukui-search' | rg -v rg
```

确认 D-Bus 激活被用户级覆盖阻断：

```bash
busctl --user call com.kylin.softwarecenter.getsearchresults /com/kylin/softwarecenter/getsearchresults com.kylin.getsearchresults get_search_result s obsidian
```

预期返回类似：

```text
Call failed: Process com.kylin.softwarecenter.getsearchresults exited with status 1
```

再打开全局搜索，检查未安装的软件商店应用是否不再出现。

## 回滚

删除用户级覆盖文件：

```bash
rm -f "$HOME/.local/share/dbus-1/services/com.kylin.softwarecenter.getsearchresults.service"
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
```

重新登录，或重新打开全局搜索后，系统会回到 `/usr/share/dbus-1/services/` 下的默认软件商店搜索提供者。

## 注意事项

- 该方案只屏蔽“全局搜索从软件商店拉取结果”的 D-Bus 激活链路，不卸载 `kylin-software-center`。
- 软件商店应用本体、系统包管理和本机应用搜索不应受影响。
- 这是用户级持久化配置，不需要维护模式；如果改成移动、删除或覆盖 `/usr/share/dbus-1/services/` 下的系统 service，则属于系统级修复，必须先检查维护模式。
