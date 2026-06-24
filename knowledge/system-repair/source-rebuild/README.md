# 系统问题修复：源码重编译

当系统问题无法通过配置、服务或包状态修复，必须修改系统组件源码时，AI 工具先读取本文件确认修复边界。只继续读取与用户问题匹配的一个具体修复章节。

通用规则：

- 修复目标必须是已有能力异常、失效、报错、不能持久化或系统服务损坏。
- 如果目标是新增能力、改变默认行为或本地客制化，切换到 `$HOME/.os-enhance-skill/SKILL.md`。
- 源码、构建目录、staging、回滚包和符号对比文件优先放到 `/data/usershare/kylinos-local-sources/<component-or-fix>/`，不要占用根分区或 `$HOME` 临时目录。
- 可跨机器复用的修复 patch 放到本仓库对应修复场景的 `knowledge/system-repair/<scenario>/patches/<fix-id>/`。
- 安装构建依赖、替换系统文件或安装本地包前必须先检查维护模式。

与具体修复相关的源码章节放在对应场景下，例如：

- [`../ukui/system-tray-source.md`](../ukui/system-tray-source.md)
- [`../ukui/file-dialog-open-with.md`](../ukui/file-dialog-open-with.md)
