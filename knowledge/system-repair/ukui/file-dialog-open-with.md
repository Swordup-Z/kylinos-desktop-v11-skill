# UKUI 打开方式文件选择器

可复用 patch 集保存在 [`patches/qt5-ukui-filedialog-openwith-applications/PATCHSET.md`](patches/qt5-ukui-filedialog-openwith-applications/PATCHSET.md)。只有确认配置、桌面文件和图标主题本身正常，但原生文件选择器仍过滤异常时才读取 patch 集。

## 适用场景

- Peony 或桌面右键文件，选择“打开方式 -> 选择其他应用”。
- 弹出的 UKUI 原生文件选择器进入 `/usr/share/applications` 后，只显示极少数 `.desktop` 文件，真实应用不可见。
- 应用列表恢复后如果仍没有图标，先重启相关 Peony/文件选择器进程并验证图标主题；不要直接替换 `libpeony`。

## 组件定位

关键包和文件：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' qt5-ukui-platformtheme peony libpeony3 libqt5-ukui-style1
dpkg -S /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so
zcat /usr/share/doc/qt5-ukui-platformtheme/changelog.Debian.gz | sed -n '1,120p'
find /usr/share/applications -maxdepth 1 -name '*.desktop' | head
```

常见目标：

```text
Source: qt5-ukui-platformtheme
Plugin: /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so
Open-with desktop dir: /usr/share/applications
```

公开源码候选：

```bash
git clone https://gitee.com/openkylin/qt5-ukui-platformtheme.git
```

如果发行版没有公开精确源码包，不要只凭 tag 名称或 changelog 版本相近就替换系统插件；必须先构建未修改候选版本，并用 `readelf`、`nm`、导出符号集合和 `NEEDED` 依赖证明候选源码足够匹配。

## 根因判断

UKUI 原生文件选择器把 `Desktop files (*.desktop)` 之类的名称过滤传给 Peony 页面模型。Peony 在 `/usr/share/applications` 下显示的是桌面文件的本地化应用名，而不是原始文件名，所以 `*.desktop` 无法匹配真实应用的显示名，导致列表看起来像只剩个别服务类 desktop 文件。

另一个触发点是文件类型过滤可能早于最终目录切换完成。即使修复了过滤规则，也要在 `goToUri()` 完成目录切换后重新应用当前文件类型过滤，否则对话框仍可能保留旧目录或旧模型状态下的过滤结果。

## 最小补丁思路

优先只处理 `/usr/share/applications` 下的 `.desktop` 选择场景，避免影响普通文件选择器行为：

1. 在 `KyNativeFileDialog::goToUri()` 完成页面目录切换后，重新调用当前文件类型过滤逻辑。
2. 在 `KyNativeFileDialog::selectNameFilterCurrentIndex()` 中取得当前目录。
3. 如果当前目录规范化后等于 `/usr/share/applications`，且过滤列表包含 `*.desktop`，则只对传给 Peony 的实际名称过滤列表清空。
4. 其他目录、mime 过滤、目录选择模式和普通文件选择保持原逻辑。

不要把 `/usr/share/applications` 下所有图标问题都归因于本补丁。如果应用条目已经可见但图标为空，应先验证：

```bash
awk -F= '/^Name=|^Icon=/{print FILENAME ":" $0}' /usr/share/applications/<desktop-id>.desktop
gtk-update-icon-cache -q /usr/share/icons/<theme> 2>/dev/null || true
```

如果系统里已有经过验证的 `qt5-ukui-filedialog` 补丁，但旧的 `peony-qt-desktop`、`peony` 或文件选择器进程仍持有旧状态，可能出现“列表恢复但图标仍不显示”的假象。此时优先重启相关进程或重新登录后再验证：

```bash
pgrep -af '[p]eony|[u]kui-panel'
kill <peony-qt-desktop-pid>
```

`peony-qt-desktop` 通常会被会话管理器自动拉起。重启后重新打开“打开方式 -> 更多应用 -> 选择其他应用”，确认应用列表和图标是否同时可见。

## Peony 图标链路风险

Peony 的 `FileInfo::getIcon()` 也会影响 `.desktop` 图标解析，但不要把它作为默认修复点。公开源码仓库中可能能找到带有“打开方式更多应用图标空白”相关修复的提交，但发行版包未必公开精确源码节点；近似节点即使探针能解析 `Icon=`，仍可能因为 ABI、导出符号、运行时行为或构建选项差异导致 `peony-desktop` 反复重启、桌面卡顿。

只有同时满足以下条件，才允许考虑替换 `libpeony`：

1. 找到与当前系统包版本高度匹配的源码节点，而不是只看 tag 或 changelog 名称。
2. 未修改基线构建出的 `libpeony` 与系统库的 `NEEDED`、`SONAME`、导出 API、插件未定义符号引用都能解释清楚。
3. patched 构建通过同样 ABI 检查，并准备好唯一基线回滚包。
4. 先做运行时试装，观察 `peony-qt-desktop` 是否稳定，不反复重启、不造成桌面卡顿。

如果试装后出现桌面卡顿、`peony-desktop` 反复启动、CPU 持续升高或日志反复出现 `app-peony-desktop` scope，应立即回滚系统原始 `libpeony`，终止旧 Peony 进程，让会话重新拉起：

```bash
pkexec /data/usershare/kylinos-local-sources/<component-or-fix>/rollback/<baseline>/restore.sh
kill <peony-qt-desktop-pid>
sha256sum /usr/lib/aarch64-linux-gnu/libpeony.so.3.2.2 <rollback-lib>
```

这类失败候选不要保存为可复用 patch；只能记录为风险、排除路径和后续匹配源码时的验证要求。

## 构建与试装

源码、构建目录、patch 和回滚包应放在 DATA 分区共享工作区：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/
```

