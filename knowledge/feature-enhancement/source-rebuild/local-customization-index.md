# 本地源码客制化索引

本文档用于记录所有“通过本地修改系统组件源码并替换系统产物解决问题”的本机工作区索引规则。DATA 工作区记录当前机器的源码、构建、回滚和现场 patch；可跨机器复用的功能 patch 还必须同步放入 skill 的对应 knowledge 场景目录，例如 `knowledge/feature-enhancement/ukui/patches/<feature-id>/`。

## 适用场景

- 用户要求保留本地修改源码，方便后续继续迭代。
- 修复需要替换系统共享库、控制中心插件、系统服务或 schema。
- 同一个组件可能存在多次本地试装、回滚、正式保留和后续继续修改。
- 需要把源码、构建目录、回滚包和验证结果从聊天记录中抽离成可复用索引。

## 固定工作区

除必须由系统包管理器安装到默认系统路径的依赖组件外，源码、构建目录、staging、回滚包、符号对比文件和其他中间产物都应优先放到 DATA 分区共享目录：

```text
/data/usershare/kylinos-local-sources/
```

每个问题使用独立目录：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/
```

目录命名应体现组件和修复目标，例如：

```text
ukui-search-store-toggle
ukui-search-engine-options
ukui-panel-tray-persistence
```

不要把这类本地开发工作区放到 `$HOME`、桌面、下载目录或根分区临时目录；这样会挤占根分区，也不利于后续查找。

## 已有源码仓库的更新规则

如果本地客制化项目下已经存在源码仓库，后续系统包升级或需要重新匹配上游版本时，默认在现有仓库中原地更新，不删除目录、不重新完整下载：

```bash
git -C "/data/usershare/kylinos-local-sources/<component-or-fix>/<source-tree>" remote -v
git -C "/data/usershare/kylinos-local-sources/<component-or-fix>/<source-tree>" status -sb
git -C "/data/usershare/kylinos-local-sources/<component-or-fix>/<source-tree>" fetch --all --tags
```

原地更新前必须先确认工作树状态：

- 如果有未提交改动，先判断是否属于当前客制化修改；需要保留时先提交本地 commit 并导出 patch，再切换或合并新基线。
- 如果已有本地客制化 commit，不要直接 reset 或覆盖；优先基于新 tag/branch 新建分支，再用 `git am <patch>`、`git cherry-pick <local-commit>` 或人工迁移方式重放修改。
- 如果构建目录缓存过旧，可以清理或重建 `build/`，但不应删除源码仓库、`CUSTOMIZATION.md` 或 `patches/`。`rollback/` 是否保留取决于当前阶段和用户策略：试装阶段应至少有可回退安全网；功能已运行时验证且 commit/patch 已保存后，用户要求保持工作区轻量时可以清理。
- 只有源码目录损坏、远端来源错误、历史缺失导致无法 fetch，或用户明确要求重新下载时，才新建备用目录重新 clone；不要用删除旧目录再重新下载作为默认流程。

每次原地更新源码基线后，都要更新 `CUSTOMIZATION.md` 中的基线版本、当前分支或 commit、patch 套用状态、构建验证结果和回滚路径。

## 必备索引文件

每个本地源码客制化目录必须创建：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/CUSTOMIZATION.md
```

`CUSTOMIZATION.md` 是后续继续修改、回滚和判断系统差异的主索引。至少记录：

