# References 路由说明

`references/` 是任务类型和场景分类的路由入口，不保存详细修复过程。

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
4. reference 内部再按子场景指向具体 knowledge 章节；不要一次性读取所有 knowledge。

## Fallback

- 修复类未命中细分场景：读取 `system-repair/system.md`。
- 增强类未命中细分场景：读取 `feature-enhancement/system.md`。