构建前先确认维护模式和系统包版本；系统级安装只允许在维护模式中执行：

```bash
mm-cli -s
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' qt5-ukui-platformtheme
```

构建示例：

```bash
eval "$(dpkg-buildflags --export=sh)"
cmake -S /data/usershare/kylinos-local-sources/<component-or-fix>/qt5-ukui-platformtheme/qt5-ukui-filedialog \
      -B /data/usershare/kylinos-local-sources/<component-or-fix>/build \
      -DCMAKE_BUILD_TYPE=None \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=lib/aarch64-linux-gnu \
      -DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
      -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS"
cmake --build /data/usershare/kylinos-local-sources/<component-or-fix>/build -j"$(nproc)"
```

安装前至少检查：

```bash
readelf -d <new-lib> | rg 'NEEDED|SONAME|RUNPATH|RPATH'
readelf -d /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so | rg 'NEEDED|SONAME|RUNPATH|RPATH'
nm -D --defined-only <new-lib> | c++filt | sort > /tmp/new.symbols
nm -D --defined-only /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so | c++filt | sort > /tmp/system.symbols
comm -3 /tmp/system.symbols /tmp/new.symbols
```

`comm -3` 应为空或只出现已解释的、不会破坏加载的差异。若导出符号、`NEEDED` 或 RPATH/RUNPATH 差异无法解释，不要替换系统插件。

## 验证

安装后重启相关应用或重新打开“选择其他应用”对话框，验证：

1. 对话框进入 `/usr/share/applications`。
2. 真实应用条目可见，不再只显示少数服务类 `.desktop`。
3. 应用图标能正常显示；若图标为空，先重启 Peony/文件选择器进程并检查桌面文件 `Icon=` 与图标主题。
4. `journalctl --user --since '2 minutes ago' --no-pager` 中没有新的 `qt5-ukui-filedialog`、Peony 或 Qt 平台主题崩溃日志。

## 回滚

首次替换系统插件前必须保存原文件和同目录 `restore.sh`：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/rollback/<timestamp>/
```

回滚后重新验证系统包状态：

```bash
pkexec /data/usershare/kylinos-local-sources/<component-or-fix>/rollback/<timestamp>/restore.sh
dpkg -V qt5-ukui-platformtheme || true
```
