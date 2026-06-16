# UKUI 全局搜索自定义命令与搜索结果增强 Patch 集

## 功能目标

- 在 UKUI 全局搜索中增加通用 `Command Search` provider。
- 支持用户级 `custom-commands.json` 配置自定义命令。
- 在 UKUI 控制中心全局搜索设置页增加“自定义命令”图形化配置入口。
- 增加软件商店搜索结果开关，默认不显示未安装应用。
- 保留 Bing/Google 搜索引擎定制。

## 类型与场景

- 需求类型：系统功能增强。
- 实际场景：UKUI 全局搜索。
- 知识入口：`knowledge/feature-enhancement/ukui/search-command-provider.md`。

## 上游与基线

- 上游仓库：`https://gitee.com/openkylin/ukui-search.git`
- 源码包：`ukui-search`
- 相关二进制包：`ukui-search`、`libukui-search2`、`ukui-control-center`
- 已验证系统包版本：`4.21.1.0-ok0.1k0.22`
- 本地验证基线：`origin/real-upstream`，commit `d06a0115`
- 本地功能分支：`codex/store-search-toggle`
- 最新本地功能 commit：`c93060ad1b3487ff34b7cc8cc9b1a7ddf698e878`
- 验证状态：`runtime-verified`

## Patch 顺序

按下面顺序套用：

```text
20260615-ukui-search-local-search-customizations.patch
20260615-ukui-search-custom-command-editor-ui.patch
20260616-ukui-search-async-command-icon-loading.patch
20260616-ukui-search-command-icon-selector-ui.patch
20260616-ukui-search-command-editor-theme-colors.patch
20260616-ukui-search-simplified-command-icon-picker.patch
20260616-ukui-search-command-icon-picker-controls.patch
20260616-ukui-search-enhance-custom-command-panel.patch
```

## 套用策略

现场修复时先确认当前系统包版本和源码节点，不要直接假设上述基线适用于所有系统：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' ukui-search libukui-search2 ukui-control-center
apt-cache policy ukui-search libukui-search2 ukui-control-center
zcat /usr/share/doc/ukui-search/changelog.Debian.gz | sed -n '1,160p'
```

然后获取当前系统对应源码：

```bash
git clone https://gitee.com/openkylin/ukui-search.git
cd ukui-search
git fetch --all --tags
git checkout <current-system-matched-node>
```

在匹配节点上按顺序执行：

```bash
git am <patch-file>
```

如果 `git am` 冲突，必须分析冲突文件和当前源码结构：

- 如果新版本已经内置软件商店结果开关、自定义命令或 Bing/Google 支持，记录现有实现并停止重复套用对应 patch。
- 如果只是函数位置、UI 结构或翻译文件上下文变化，按 patch 原始意图手工迁移。
- 如果 `libukui-search` 导出符号、schema、插件管理器或前端折叠逻辑发生变化，重新设计最小补丁并重新做 ABI/RPATH/符号验证。

冲突处理后重新导出 patch，并更新本目录 `PATCHSET.md`。

## 安装前验证

至少验证：

```bash
readelf -d <build>/libsearch/libukui-search.so.2.3.0 | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
readelf -d <build>/search-ukcc-plugin/libsearch-ukcc-plugin.so | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
nm -D --defined-only /usr/lib/<arch>/libukui-search.so.2.3.0 | awk '{print $3}' | sort > /tmp/system.syms
nm -D --defined-only <build>/libsearch/libukui-search.so.2.3.0 | awk '{print $3}' | sort > /tmp/new.syms
comm -23 /tmp/system.syms /tmp/new.syms
comm -13 /tmp/system.syms /tmp/new.syms
glib-compile-schemas --strict <schema-dir>
```

## 运行时验证

- 设置页全局搜索中存在软件商店搜索结果开关。
- 设置页全局搜索中存在“自定义命令”配置入口。
- 命令配置对话框能新增、复制、删除、单条保存命令。
- 图标选择不会阻塞设置界面。
- 深色/浅色主题下输入框、详情区和确认框可读。
- 全局搜索执行自定义命令后搜索框关闭。
- 需要确认的命令默认焦点在取消，Tab/方向键能切换焦点。
- `Command Search` 插件被注册，日志包含 `register search plugin: "Command Search"`。

## DATA 工作区映射

当前机器现场工作区：

```text
/data/usershare/kylinos-local-sources/ukui-search-store-toggle/
```

现场工作区用于保存源码树、构建状态和当前机器验证证据；本目录用于保存可复用 patch 知识。