- 目标问题、期望行为和是否已经在系统中试装。
- 涉及的二进制包、源码包、关键系统文件和用户级配置文件。
- 源码来源、候选 git 节点、当前工作分支、精确匹配或近似匹配依据。
- 是否为本机客制化工作树；如果用户要求保留变更边界，可以在本地源码工作树提交 git commit，但不要 push 到上游或公开仓库。
- 本地客制化 commit 的 hash、导出的 patch 路径，以及后续系统包版本更新时的重新套用方式。
- 如果 patch 已沉淀到 skill，记录对应 `knowledge/<type>/<scenario>/patches/<feature-id>/PATCHSET.md` 路径。
- 修改过的源码文件、新增资源文件、安装到系统的目标文件。
- 构建命令、构建目录、构建依赖和构建失败后的处理记录。
- 安装前 ABI、SONAME、NEEDED、RPATH/RUNPATH、导出符号、关键字符串验证结果。
- 试装时间、staged 文件、系统备份、用户级覆盖备份和回滚脚本路径。
- 安装后验证结果、仍需用户重启或手工验证的项目。
- 当前阶段状态和状态证据。构建通过但未安装不能写成已修复；只能标记为 `build-verified` 或 `staged-for-install`。已安装但尚未完成真实功能验证时标记为 `installed-pending-runtime-verification`。只有真实系统加载新产物且用户场景验证通过后，才标记为 `runtime-verified`。其他状态可用 `draft`、`rolled-back`、`kept-for-future`。

示例结构：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/
├── CUSTOMIZATION.md
├── <source-tree>/
├── build/                 # 构建阶段产物，可按需重建
├── rollback/              # 试装安全网，可在验证通过并保存 patch 后按用户策略清理
│   └── <timestamp>/
│       ├── system-backup/
│       ├── user-backup/
│       ├── SHA256SUMS
│       └── restore.sh
├── patches/
│   └── <source-package>/
│       └── <timestamp>-<source-package>-<short-topic>.patch
└── notes/
```

`restore.sh` 必须和对应回滚包放在同一目录。重新生成 staged 文件、调整回滚脚本或补充备份后，必须重新生成并验证 `SHA256SUMS`。

## 本地 commit 与 patch 保留

本地源码客制化可以使用 git commit 固化修改边界，便于以后系统包升级后继续合并个性化功能；但该 commit 默认只属于当前机器的本地工作树，不应 push 到上游社区、发行版仓库或公开远端，除非用户明确要求发布。

迭代开发阶段不要急于提交。只要用户仍在验证 UI、交互、运行时行为或问题是否真正修复，本地源码修改应保持为未提交工作树状态；不要生成本地 commit，不要导出 patch，也不要把状态写成 `runtime-verified`。只有满足以下条件后，才执行 commit 和 patch 导出：

- 构建通过，并已完成安装前 ABI、RPATH/RUNPATH、依赖和关键字符串检查。
- 已在维护模式中试装到系统路径，且系统文件哈希与 staged 产物一致。
- 用户已经在真实桌面会话中确认目标行为符合预期，或已有可替代用户确认的明确运行时证据。
- 已确认没有新增阻塞问题，例如前端无法唤醒、持续高 CPU、弹窗卡住、核心功能回退等。

如果在验证过程中发现问题，应继续基于未提交工作树修改；已经误提交的本地 commit 应优先用非破坏方式撤回为未提交改动，例如 `git reset --mixed HEAD~1`，并删除误生成的 patch。不要把尚未验证通过的试验性 patch 留在 `patches/` 中作为后续迁移依据。

`patches/` 是保存本地修改源码的项目根目录下的目录，应与 `<source-tree>/`、`build/`、`rollback/` 同级，不要放进源码树内部。`patches/` 下再按源码包名分层，方便系统包版本更新后按源码包查找、重新套用和合并个性化功能。例如源码树是：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/<source-tree>/
```

源码包名是 `<source-package>` 时，patch 保存目录应是：

```text
/data/usershare/kylinos-local-sources/<component-or-fix>/patches/<source-package>/
```

