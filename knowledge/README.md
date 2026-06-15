# 知识库结构

本目录用于记录 KylinOS Desktop V11 问题处理中的具体可复用知识。与 `references/` 的分工如下：

- `references/`：场景分类和路由入口，负责快速判断问题属于哪个方向、先读哪些知识章节、执行哪些最小诊断。
- `knowledge/`：具体知识章节，负责记录特定场景的背景、诊断路径、修复步骤、验证方法、回滚方案、清理规则和已知风险。

## 渐进式披露

处理问题时按以下顺序加载：

1. 读取 `SKILL.md` 判断大类。
2. 读取最小匹配的 `references/*.md`。
3. 只有 reference 明确指向某个知识章节，或问题需要对应深度处理时，才继续读取 `knowledge/<category>/<scenario>.md`。

不要一次性读取整个 `knowledge/` 目录。新增经验时也不要把一次性日志、聊天过程或临时路径写进知识库。

## 分类方式

`knowledge/` 按问题处理方式或组件域分目录，例如：

```text
knowledge/source-rebuild/
knowledge/system/
knowledge/applications/
knowledge/ukui/
knowledge/network/
knowledge/hardware/
knowledge/storage/
knowledge/agent-tools/
```

目录下应包含一个 `README.md` 说明该分类的通用流程；具体问题使用独立章节文件，例如：

```text
knowledge/source-rebuild/ukui-search-web-engine.md
```

## 章节要求

每个具体知识章节应尽量包含：

- 适用场景。
- 关键系统文件、服务、包名或源码位置。
- 先诊断、再修改、最后验证的流程。
- 持久化修复方式。
- 回滚方式。
- 清理中间产物的要求。
- 不应继续操作的风险信号。

如果某个问题只是分类入口或快速检查，不需要独立章节；保留在 `references/` 即可。如果某个 reference 已经变得很长，应把详细步骤抽取到 `knowledge/`，reference 只保留摘要、路由和最小诊断。
