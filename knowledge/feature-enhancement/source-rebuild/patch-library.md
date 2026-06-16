# 可复用源码 Patch 知识库

本文档定义通过本地修改源码包实现的系统修复或功能增强如何沉淀到 skill。DATA 工作区保存当前机器的源码、构建和回滚状态；skill 仓库保存可跨机器复用的功能 patch、上游来源和套用策略。

## 存放位置

每个功能级源码修改都必须在对应场景 knowledge 下保存 patch 集：

```text
knowledge/<system-repair|feature-enhancement>/<scenario>/patches/<feature-id>/
├── PATCHSET.md
└── *.patch
```

路径按“需求类型 -> 实际场景 -> patches -> 具体功能”组织：

- 系统修复类 patch 放到 `knowledge/system-repair/<scenario>/patches/<feature-id>/`。
- 功能增强类 patch 放到 `knowledge/feature-enhancement/<scenario>/patches/<feature-id>/`。
- 如果一个功能横跨多个源码包，在同一个 `<feature-id>/` 下按文件名或子目录区分源码包。

## PATCHSET.md 必备字段

每个 patch 集必须包含 `PATCHSET.md`，至少记录：

- 功能目标和需求类型。
- 上游仓库 URL。
- 源码包名和相关二进制包名。
- patch 基于的源码节点：commit hash、tag、branch 或发行版源码包版本。
- 当前验证过的系统包版本和架构。
- patch 文件列表及套用顺序。
- 已安装文件或预期影响的系统组件。
- 构建依赖、构建命令和安装前 ABI/RPATH/符号验证点。
- 运行时验证状态：`draft`、`build-verified`、`installed-pending-runtime-verification`、`runtime-verified`、`kept-for-future`。
- 后续系统包版本变化时的重新套用策略。

## 使用规则

不要假设 skill 中保存的 patch 能直接应用到任意系统版本。处理现场问题时必须先读取当前系统实际情况：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <binary-package>
apt-cache policy <binary-package>
zcat /usr/share/doc/<binary-package>/changelog.Debian.gz | sed -n '1,160p'
```

然后根据当前系统包版本下载或切换到对应源码：

```bash
git clone <upstream-repo>
git fetch --all --tags
git checkout <current-system-matched-node>
```

优先使用与当前系统二进制包精确匹配的发行版源码包或节点。只有确认没有精确源码包时，才使用公开上游仓库的最接近节点，并在 `CUSTOMIZATION.md` 和 `PATCHSET.md` 中标明“近似匹配”。

套用 patch 时按 `PATCHSET.md` 中的顺序执行：

```bash
git am <patch-file>
```

如果出现冲突，不要放弃，也不要盲目强行覆盖。必须自主分析当前源码与 patch 的语义差异，按以下顺序处理：

1. 阅读冲突文件、当前系统源码节点和 patch 原始意图。
2. 判断新版本是否已经包含同类功能；如果已经包含，记录替代实现，不再重复套用。
3. 如果新版本只改变了上下文或函数位置，手工迁移 patch 逻辑。
4. 如果接口、ABI、配置 schema 或 D-Bus 协议变化，重新设计最小补丁，不机械照搬旧实现。
5. 冲突解决后重新构建，并执行 ABI、RPATH/RUNPATH、NEEDED、导出符号和运行时验证。

冲突处理完成后必须导出新的 patch，并更新本地 DATA 工作区的 `CUSTOMIZATION.md`。如果新的 patch 具有通用复用价值，也要更新 skill 中对应 `PATCHSET.md` 和 patch 文件。

## 与 DATA 工作区的关系

DATA 工作区路径：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/
```

该目录保存当前机器的源码树、构建目录、回滚包、现场 patch 和 `CUSTOMIZATION.md`。skill 中的 patch 集保存可复用知识，不替代 DATA 工作区，也不保存当前机器一次性日志、用户名、临时路径或构建产物。

运行时验证通过后，必须同时维护两份索引：

- DATA 工作区 `CUSTOMIZATION.md`：记录当前机器实际源码、安装文件、回滚路径和验证证据。
- skill 中 `PATCHSET.md`：记录可复用 patch、上游仓库、基线节点、适用版本和迁移策略。