源码包名优先从当前系统包元数据确认：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <binary-package>
```

验证通过后的流程：

```bash
git status -sb
git diff --stat
git add <changed-files>
git commit -m "<component>: <customization-summary>"
mkdir -p "/data/usershare/kylinos-local-sources/<component-or-fix>/patches/<source-package>"
git format-patch -1 HEAD --stdout > "/data/usershare/kylinos-local-sources/<component-or-fix>/patches/<source-package>/<timestamp>-<source-package>-<short-topic>.patch"
```

提交信息只描述实际功能变更，不写 AI 相关署名、协作生成信息或无关聊天上下文。导出的 patch 应保存在当前客制化项目根目录下的 `patches/<source-package>/`，不要放在源码树内部、`$HOME`、下载目录或临时目录。

生成 patch 后必须更新 `CUSTOMIZATION.md`：

- 记录本地 commit hash 和 patch 文件路径。
- 记录该 patch 基于哪个源码节点、系统包版本或候选 tag 生成。
- 记录 patch 是否已经安装到当前系统、对应回滚包路径或替代回滚方式，以及验证结果。
- 记录后续版本更新时的合并方式，例如先切到新源码节点，再尝试 `git am <patch>`；若冲突较多，则用 `git apply --reject <patch>` 辅助人工合并，最后重新构建、做 ABI/RPATH/符号验证和试装验证。

如果该 patch 实现的是可复用功能，而不是只对当前机器一次性有效的临时调试改动，还必须同步到 skill：

```text
knowledge/<system-repair|feature-enhancement>/<scenario>/patches/<feature-id>/
├── PATCHSET.md
└── <patch-files>
```

`PATCHSET.md` 必须写明上游仓库、基线节点、适用系统包版本、patch 顺序和冲突处理策略。后续在其他系统上使用时，必须根据现场系统包版本下载或切换到对应源码节点，再套用 patch；遇到冲突时自主分析当前源码差异并迁移补丁逻辑，不能机械覆盖或放弃。

系统包或上游源码更新后，不要直接复用旧构建产物。应重新拉取或切换到新源码节点，先确认新版本是否已经包含同类功能；如果没有，再用保存的 patch 重新套用或按 patch 内容手工迁移，并重复完整的构建、安装前验证、回滚安全网准备和安装后验证流程。

## 试装与回滚策略

迭代试装阶段优先维护一个“改动前基线回滚包”，不要每做一次小改就生成新的长期回滚包。基线回滚包应在首次替换系统文件前创建，保存原系统文件、`restore.sh` 和 `SHA256SUMS`；后续试验失败时统一恢复到这个基线版本。

后续小改的构建产物可以进入临时 staging 或当前试装目录用于安装验证，但不要把每次试验都沉淀为新的长期 `rollback/<timestamp>/`。只有以下情况才新建或长期保存新的回滚包：

- 替换目标文件集合发生变化，原基线回滚包无法覆盖新增或删除的系统文件。
- 已验证通过的本地定制需要作为新的长期运行版本保留，并且用户希望保留该版本的回滚入口。
- 要进入 A/B 验证，需要在官方基线和某个已验证本地版本之间来回切换。

如果需要复用既有回滚包的安装脚本进行试装，应明确区分“基线回滚包”和“试装 staging”。试装 staging 可以被覆盖或重建；基线回滚包中的 `system-backup/`、`restore.sh` 和 `SHA256SUMS` 不应被覆盖，避免失去回到改动前状态的能力。

功能已经完成运行时验证后，回滚包可以按用户偏好处理：

- 若用户希望保留“文件级快速回滚”，保留一个最小回滚包，只包含 `system-backup/`、`restore.sh` 和 `SHA256SUMS`，不要保留完整 build、staged 或 original-build。
- 若用户希望保持工作区轻量，并且源码 commit 与 patch 已保存，可以删除 `rollback/`、`build/`、staging、符号对比文件和其他中间产物；`CUSTOMIZATION.md` 必须同步说明当前不保留本地回滚包，后续回滚方式是通过包管理器恢复官方包，或从 `patches/<source-package>/` 重新构建安装。
- 回滚包目录应位于 DATA 工作区 `/data/usershare/kylinos-local-sources/<component-or-fix>/rollback/`，不要放到根分区、`/root`、`/tmp` 或用户下载目录。由于回滚包可能包含用提权命令复制的系统文件，文件所有者可能是 root；清理这类 root-owned 回滚包时可以用 `pkexec rm -rf <rollback-dir>`，但必须限定到明确的工作区回滚目录。

## 全局索引

如果 `/data/usershare/kylinos-local-sources/README.md` 不存在，应创建它作为全局索引。该文件只记录每个本地客制化项目的导航信息，不承载长篇补丁过程：

```text
# KylinOS Local Source Customizations

