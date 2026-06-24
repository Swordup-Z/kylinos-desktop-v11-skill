# References 路由说明

`references/` 是系统修复场景的策略路由入口，不保存详细修复过程。

## 入口目录

`system-repair/` 用于系统已有能力异常、失效、报错、不能持久化、安装失败或系统服务损坏的场景。功能增强、本地客制化和默认行为调整已拆分到 `$HOME/.os-enhance-skill`。

场景文件名：

```text
system.md
applications.md
ukui.md
network.md
hardware.md
storage.md
agent-tools.md
source-rebuild.md
```

## 使用方式

1. 先确认任务属于系统修复，而不是功能增强。
2. 再判断场景：system、applications、ukui、network、hardware、storage、agent-tools 或 source-rebuild。
3. 只读取一个最小匹配 reference。
4. reference 只指向该场景的 knowledge 索引，不直接展开所有细分知识。
5. 进入 `knowledge/system-repair/<scenario>/README.md` 后，只读取与用户问题匹配的具体章节；不要一次性读取整个场景目录。

## 层级链路

固定链路如下：

```text
需求类型
-> 实际场景 reference
-> 特定分类/具体实例索引
-> 细分领域 knowledge
```

对应文件路径：

```text
SKILL.md
-> references/system-repair/<scenario>.md
-> knowledge/system-repair/<scenario>/README.md
-> knowledge/system-repair/<scenario>/<topic>.md
```

只有 `README.md` 明确说明当前场景复用其他场景知识时，才跨场景读取；否则保持同类型、同场景路径。

## Fallback

未命中细分场景时，读取 `system-repair/system.md`。
