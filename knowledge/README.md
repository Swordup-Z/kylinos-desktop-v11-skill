# Knowledge 结构说明

`knowledge/` 保存具体可复用系统修复知识，包括背景、诊断、修复步骤、验证、回滚和清理规则。

## 知识入口

- `system-repair/`：系统已有能力异常、失效、报错、不能持久化、安装失败或系统服务损坏的修复知识。

功能增强、本地客制化和默认行为调整已拆分到 `$HOME/.os-enhance-skill`。

场景分类：

```text
system/
applications/
ukui/
network/
hardware/
storage/
agent-tools/
source-rebuild/
```

## 渐进式披露

加载顺序：

```text
SKILL.md
-> references/system-repair/<scenario>.md
-> knowledge/system-repair/<scenario>/README.md
-> knowledge/system-repair/<scenario>/<topic>.md
```

`references/` 只做实际修复场景路由；场景 `README.md` 只做特定分类和具体实例索引；具体 `<topic>.md` 才记录处理过程。新增经验时先判断场景，再放入对应目录；如果没有合适章节，新建一个最小主题文件，并从同场景 README 链接过去。

通过源码修改实现的可复用修复，patch 集放在同场景目录下：

```text
knowledge/system-repair/<scenario>/patches/<fix-id>/PATCHSET.md
knowledge/system-repair/<scenario>/patches/<fix-id>/*.patch
```

只有需要在源码树中复用或迁移该功能时才读取 patch 集。

每次只读取最小必要链路。不要因为同一场景下存在多个主题文件，就把整个场景目录全部读入上下文。

## 章节要求

具体知识章节应尽量包含：

- 适用场景。
- 关键系统文件、服务、包名或源码位置。
- 先诊断、再修改、最后验证的流程。
- 持久化策略。
- 回滚或恢复方式。
- 中间产物清理规则。
- 不应继续操作的风险信号。

不要把一次性聊天过程、长篇日志、当前用户名或不可复用临时路径写入 knowledge；需要用户目录时使用 `$HOME`、`<user>`、`<component-or-fix>` 等占位符。
