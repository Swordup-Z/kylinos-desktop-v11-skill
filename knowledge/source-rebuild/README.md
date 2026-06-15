# 源码重编译知识库

本目录记录 KylinOS Desktop V11 上“需要重新编译系统源码包或替换系统二进制才能解决”的问题。这里不记录普通应用安装经验，也不记录一次性现场日志；普通安装问题应放到 `references/application-installation.md`，系统级通用边界放到 `references/system-maintenance.md`。

## 适用场景

- 系统设置界面或后端逻辑写死，无法通过 gsettings、D-Bus、配置文件或用户级覆盖实现需求。
- 需要修改 UKUI、Kylin 系统组件、共享库、控制中心插件或系统服务源码。
- 需要评估公开上游源码、发行版源码包、本机二进制包之间是否精确匹配。
- 需要构建、验证、安装或回滚本地补丁包。

## 子分类

- UKUI 全局搜索默认互联网搜索引擎源码级修改：读取 [ukui-search-web-engine.md](ukui-search-web-engine.md)。

后续新增源码重编译问题时，按组件或场景新增文件，例如：

```text
knowledge/source-rebuild/<component-or-scenario>.md
```

## 通用安全流程

1. 先读取具体场景 reference，确认没有配置级、用户级或服务级的低风险方案。
2. 检查维护模式：

```bash
mm-cli -s
```

只有需要安装构建依赖、写系统路径、替换系统库或安装本地包时才要求 maintain mode；纯源码阅读、构建目录编译和 ABI 对比可以先诊断。

3. 确认本机包版本和来源：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <package>
apt-cache policy <package>
apt-cache showsrc <source-package> 2>&1 | sed -n '1,120p'
```

4. 优先使用精确源码包。仅在确认没有精确源码包，且用户明确接受风险时，才尝试公开上游最接近 tag。
5. 构建前避免全量安装 `Build-Depends` 带入不需要的系统组件；先用模拟安装检查依赖影响：

```bash
apt-get -s install <build-dependency...>
```

6. 构建产物安装前必须验证：

```bash
readelf -d <new-binary> | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
readelf -d <system-binary> | rg 'NEEDED|SONAME|RUNPATH|RPATH|FLAGS'
ldd <new-binary>
nm -D --defined-only <new-binary>
nm -D --defined-only <system-binary>
strings <new-binary> | rg '<expected-change>'
```

7. 看到以下任一情况时，不要直接替换系统库：

- 新产物带有指向构建目录或用户目录的 `RUNPATH`/`RPATH`。
- `SONAME` 与系统库不一致。
- `NEEDED` 依赖集合明显变化，尤其引入未确认的系统组件。
- 共享库导出符号相对系统库有非预期缺失或签名变化。
- 公开源码 tag 与本机二进制包版本不精确匹配。

符号差异不只看数量。即使差异数量不大，只要出现系统库已有公共符号在新库中消失、构造函数/方法签名变化、命名空间变化或全局静态符号变化，也应视为不能直接替换系统库的风险信号。

8. 如果决定安装，优先构建 `.deb` 并通过包管理器安装；只有在明确记录备份、回滚和验证步骤后，才考虑手动替换单个系统文件。
9. 安装后验证功能、服务状态和日志；确认可回滚后再退出维护模式：

```bash
mm-cli -c -a
```

随后要求用户重启回到 normal mode。

## 源码获取与候选节点收敛

源码入口按可信度排序：

1. 当前发行版 `deb-src` 或源码包归档。这是最优先来源，因为它应与本机二进制包版本和补丁集合对应。
2. 已安装包自带 changelog、copyright、包元数据中指向的上游仓库。
3. openKylin/Gitee 上游仓库，例如：

```bash
git clone https://gitee.com/openkylin/<source-package>.git
```

公开上游仓库只能作为候选来源，不能因为 tag 名称相近就直接认定为本机包精确源码。收敛候选节点时按“模糊线索 -> 精确比对”推进：

1. 从本机提取线索：

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <binary-package>
zcat /usr/share/doc/<binary-package>/changelog.Debian.gz | sed -n '1,160p'
dpkg -L <binary-package>
```

2. 在源码仓库中用版本号、BUG 编号、Change-Id、提交描述、关键文件名做模糊匹配：

```bash
git log --all --format='%h %ai %D%n%s%n' --grep='<bug-id>|<keyword>' --extended-regexp
git log --all --format='%h %ai %D%n%s%n' -G '<change-id>|<function-name>|<expected-file>'
git branch -a --contains <candidate-commit>
git tag --contains <candidate-commit>
```

3. 对候选节点做精确比对：

```bash
git checkout <candidate-commit>
dpkg -S <system-file>
readelf -d <candidate-output> | rg 'NEEDED|SONAME|RUNPATH|RPATH'
nm -D --defined-only <system-binary> | awk '{print $3}' | sort > /tmp/system.syms
nm -D --defined-only <candidate-output> | awk '{print $3}' | sort > /tmp/candidate.syms
comm -23 /tmp/system.syms /tmp/candidate.syms
comm -13 /tmp/system.syms /tmp/candidate.syms | c++filt
strings <candidate-output> | rg '<expected-feature>|<known-system-string>'
```

