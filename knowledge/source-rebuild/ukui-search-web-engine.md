# UKUI 全局搜索互联网搜索引擎源码级修改

## 适用场景

KylinOS Desktop V11 的 UKUI 全局搜索设置里，“默认互联网搜索引擎”只提供固定选项，用户希望新增 Bing、Google 等搜索引擎。该需求通常不能只靠 `gsettings` 完成，因为设置界面下拉框和后端 URL 映射都可能写死在二进制组件中。

先读取场景入口：[../../references/ukui-search.md](../../references/ukui-search.md)。

## 关键文件

本机常见二进制路径：

```text
/usr/lib/<arch>/ukui-control-center/libsearch-ukcc-plugin.so
/usr/lib/<arch>/libukui-search.so.2.3.0
```

常见源码位置：

```text
search-ukcc-plugin/search.cpp
libsearch/websearch/web-search-plugin.cpp
```

设置插件通常负责下拉框选项；`libukui-search` 后端通常负责把 `web-engine` 映射成实际 URL。

## 诊断

确认包版本和文件归属：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' ukui-search libukui-search2 ukui-control-center
dpkg -S /usr/lib/*/ukui-control-center/libsearch-ukcc-plugin.so /usr/lib/*/libukui-search.so.2.3.0 2>/dev/null
```

确认现有二进制是否已经支持目标搜索引擎：

```bash
strings /usr/lib/*/ukui-control-center/libsearch-ukcc-plugin.so | rg -n 'baidu|sougou|360|bing|google|Bing|Google'
strings /usr/lib/*/libukui-search.so* 2>/dev/null | rg -n 'baidu|sogou|www.so.com|bing|google|www.bing.com|www.google.com'
```

如果只有 gsettings 能写入 `web-engine=bing`，但后端没有 Bing URL 字符串，实际搜索仍可能走默认分支。

## 源码匹配

优先使用当前发行版的精确源码包：

```bash
apt-cache showsrc ukui-search 2>&1 | sed -n '1,120p'
```

如果当前 apt 未配置 `deb-src`，只能说明本机配置不能直接取源码；不要据此断言上游没有源码。可继续查公开上游 tag，但必须把公开 tag 视为“候选源码”，而不是精确来源：

```bash
git ls-remote --tags https://gitee.com/openkylin/ukui-search.git | rg '<version-pattern>'
```

公开 tag 与本机二进制包版本存在发行版后缀差异时，例如公开 tag 是 `build/<version>-ok0.1`，而本机包是 `<version>-ok0.1k0.22`，不能直接认为 ABI 完全一致。

不要只按公开 tag 名称判断源码是否存在。KylinOS 发行版包可能在公开 openKylin 基线版本上继续做发行版侧重打包，包版本后缀如 `k0.<n>` 可能不会出现在公开仓库 tag 或 `debian/changelog` 历史中。遇到这种情况，应先读取当前已安装包自带 changelog，再用其中的 BUG 编号、Change-Id、改动描述反查公开仓库提交：

```bash
zcat /usr/share/doc/<binary-package>/changelog.Debian.gz | sed -n '1,160p'
git log --all --format='%h %ai %D%n%s%n' -G '<bug-id>|<change-description>'
git log --all --format='%h %ai %D%n%s%n' --grep='<bug-id>|<keyword>' --extended-regexp
```

如果公开仓库中能找到对应修复提交，但公开分支的包版本已经推进到更高版本，应把它视为“候选补丁提交”或“回灌来源线索”，不能直接把该分支整体作为当前系统包的精确源码。精确源码仍应以发行版 `deb-src`、源码包归档或与当前二进制包版本完全对应的补丁集合为准。

## 最小源码修改

设置界面下拉框负责控制用户可见选项。新增或移除搜索引擎时，优先在这里调整 `insertItem` 列表。示例：

```cpp
m_webEngineFrame->mCombox->insertItem(0, QIcon("/usr/share/ukui-search/search-ukcc-plugin/image/baidu.svg"), tr("baidu"), "baidu");
m_webEngineFrame->mCombox->insertItem(1, QIcon("/usr/share/ukui-search/search-ukcc-plugin/image/bing.svg"), tr("Bing"), "bing");
m_webEngineFrame->mCombox->insertItem(2, QIcon("/usr/share/ukui-search/search-ukcc-plugin/image/google.svg"), tr("Google"), "google");
```

如果只是希望设置界面不再显示某些旧选项，不要删除系统包自带图标资源，也不要先改后端 URL 映射；从下拉框移除对应 `insertItem` 即可。保留后端旧分支能避免已有 `gsettings` 值或手工配置突然失效。移除前应先检查当前值，如果当前值正是即将隐藏的旧选项，先迁移到仍可见的默认值：

```bash
gsettings get org.ukui.search.settings web-engine
gsettings set org.ukui.search.settings web-engine baidu
```

后端 URL 映射需要新增分支，示例：

```cpp
} else if(m_webEngine == "bing") {
    address = "https://www.bing.com/search?q=" + m_keyWord;
} else if(m_webEngine == "google") {
    address = "https://www.google.com/search?q=" + m_keyWord;
}
```

这只是最小功能补丁；正式补丁还应同步翻译、图标和打包元数据。若只移除设置界面的可见选项，通常不需要修改后端 URL 映射。

新增设置下拉框选项时，如果原有选项都使用 `QIcon("<installed-resource-path>")`，不要使用空 `QIcon()` 作为长期方案。应同步添加可安装的图标资源，并确认构建系统会把资源安装到代码引用的路径。例如 `search-ukcc-plugin/CMakeLists.txt` 若通过 `file(GLOB IMG_FILES ./image/*)` 安装图标，则可把新增 SVG 放入源码的 `search-ukcc-plugin/image/`，试装时同步复制到：

```text
/usr/share/ukui-search/search-ukcc-plugin/image/
```

验证时同时检查插件二进制包含目标图标路径、系统资源文件存在且可读：

```bash
strings /usr/lib/<arch>/ukui-control-center/libsearch-ukcc-plugin.so | rg 'bing\.svg|google\.svg|Bing|Google'
ls -l /usr/share/ukui-search/search-ukcc-plugin/image/<engine>.svg
```

## 构建注意事项

不要盲目安装完整 `Build-Depends`。先模拟依赖影响，避免重新拉入用户已经卸载的系统组件：

```bash
apt-get -s install <dependency...>
```

本场景可能需要的构建依赖包括 Qt、UKUI/Kylin SDK、Xapian、Qt RemoteObjects、Qt LinguistTools 等。具体以当前源码和系统包为准。

如果使用 CMake 直接构建，必须避免产物携带构建目录 `RUNPATH`：

```bash
cmake -S <src> -B <build> \
  -DCMAKE_BUILD_TYPE=RelWithDebInfo \
  -DBUILD_TEST=OFF \
  -DCMAKE_SKIP_RPATH=ON \
  -DCMAKE_INSTALL_PREFIX=/usr \
  -DCMAKE_C_FLAGS="$(dpkg-buildflags --get CFLAGS)" \
  -DCMAKE_CXX_FLAGS="$(dpkg-buildflags --get CXXFLAGS)" \
  -DCMAKE_SHARED_LINKER_FLAGS="$(dpkg-buildflags --get LDFLAGS)"
```

## 安装前验证

先确认新产物包含目标逻辑：

```bash
strings <build>/libsearch/libukui-search.so.2.3.0 | rg -n 'www.bing.com|www.google.com|bing|google'
strings <build>/search-ukcc-plugin/libsearch-ukcc-plugin.so | rg -n 'Bing|Google|bing|google'
```

再对比系统库和新库：

```bash
readelf -d <build>/libsearch/libukui-search.so.2.3.0 | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
readelf -d /usr/lib/<arch>/libukui-search.so.2.3.0 | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
ldd <build>/libsearch/libukui-search.so.2.3.0

nm -D --defined-only /usr/lib/<arch>/libukui-search.so.2.3.0 | awk '{print $3}' | sort > /tmp/ukui-search.system.syms
nm -D --defined-only <build>/libsearch/libukui-search.so.2.3.0 | awk '{print $3}' | sort > /tmp/ukui-search.new.syms
comm -23 /tmp/ukui-search.system.syms /tmp/ukui-search.new.syms
comm -13 /tmp/ukui-search.system.syms /tmp/ukui-search.new.syms
```

对控制中心插件也执行同类检查。

## 不应安装的判定

出现以下情况时应停止，不要替换系统库：

- 直接 CMake 构建的 `libukui-search.so` 带有指向 `$HOME` 或构建目录的 `RUNPATH`。
- 新库和系统库导出符号存在非预期差异，尤其是系统库有而新库没有的公共符号。
- 公开上游 tag 与本机包版本不精确匹配。
- 只替换设置插件会显示 Bing/Google，但后端库没有 URL 映射；这会形成“界面有选项但实际搜索不生效”的半修复状态。

## 安装与回滚

优先构建 `.deb` 并通过包管理器安装，这样可被 `dpkg` 追踪。只有在确认 ABI 一致、依赖一致、无 RPATH、已有备份和回滚命令时，才考虑手动替换：

```bash
install -m 0644 <new-lib> /usr/lib/<arch>/...
```

手动替换前应备份原文件到带时间戳的系统路径，并记录所属包：

```bash
dpkg -S <system-file>
cp -a <system-file> <system-file>.bak.<timestamp>
```

验证失败时立即恢复备份。修复完成并验证后，退出维护模式并要求用户重启：

```bash
mm-cli -c -a
```

## 已验证经验

在一次 KylinOS Desktop V11 环境中，使用公开上游 `ukui-search` 的接近 tag 可以成功编译出包含 Bing/Google 字符串的产物，并可通过 `CMAKE_SKIP_RPATH=ON` 去掉构建目录 `RUNPATH`。但新 `libukui-search.so.2.3.0` 与系统现有库存在导出符号差异：系统库 1669 个导出符号，新库 1663 个；系统有而新库没有 20 个，新库有而系统没有 14 个。差异涉及构造函数签名、内部类方法和 `LogUtils` 命名空间变化。

在用户明确要求本地试装后，先保留 stripped 安装产物、未裁剪构建产物、系统原文件备份、校验和和 `restore.sh`，再替换以下两个文件：

```text
/usr/lib/<arch>/libukui-search.so.2.3.0
/usr/lib/<arch>/ukui-control-center/libsearch-ukcc-plugin.so
```

替换后执行 `ukui-search --quit` 立即触发：

```text
symbol lookup error: ukui-search: undefined symbol: UkuiSearch::LogUtils::messageOutput(...)
```

随后执行回滚脚本恢复原系统文件，`dpkg -V libukui-search2 ukui-search` 无输出，说明包文件校验恢复正常。结论是：公开上游接近 tag 可用于验证补丁位置和构建链路，但当前已确认不能替换本机系统库；必须寻找精确源码包或当前发行版对应补丁源。

进一步尝试将同一源码 tag 构建成完整 `.deb` 包，并以本地包集合方式从发行版版本 `<version>-ok0.1k0.22` 降级到公开 tag 版本 `<version>-ok0.1`。必须作为同源集合一起安装的运行时包包括：

```text
libchinese-segmentation-common
libchinese-segmentation1
libukui-search-common
libukui-search2
ukui-search-systemdbus
ukui-search-service
ukui-search
```

该整组降级可以避免“旧 `ukui-search` 加载新 `libukui-search`”导致的 `undefined symbol`，但前端启动时出现新的桌面协议兼容错误：

```text
wl_display#1: error 1: invalid method 3, object org_kde_kwin_blur#...
```

这说明公开 tag 版本的 `ukui-search` 前端和当前 KylinOS Desktop V11 的 UKUI/Wayland 组件仍不兼容。结论：不能通过整组降级到公开 tag 的方式解决当前系统；应回滚到发行版仓库版本，并继续寻找精确源码包或发行版补丁源。若试装过本地降级包，回滚后用以下方式确认恢复：

```bash
dpkg-query -W -f='${binary:Package} ${Version}\n' ukui-search ukui-search-service ukui-search-systemdbus libukui-search2 libukui-search-common libchinese-segmentation1 libchinese-segmentation-common
dpkg -V ukui-search ukui-search-service ukui-search-systemdbus libukui-search2 libukui-search-common libchinese-segmentation1 libchinese-segmentation-common
apt-mark showhold
```

`dpkg -V` 应无输出，相关包不应继续处于 hold 状态。

进一步核查公开源码仓库时，不要假设顶层构建文件一定声明包版本。`ukui-search` 这类组件的可见包版本通常主要来自 `debian/changelog`，而发行版二进制包可能只在本机 `/usr/share/doc/<binary-package>/changelog.Debian.gz` 中保留完整发行版后缀。通用做法是：

1. 读取当前已安装包 changelog，提取最新发行版版本、BUG 编号、Change-Id、改动描述和影响域。
2. 在公开仓库中用这些线索反查源码提交，而不是只查 tag 名称。
3. 对照二进制包实际安装文件，确认 changelog 中提到的文件或能力是否已经落到当前系统。

示例命令：

```bash
zcat /usr/share/doc/<binary-package>/changelog.Debian.gz | sed -n '1,160p'
git log --all --format='%h %ai %D%n%s%n' -G '<bug-id>|<change-id>|<change-description>'
git log --all --format='%h %ai %D%n%s%n' --grep='<bug-id>|<keyword>' --extended-regexp
dpkg -L <binary-package> | rg '<expected-file-or-feature>'
dpkg -S <expected-system-file>
```

如果公开仓库中能找到同一 BUG/Change-Id/改动描述对应的源码提交，只能说明公开仓库包含该修复的来源或回灌线索；不能直接说明公开分支整体就是当前系统包的精确源码。后续如需基于公开仓库修复当前系统，应优先构造“当前系统包基线 + 目标补丁”的候选源码，并通过 ABI/依赖验证收敛，而不是直接降级或整体切换到公开更高版本分支。

ABI 反推时，可把缺失 C++ 导出符号作为源码版本指纹。例如系统 `ukui-search` 前端如果依赖：

```text
UkuiSearch::LogUtils::messageOutput(QtMsgType, QMessageLogContext const&, QString const&)
```

而公开候选源码构建出的 `libukui-search.so` 只提供全局命名空间的 `LogUtils::messageOutput(...)`，则说明候选源码早于 `LogUtils` 纳入 `UkuiSearch` 命名空间的提交。公开仓库中该变化可用以下方式反查：

```bash
nm -D --undefined-only /usr/bin/ukui-search | c++filt | rg 'LogUtils|messageOutput'
nm -D --defined-only /usr/lib/<arch>/libukui-search.so.2.3.0 | c++filt | rg 'LogUtils|messageOutput'
git log --all --format='%h %ai %D%n%s%n' -G 'namespace UkuiSearch|messageOutput|LogUtils' -- libsearch/log-utils.h libsearch/log-utils.cpp
git describe --tags --contains <commit>
```

如果候选源码早于某个 ABI 迁移提交，替换后系统前端可能因为找不到当前系统依赖的 C++ 符号而失败。因此，C++ API 差异可以用于排除过早源码并给出候选提交下界，但仍需要结合包 changelog、BUG 编号、Change-Id 和其他二进制文件指纹来判断完整补丁集合。

候选源码可能包含当前系统尚未打包的后续稳定性修复。遇到这种情况，不要只按“符号数量不同”直接否定；先判断差异方向和影响面。若候选库相对系统库只多导出内部辅助符号，例如 SQLite 配置、日志、缓存或测试辅助类，而没有减少系统库已有公共符号，则属于“候选库是系统库导出符号的超集”的情况：

```text
system_only = 0
candidate_only > 0
```

这种情况不同于之前的缺符号风险；只要 `system_only` 为 0、`SONAME`/`NEEDED` 一致且无 `RPATH`/`RUNPATH`，可视为低于缺符号场景的 ABI 风险。但新增符号对应的源码变更仍要阅读，确认不是大范围架构迁移、运行协议变化或引入新运行时依赖。通用验证：

```bash
nm -D --defined-only /usr/lib/<arch>/libukui-search.so.2.3.0 | awk '{print $3}' | sort > /tmp/ukui-search.system.rawsyms
nm -D --defined-only <build>/libsearch/libukui-search.so.2.3.0 | awk '{print $3}' | sort > /tmp/ukui-search.patched.rawsyms
comm -23 /tmp/ukui-search.system.rawsyms /tmp/ukui-search.patched.rawsyms
comm -13 /tmp/ukui-search.system.rawsyms /tmp/ukui-search.patched.rawsyms | c++filt
readelf -d <build>/libsearch/libukui-search.so.2.3.0 | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
```

在候选基线上为 Bing/Google 做最小补丁后，应验证：

```bash
strings <build>/libsearch/libukui-search.so.2.3.0 | rg 'www\.bing\.com|www\.google\.com|bing|google'
strings <build>/search-ukcc-plugin/libsearch-ukcc-plugin.so | rg 'Bing|Google|bing|google'
LD_LIBRARY_PATH=<build>/libsearch timeout 5s /usr/bin/ukui-search --quit
```

若系统前端通过 `LD_LIBRARY_PATH` 加载本地新库执行 `--quit` 不再出现 `undefined symbol`，说明至少没有复现早期不匹配版本的 C++ 接口缺失问题。不要把本地构建过程中 `lupdate` 写回的 `.ts` 翻译文件噪声作为补丁内容；源码补丁应尽量只保留功能相关 C++ 变更。

只有完成上述本地验证后，才进入替换系统文件试运行阶段。试运行前必须先准备回滚机制，不要直接覆盖 `/usr` 下文件：

```text
local-test-package/
  staged/          # 将要安装到系统路径的 stripped 新产物
  original-build/  # 未裁剪构建产物，用于后续分析
  system-backup/   # 试装前复制出的系统原文件
  SHA256SUMS       # 新旧文件和回滚脚本校验和
  restore.sh       # 只恢复本次试装目标文件的回滚脚本
```

`restore.sh` 应只恢复本次替换的目标文件，例如：

```bash
install -m 0644 system-backup/libukui-search.so.2.3.0 /usr/lib/<arch>/libukui-search.so.2.3.0
install -m 0644 system-backup/libsearch-ukcc-plugin.so /usr/lib/<arch>/ukui-control-center/libsearch-ukcc-plugin.so
ldconfig
```

如果试装新增了原系统中不存在的资源文件，例如新增搜索引擎图标，回滚脚本也应删除这些新增文件，避免回滚后留下孤立资源：

```bash
rm -f /usr/share/ukui-search/search-ukcc-plugin/image/<engine>.svg
```

试装后立即执行最小验证：

```bash
sha256sum -c SHA256SUMS
sha256sum /usr/lib/<arch>/libukui-search.so.2.3.0 staged/libukui-search.so.2.3.0
sha256sum /usr/lib/<arch>/ukui-control-center/libsearch-ukcc-plugin.so staged/libsearch-ukcc-plugin.so
dpkg -V libukui-search2 ukui-search ukui-control-center
timeout 5s ukui-search --quit
journalctl --user --since '5 minutes ago' --no-pager | rg -i 'ukui-search|control-center|undefined symbol|segfault|core dumped|crash'
```

`dpkg -V` 在试装期间会报告被替换文件的校验差异，这是预期现象；关键是确认差异只来自本次替换的目标文件。验证控制中心设置插件时，可打开对应设置页后确认进程实际加载了目标插件：

```bash
pid=$(pgrep -n -f 'ukui-control-center')
rg 'libsearch-ukcc-plugin\.so' /proc/$pid/maps
```

一旦出现 `undefined symbol`、前端启动失败、控制中心插件加载失败或服务异常，立即运行 `restore.sh` 并再次执行 `dpkg -V` 确认系统文件恢复。
