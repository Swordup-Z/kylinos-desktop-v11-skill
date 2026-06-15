# UKUI 全局搜索

本文档用于处理 KylinOS Desktop V11 上 UKUI 全局搜索相关问题，包括快捷键之外的搜索结果来源、软件商店未安装应用结果、搜索插件和 D-Bus 激活链路。

## 适用场景

- 全局搜索结果中出现应用商店里的未安装应用，用户希望只显示本机应用或本地结果。
- 设置界面的全局搜索选项没有提供对应开关。
- 通过源码级修改在设置界面新增“是否搜索应用商店应用”的正式开关。
- 需要区分文件索引、AI 索引、本机应用索引和软件商店在线/商店结果来源。
- 设置界面的“默认互联网搜索引擎”只提供少数固定选项，用户希望添加 Bing、Google 等搜索引擎。

快捷键冲突、`Alt+Space` 等问题应读取 [`../../references/ukui-keybindings.md`](../../references/ukui-keybindings.md)。

## 先诊断

先确认 UKUI 全局搜索已有公开设置：

```bash
gsettings list-recursively org.ukui.search.settings
```

其中 `ai-index-enable` 只表示 AI 索引服务开关，不等同于“是否显示应用商店里的未安装应用”。如果它已经是 `false`，全局搜索仍显示商店应用，继续检查软件商店搜索插件。

## 互联网搜索引擎选项

先确认当前 `web-engine` 配置：

```bash
gsettings list-recursively org.ukui.search.settings
gsettings range org.ukui.search.settings web-engine
gsettings describe org.ukui.search.settings web-engine
```

`web-engine` 通常是普通字符串 key，不是枚举类型；但这不代表任意字符串都会被后端识别。继续检查设置插件和后端库：

```bash
strings /usr/lib/*/ukui-control-center/libsearch-ukcc-plugin.so | rg -n -C 5 'Default web searching engine|combobox of web search engine|baidu|sougou|360|google|bing'
strings /usr/lib/*/libukui-search* 2>/dev/null | rg -n -C 4 'baidu|sougou|360|google|bing|https://www.so.com|https://www.sogou.com|https://baidu.com'
dpkg -S /usr/lib/*/ukui-control-center/libsearch-ukcc-plugin.so /usr/lib/*/libukui-search.so.2 2>/dev/null
```

常见情况：

- `libsearch-ukcc-plugin.so` 负责设置界面下拉框，选项可能写死为 `baidu`、`sougou`、`360`。
- `libukui-search.so.2` 负责实际打开网页搜索 URL，后端可能只包含 360、搜狗、百度 URL。
- `gsettings set org.ukui.search.settings web-engine google` 这类方式即使能写入字符串，也可能被后端当作默认分支处理，实际仍打开百度。

如果源码可用，可从源码确认两个关键位置：

```text
search-ukcc-plugin/search.cpp
libsearch/websearch/web-search-plugin.cpp
```

要真正新增 Bing/Google，不应只改 gsettings，也不应只补图标；需要同时修改设置插件下拉框和后端 URL 映射，然后以与当前系统包匹配的版本重新构建、安装。没有当前系统包的精确源码和构建依赖时，不建议通过二进制字符串 patch 或替换共享库来处理，因为这会影响 UKUI 全局搜索和控制中心稳定性。

如果需要进入源码级修改，继续读取源码重编译入口：[`../../references/source-rebuild.md`](../../references/source-rebuild.md)。该入口会路由到源码匹配、最小补丁位置、构建依赖、ABI/RPATH 验证和“不应安装”判定知识。

判断源码是否与当前系统包精确匹配时，先看本机二进制包版本：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' ukui-search libukui-search2 ukui-control-center
apt-cache policy ukui-search libukui-search2 ukui-control-center
apt-cache showsrc ukui-search 2>&1 | sed -n '1,80p'
```

如果本机没有配置 `deb-src`，`apt-cache showsrc` 会提示需要指定代码源，此时只能说明当前 apt 配置不能直接获取源码包，不等于上游社区没有源码。继续查 openKylin/Gitee tag：

```bash
git ls-remote --tags https://gitee.com/openkylin/ukui-search.git | rg '4\.21\.1\.0|4\.21\.1\.0-ok|build/4\.21'
git ls-remote --heads https://gitee.com/openkylin/ukui-search.git | rg 'openkylin|packaging|nile|huanghe|yangtze'
```

常见判断：

- `upstream/<version>` 表示上游基础源码版本。
- `build/<version>-ok...` 更接近发行版构建点，可能包含打包或下游补丁。
- 当前系统包如果带有更长的发行版后缀，例如 `<version>-ok0.1k0.22`，而公开 tag 只到 `build/<version>-ok0.1` 或 `build/<version>-ok0.6`，则不能直接断言该 tag 与本机二进制包完全一致。

如果只是希望临时使用不同搜索引擎，可考虑浏览器扩展或浏览器侧搜索重定向，但这不等同于在 UKUI 设置界面新增正式选项。

### 能否交给默认浏览器的默认搜索引擎

通常不能直接做到。UKUI 全局搜索的后端不是把“纯关键词”交给默认浏览器，而是先根据 `web-engine` 拼出完整搜索 URL，再让默认浏览器打开。例如：

```text
https://www.so.com/s?q=<keyword>
https://www.sogou.com/web?query=<keyword>
https://baidu.com/s?word=<keyword>
```

浏览器只有在地址栏收到纯文本查询时，才会使用自身默认搜索引擎；如果外部程序传入的是完整 `https://...` URL，浏览器默认搜索引擎不会参与。

