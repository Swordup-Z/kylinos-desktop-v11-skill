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

## 本地试装包要求

如果用户明确要求在 ABI 风险存在时进行本地试装，必须先准备可独立保存的本地试装包，至少包含：

- `staged/`：实际安装到系统路径的 stripped 产物。
- `original-build/`：未裁剪构建产物，便于后续分析。
- `system-backup/`：试装前复制出的系统原文件。
- `SHA256SUMS`：系统原文件、安装产物、原始构建产物的校验和。
- `restore.sh`：只恢复本次改动目标文件的回滚脚本。

试装后立即用最小命令验证动态链接是否正常，例如运行组件自身的 `--quit`、`--version`、插件加载命令或对应服务重启命令。若出现 `symbol lookup error`、`undefined symbol`、进程崩溃或服务无法启动，立即执行回滚脚本并再次验证系统包文件校验。

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