可接受的候选通常满足：`SONAME` 一致、`NEEDED` 未引入未确认依赖、无构建目录 `RPATH`/`RUNPATH`、系统已有导出符号没有缺失、关键字符串和系统二进制行为相符。若候选只比系统多少量内部辅助符号，应继续阅读新增符号对应源码，确认不是架构迁移或协议变化。

如果候选节点不匹配，不要反复在同一失败点硬试。按失败类型继续推进：

- 缺少系统前端依赖的 C++ 符号：候选源码过早，沿包含该符号迁移的提交之后继续找。
- 新库缺少系统库已有导出符号：停止替换，继续寻找更接近的节点或精确源码包。
- 整组降级后出现桌面协议或运行时错误：说明公开旧版本与当前桌面栈不兼容，应回滚，不要继续降级。
- 只多出少量内部辅助符号：阅读对应提交，若是稳定性修复且依赖不变，可作为较低风险候选继续验证。

## 构建失败后的继续尝试

构建失败时先分类，不要直接全量安装依赖或切换大版本：

- `CMake` 找不到包：用 `apt-cache search`、`apt-file search` 或 `dpkg -S` 反查开发包；先 `apt-get -s install <package>` 模拟依赖影响。
- 头文件或库缺失：优先安装最小 `-dev` 包，不要一次性安装完整桌面元包。
- 构建目录缓存污染：删除构建目录后用相同源码重新配置，不要修改源码绕过依赖检查。
- `RPATH`/`RUNPATH` 指向构建目录：重新配置 `CMAKE_SKIP_RPATH=ON`，不要安装带用户目录路径的产物。
- 翻译工具 `lupdate` 改写 `.ts`：构建后恢复无关翻译源噪声，只保留功能相关源码和资源变更。
- 链接成功但运行失败：保留日志和符号差异，回到候选节点收敛，不要直接扩大替换范围。

每次重试都应只改变一个变量：源码节点、构建参数、依赖集合或补丁内容。重试成功后再进入 ABI/依赖/RPATH 和回滚验证。

## 本地试装包要求

如果用户明确要求在 ABI 风险存在时进行本地试装，必须先准备可独立保存的本地试装包，至少包含：

- `staged/`：实际安装到系统路径的 stripped 产物。
- `original-build/`：未裁剪构建产物，便于后续分析。
- `system-backup/`：试装前复制出的系统原文件。
- `SHA256SUMS`：系统原文件、安装产物、原始构建产物的校验和。
- `restore.sh`：只恢复本次改动目标文件的回滚脚本。

`staged/` 中的共享库应尽量接近发行版安装形态。若直接构建产物包含调试符号，应先复制到 `staged/` 后执行 `strip --strip-unneeded`，保留未裁剪版本在 `original-build/` 中用于后续分析。重新生成 `staged/` 或修改 `restore.sh` 后，必须重新生成并验证 `SHA256SUMS`。

试装后立即用最小命令验证动态链接是否正常，例如运行组件自身的 `--quit`、`--version`、插件加载命令或对应服务重启命令。若出现 `symbol lookup error`、`undefined symbol`、进程崩溃或服务无法启动，立即执行回滚脚本并再次验证系统包文件校验。

## 构建产物清理

源码重编译验证完成后，应主动清理中间产物，不要把源码 clone、构建目录、完整本地试装包、未裁剪构建产物长期留在用户目录。清理前先确认以下条件：

- 已完成安装后验证，或已经回滚到系统原状态。
- 仍处于手动替换系统文件状态时，至少保留最小回滚备份。
- 最小回滚备份包含 `system-backup/`、`restore.sh` 和 `SHA256SUMS`，不包含 `staged/`、`original-build/`、完整源码树或构建目录。
- `restore.sh` 已覆盖本次所有系统级改动：恢复被替换的文件，并删除本次新增但原系统不存在的资源文件。

推荐把最小回滚备份移动到用户级固定位置，例如：

```text
$HOME/.local/share/kylinos-desktop-v11-skill/rollback/<component>-<timestamp>/
```

再删除纯中间产物：

```bash
rm -rf "$HOME/<source-clone-dir>" "$HOME/<build-worktree-dir>" "$HOME/<local-test-package-dir>"
```

清理后验证：

```bash
test ! -e "$HOME/<source-clone-dir>"
test ! -e "$HOME/<build-worktree-dir>"
du -sh "$HOME/.local/share/kylinos-desktop-v11-skill/rollback/<component>-<timestamp>"
sha256sum -c "$HOME/.local/share/kylinos-desktop-v11-skill/rollback/<component>-<timestamp>/SHA256SUMS"
```

如果已经改为 `.deb` 安装且包管理器可完整回滚，可不保留用户级回滚备份；但必须记录可执行的包管理器回滚命令。

## 记录要求

每个源码重编译知识文件至少包含：

- 适用场景。
- 对应本机包和关键文件。
- 源码匹配判断方法。
- 最小补丁位置。
- 构建依赖和避免误装的注意事项。
- 安装前 ABI/依赖/RPATH 验证。
- 安装、验证和回滚方案。
- 已知风险和“不应安装”的判定条件。
