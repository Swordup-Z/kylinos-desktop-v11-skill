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

## 最小源码修改

设置界面下拉框需要新增选项，示例：

```cpp
m_webEngineFrame->mCombox->insertItem(3, QIcon(), tr("Bing"), "bing");
m_webEngineFrame->mCombox->insertItem(4, QIcon(), tr("Google"), "google");
```

后端 URL 映射需要新增分支，示例：

```cpp
} else if(m_webEngine == "bing") {
    address = "https://www.bing.com/search?q=" + m_keyWord;
} else if(m_webEngine == "google") {
    address = "https://www.google.com/search?q=" + m_keyWord;
}
```

这只是最小功能补丁；正式补丁还应同步翻译、图标和打包元数据。

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

在一次 KylinOS Desktop V11 环境中，使用公开上游 `ukui-search` 的接近 tag 可以成功编译出包含 Bing/Google 字符串的产物，并可通过 `CMAKE_SKIP_RPATH=ON` 去掉构建目录 `RUNPATH`。但新 `libukui-search.so.2.3.0` 与系统现有库存在导出符号差异：系统库 1669 个导出符号，新库 1663 个；系统有而新库没有 20 个，新库有而系统没有 14 个。差异涉及构造函数签名、内部类方法和 `LogUtils` 命名空间变化。结论是：公开上游接近 tag 可用于验证补丁位置和构建链路，但不能在 ABI 不一致时直接替换系统库。
