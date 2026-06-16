# References 路由说明

`references/` 是任务类型和实际场景的策略路由入口，不保存详细修复过程。

## 两类入口

- `system-repair/`：系统已有能力异常、失效、报错、不能持久化。
- `feature-enhancement/`：系统原本能工作，但需要新增能力、改变默认行为或做本地客制化。

两个目录使用相同场景文件名：

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

1. 先判断任务类型：修复还是增强。
2. 再判断场景：system、applications、ukui、network、hardware、storage、agent-tools 或 source-rebuild。
3. 只读取一个最小匹配 reference。
4. reference 只指向该场景的 knowledge 索引，不直接展开所有细分知识。
5. 进入 `knowledge/<type>/<scenario>/README.md` 后，只读取与用户问题匹配的具体章节；不要一次性读取整个场景目录。

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
-> references/<system-repair|feature-enhancement>/<scenario>.md
-> knowledge/<system-repair|feature-enhancement>/<scenario>/README.md
-> knowledge/<system-repair|feature-enhancement>/<scenario>/<topic>.md
```

只有 `README.md` 明确说明当前场景复用其他场景知识时，才跨场景读取；否则保持同类型、同场景路径。

## Fallback

- 修复类未命中细分场景：读取 `system-repair/system.md`。
- 增强类未命中细分场景：读取 `feature-enhancement/system.md`。