可选变通方案：

- 浏览器侧重定向：安装重定向扩展，把 `baidu.com/s?word=...`、`sogou.com/web?query=...` 或 `so.com/s?q=...` 转到 Bing/Google。这不改 UKUI，但依赖浏览器扩展。
- 用户级默认浏览器拦截器：把默认浏览器改成一个用户级脚本，只拦截这几类搜索 URL 并转换后再调用真实浏览器。此方案会改变默认浏览器入口，影响面比浏览器扩展更大，需谨慎验证。
- 源码级修复：修改 UKUI 后端，让它支持 Bing/Google，或改成传纯关键词给浏览器/自定义搜索服务。这是最完整但成本最高的方案。

不建议通过改 `/etc/hosts`、DNS 劫持或二进制字符串替换来实现搜索引擎切换；前者处理不了 HTTPS 证书和路径参数，后者容易破坏 `libukui-search` 或控制中心插件。

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

## 源码级正式开关

如果用户明确要求在设置界面提供正式开关，而不是用户级 D-Bus workaround，应进入源码重编译流程：先读取 [`../../references/source-rebuild.md`](../../references/source-rebuild.md)，并把源码、构建目录、回滚包和 `CUSTOMIZATION.md` 放到 `/data/usershare/kylinos-local-sources/<component-or-fix>/`。

最小实现通常涉及 `ukui-search` 本体，不需要修改软件商店本体：

- `data/org.ukui.search.data.gschema.xml`
  - 新增布尔 key，例如 `software-center-search-enable`，默认 `false`。
- `search-ukcc-plugin/search.cpp` / `search.h`
  - 在全局搜索设置页新增开关。
  - 开关读写 `softwareCenterSearchEnable`。
- `libsearch/searchinterface/searchtasks/app-search-task.cpp`
  - 在调用 `com.kylin.softwarecenter.getsearchresults` 前读取 `softwareCenterSearchEnable`。
  - 开关关闭时不调用软件商店 D-Bus provider。

如果系统之前使用过用户级 D-Bus 覆盖：

```text
$HOME/.local/share/dbus-1/services/com.kylin.softwarecenter.getsearchresults.service
```

安装正式开关前应备份并移除该覆盖文件，再重载用户 D-Bus 配置。否则即使设置界面打开“搜索应用商店应用”，用户级覆盖仍可能把 provider 指向 `/bin/false`，导致正式开关无法重新启用商店结果。

安装后默认关闭：

```bash
gsettings set org.ukui.search.settings software-center-search-enable false
```

运行时刷新：

```bash
pkill -f /usr/bin/kylin-software-center-plugin-synchrodata 2>/dev/null || true
ukui-search --quit 2>/dev/null || true
ukui-search-service --quit 2>/dev/null || true
busctl --user call org.freedesktop.DBus /org/freedesktop/DBus org.freedesktop.DBus ReloadConfig
```

验证：

```bash
gsettings get org.ukui.search.settings software-center-search-enable
strings /usr/lib/*/libukui-search.so.* | rg 'softwareCenterSearchEnabled|com\.kylin\.softwarecenter'
strings /usr/lib/*/ukui-control-center/libsearch-ukcc-plugin.so | rg 'Search Software Store apps|softwareCenterSearchEnable'
busctl --user list | rg 'com.kylin.softwarecenter.getsearchresults|ukui.search' || true
```

预期：

- `software-center-search-enable` 默认为 `false`。
- 设置插件包含新开关字符串。
- 软件商店 provider 不应常驻；如果只是 `(activatable)`，说明它还没有被当前搜索主动拉起。
- 设置中打开该开关后，才允许全局搜索调用软件商店 provider。
