# qt5-ukui-filedialog 打开方式应用列表过滤修复

## 元数据

- 需求类型：系统问题修复。
- 场景：UKUI 打开方式文件选择器。
- 功能目标：修复“打开方式 -> 选择其他应用”进入 `/usr/share/applications` 或用户 XDG Desktop 目录后应用 `.desktop` 条目被错误过滤的问题。
- 上游仓库：`https://gitee.com/openkylin/qt5-ukui-platformtheme.git`
- 源码包：`qt5-ukui-platformtheme`
- 相关二进制包：`qt5-ukui-platformtheme`、`libqt5-ukui-style1`
- 目标系统文件：`/usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so`
- 已验证系统包版本：`qt5-ukui-platformtheme 4.20.1.0-0k1.73`，`arm64`
- 基线节点：`38f92f57910f069ca7c4d7fb5748cb33695cdec3`，来自 `origin/openkylin/nile-sp2`
- 本地验证提交：
  - `6b964c54212b6ee4a714d06d5401ac4feef7965a`：修复系统应用目录 `.desktop` 过滤。
  - `cb76ea689d3eafa33abeb37dafb52cbb38489eea`：修复 XDG Desktop 目录 `.desktop` 过滤。
- 运行时验证状态：`runtime-verified`
- 验证结果：在保持系统原始 `libpeony` 的前提下，修复 `/usr/share/applications` 和 XDG Desktop 目录应用条目过滤后，“打开方式 -> 更多应用 -> 选择其他应用”中的真实应用和桌面图标均可见。

公开源码分支中的 changelog 版本可能和发行版包版本不完全一致。使用此 patch 前，必须重新根据当前系统包版本和二进制 ABI 做匹配；不要把上述基线节点机械套用到所有系统。

## Patch 顺序

1. [`0001-Fix-desktop-application-file-dialog-filtering.patch`](0001-Fix-desktop-application-file-dialog-filtering.patch)
2. [`0002-Handle-desktop-directory-application-filtering.patch`](0002-Handle-desktop-directory-application-filtering.patch)

## 补丁语义

该 patch 集只改变 UKUI 原生文件选择器在 `/usr/share/applications` 和用户 XDG Desktop 目录下处理 `*.desktop` 过滤的行为：

- `goToUri()` 完成目录切换后重新应用当前文件类型过滤。
- 当前目录为 `/usr/share/applications` 且过滤列表包含 `*.desktop` 时，清空传给 Peony 页面模型的名称过滤列表。
- 当前目录为 `QStandardPaths::DesktopLocation` 且过滤列表包含 `*.desktop` 时，同样清空传给 Peony 页面模型的名称过滤列表。
- 其他目录、mime 过滤和普通文件选择逻辑保持原行为。

这样可以避免 Peony 使用桌面文件本地化显示名去匹配 `*.desktop`，导致真实应用条目或用户桌面图标被隐藏。

## 适用前检查

```bash
mm-cli -s
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' qt5-ukui-platformtheme peony libpeony3 libqt5-ukui-style1
dpkg -S /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so
zcat /usr/share/doc/qt5-ukui-platformtheme/changelog.Debian.gz | sed -n '1,160p'
xdg-user-dir DESKTOP
sed -n '1,80p' "$HOME/.config/QtProject.conf" 2>/dev/null || true
```

如果当前不是维护模式，只能做诊断和源码准备；不要替换系统插件。

## 套用策略

在 DATA 工作区准备源码：

```bash
mkdir -p /data/usershare/kylinos-local-sources/<component-or-fix>
cd /data/usershare/kylinos-local-sources/<component-or-fix>
git clone https://gitee.com/openkylin/qt5-ukui-platformtheme.git
cd qt5-ukui-platformtheme
git fetch --all --tags
git checkout <matched-source-node>
```

先构建未修改基线并与系统插件比对：