| Project | Scenario | Source packages | Source tree | Patch dirs | Status | Index |
| --- | --- | --- | --- | --- | --- | --- |
| <component-or-fix> | <short-scenario> | <source-package> | <source-tree>/ | patches/<source-package>/ | build-verified / staged-for-install / installed-pending-runtime-verification / runtime-verified | CUSTOMIZATION.md |
```

每次新增、试装、回滚、导出 patch、迁移本地源码客制化项目或确认系统包升级后的新基线时，都要同步更新全局索引和对应 `CUSTOMIZATION.md`。

## 渐进式披露与映射表

为了让后续维护者或 AI 工具快速查找，不要把所有细节写进全局索引。按三层组织：

1. 全局索引 `/data/usershare/kylinos-local-sources/README.md`：只记录项目级路由，包括项目目录、场景、源码包名、源码树、patch 目录、状态和 `CUSTOMIZATION.md` 链接。
2. 项目索引 `/data/usershare/kylinos-local-sources/<component-or-fix>/CUSTOMIZATION.md`：记录该项目的源码包到二进制包、patch、安装文件和回滚方式映射。
3. patch 文件和可选回滚包：只在需要重新套用、构建或回滚时再读取。

`CUSTOMIZATION.md` 中增加“源码包与 patch 映射”表：

```text
| Source package | Binary packages | Base version/tag | Source tree | Patch dir | Latest local commit | Latest patch | Stage | Evidence | Installed files | Rollback |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| <source-package> | <binary-package-list> | <version-or-tag> | <source-tree>/ | patches/<source-package>/ | <commit-or-none> | <patch-or-none> | build-verified | build + ABI checks passed, not installed | /usr/lib/... | rollback/<timestamp>/restore.sh 或 package-manager restore |
```

如果一个客制化项目涉及多个源码包，应在同一个项目根目录下按源码包拆分 patch 目录：

```text
patches/<source-package-a>/
patches/<source-package-b>/
```

查找时先读全局索引，确认项目和源码包；再读对应项目的 `CUSTOMIZATION.md`，确认 patch、基线版本、安装目标和回滚方式；最后才打开具体 patch、源码文件或可选回滚包。

全局索引和项目索引中的状态必须按阶段更新，不能提前确认。阶段含义：

- `draft`：还在分析或修改源码，没有完成构建。
- `build-verified`：构建成功，且 ABI/RPATH/依赖/符号等安装前检查通过，但尚未准备安装包。
- `staged-for-install`：已准备 staged 文件、安装脚本、回滚脚本和校验文件，但尚未写入系统路径。
- `installed-pending-runtime-verification`：已在维护模式中安装到系统路径，但还没有完成真实桌面会话、服务日志、重启/重登录等验证。
- `runtime-verified`：真实运行环境验证通过，可以描述为已修复。
- `rolled-back`：已经回滚到安装前状态。
- `kept-for-future`：没有安装或已不再使用，但源码、patch 或经验保留给后续参考。

## 中间产物忽略策略

本地源码客制化工作区应尽量让 `git status` 只显示真实源码修改。构建、配置、测试或打包过程中发现未跟踪的中间产物时，不要每次手工处理；应优先把稳定模式写入合适的 `.gitignore`，并把该规则保留在本地源码工作树中，减少后续重复清理。

忽略规则优先级：

- 源码仓库内部生成且不应提交的产物，写入 `<source-tree>/.gitignore`。
- 项目根目录下的本地构建、staging、临时包、符号对比、日志等产物，写入 `/data/usershare/kylinos-local-sources/<component-or-fix>/.gitignore`。
- 多个客制化项目都会出现的通用临时产物，可考虑写入 `/data/usershare/kylinos-local-sources/.gitignore`，但不要影响各项目必须保留的 `CUSTOMIZATION.md`、`patches/` 和用户明确要求长期保留的 `rollback/`。

常见可忽略模式包括：

```gitignore
build/
cmake-build-*/
.cache/
.lupdate/
.qm/
*.o
*.so
*.a
*.log
*.tmp
```

`.gitignore` 只对未跟踪文件生效。若构建工具改写的是已经被 git 跟踪的源码文件，例如翻译源 `.ts`、schema、资源清单或版本文件，不能只靠 `.gitignore` 解决；应优先调整构建目标或构建参数避免改写源码树。暂时无法避免时，不必在每次中间构建后都恢复这些噪声；只要构建产物能正常生成、试装和运行验证不依赖源码树干净状态，中间过程可以保留构建产生的已跟踪文件改动，避免重复清理浪费时间。

只有在以下场景才恢复已跟踪生成噪声：

- 怀疑最新源码改动没有被构建系统采纳，需要让 `git diff` 重新变清晰来排查。
- 准备做最终 diff 审查、commit、导出 patch 或更新 `CUSTOMIZATION.md`。
- 生成噪声影响后续构建、测试、合并、切换分支或补丁套用。
- 用户明确要求清理工作树。

恢复时用 `git checkout -- <tracked-generated-files>` 或等价非破坏方式恢复无关生成噪声，只保留真实功能修改。

如果预计构建过程会改写已跟踪文件，编译前可以先把确认属于本次功能修改的文件加入暂存区，用暂存区隔离真实改动和构建副作用：

```bash
git status -sb
git diff -- <real-source-files>
git add <real-source-files>
git diff --cached --stat
```

构建完成后再检查：

```bash
git diff --stat
git diff --cached --stat
```

此时未暂存区通常就是构建过程产生的噪声。中间验证阶段可以先不处理；需要最终整理时再逐项确认后恢复。恢复噪声时不要使用会丢失暂存区的破坏性命令，优先按文件恢复未暂存改动：

```bash
git checkout -- <tracked-generated-files>
```

验证期间可以保留暂存状态，但不要在用户确认真实运行效果前执行 `git commit` 或导出 patch。若后续还要继续修改同一文件，先确认暂存区和工作区差异，避免把未验证的新改动混入已暂存的构建候选。

## 保留与清理

- 用户明确要求后续继续修改时，保留源码树和必要构建目录；只清理重复构建缓存、下载缓存和不再需要的临时包。
- 如果问题已经通过官方包或配置级方案解决，且用户不需要保留源码，清理源码树和构建目录，只保留必要回滚记录或在 `CUSTOMIZATION.md` 标记为 `rolled-back`。
- 如果本地客制化修改已经正式安装并持续使用，回滚包是否长期保留按用户策略决定。需要文件级快速回滚时，保留最小回滚包；可继续留在项目目录 `rollback/<timestamp>/`，也可迁移到：

```text
/data/usershare/kylinos-local-sources/persistent-rollbacks/<component>/<timestamp>/
```

迁移后必须更新全局索引和 `CUSTOMIZATION.md` 中的回滚路径。若用户选择不保留本地回滚包，则清理 `rollback/` 后也必须更新索引，把回滚方式改为包管理器恢复官方包或从保存 patch 重新构建安装。

## 与 skill 知识库的关系

本地工作区保存“当前机器上实际源码、构建和回滚状态”；skill 仓库保存通用规则、可复用方法和可跨机器复用的功能 patch。不要把以下内容写入 skill：

- 当前用户专属绝对路径、用户名、一次性日志。
- 未泛化的聊天过程。
- 只对某一次构建有效的临时文件名。
- 未验证且不具备复用价值的本地补丁细节。

如果从本地客制化中抽象出通用经验，应写到对应 `knowledge/feature-enhancement/<scenario>/<topic>.md`、`knowledge/system-repair/<scenario>/<topic>.md` 或组件场景章节，并使用 `$HOME`、`<component-or-fix>`、`<timestamp>` 等占位符。功能级源码 patch 应放入对应场景的 `patches/<feature-id>/`，并通过 `PATCHSET.md` 说明上游仓库、基线节点和合入策略。