```bash
eval "$(dpkg-buildflags --export=sh)"
cmake -S qt5-ukui-filedialog -B ../build-baseline \
      -DCMAKE_BUILD_TYPE=None \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=lib/aarch64-linux-gnu \
      -DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
      -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS"
cmake --build ../build-baseline -j"$(nproc)"
readelf -d ../build-baseline/libqt5-ukui-filedialog.so | rg 'NEEDED|SONAME|RUNPATH|RPATH'
readelf -d /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so | rg 'NEEDED|SONAME|RUNPATH|RPATH'
nm -D --defined-only ../build-baseline/libqt5-ukui-filedialog.so | c++filt | sort > /tmp/candidate.symbols
nm -D --defined-only /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so | c++filt | sort > /tmp/system.symbols
comm -3 /tmp/system.symbols /tmp/candidate.symbols
```

确认候选源码足够匹配后再套用 patch：

```bash
git am /path/to/0001-Fix-desktop-application-file-dialog-filtering.patch
git am /path/to/0002-Handle-desktop-directory-application-filtering.patch
cmake -S qt5-ukui-filedialog -B ../build-patched \
      -DCMAKE_BUILD_TYPE=None \
      -DCMAKE_INSTALL_PREFIX=/usr \
      -DCMAKE_INSTALL_LIBDIR=lib/aarch64-linux-gnu \
      -DCMAKE_C_FLAGS="$CFLAGS $CPPFLAGS" \
      -DCMAKE_CXX_FLAGS="$CXXFLAGS $CPPFLAGS" \
      -DCMAKE_SHARED_LINKER_FLAGS="$LDFLAGS"
cmake --build ../build-patched -j"$(nproc)"
```

## 冲突迁移

如果 `git am` 冲突：

1. 先判断新版本是否已经修复了 `/usr/share/applications` 和 XDG Desktop 目录下 `*.desktop` 名称过滤。
2. 如果函数名或文件位置变化，迁移三段语义：目录切换后重放过滤；只在应用 desktop 目录清空实际名称过滤；只在 XDG Desktop 目录清空实际名称过滤。
3. 如果 Peony 或文件选择器模型 API 变化，重新定位“显示名过滤”入口，不要直接移除所有 name filter。
4. 迁移后重新构建未修改基线和 patched 版本，并重复 ABI、依赖、符号、运行时验证。

## 安装与验证

首次替换系统插件前准备基线回滚包：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/rollback/<timestamp>/
```

安装后验证：

```bash
sha256sum /usr/lib/aarch64-linux-gnu/qt5/plugins/platformthemes/libqt5-ukui-filedialog.so <patched-lib>
journalctl --user --since '2 minutes ago' --no-pager | rg -i 'qt5-ukui-filedialog|peony|platformtheme|crash|error|failed' || true
```

运行时打开“打开方式 -> 选择其他应用”，确认 `/usr/share/applications` 下真实应用和图标可见；再点击快速访问里的“桌面”或进入 `xdg-user-dir DESKTOP`，确认用户桌面上的 `.desktop` 图标可见。

如果快速访问里的“桌面”仍不可见：

```bash
pgrep -af '[p]eony'
kill <peony-qt-desktop-pid> <peony-pid>
```

关闭已打开的文件选择器窗口并重新打开。改动 XDG 用户目录、`$HOME/.config/QtProject.conf` 或文件选择器插件后，旧 Peony/文件选择器进程可能仍保留旧的 `QStandardPaths::DesktopLocation` 或 shortcuts 缓存。

如果应用条目可见但图标仍为空，先重启 Peony/文件选择器相关进程或重新登录，再重新验证。不要直接套用 Peony 近似源码节点替换 `libpeony`；近似构建即使能通过简单图标探针，也可能导致 `peony-desktop` 反复重启和桌面卡顿。只有找到与系统包 ABI 高度匹配的源码节点并通过完整运行时验证，才允许单独沉淀 Peony patch。
