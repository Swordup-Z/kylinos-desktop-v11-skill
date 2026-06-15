# 图形与频率

## 定位

这是图形驱动、GPU/显示频率、`devfreq` 和硬件强相关稳定性问题的分类入口。

## 适用场景

- 日志中出现 `failed to set <driver> frequency`。
- 图形/频率相关卡死、异常或硬件探测噪声。
- 无 NVIDIA 硬件但反复探测 NVIDIA。

## 先读知识章节

- 图形频率和硬件相关处理：[`../knowledge/hardware/graphics-frequency.md`](../knowledge/hardware/graphics-frequency.md)

## 最小诊断

```bash
journalctl -b --no-pager | rg -i 'devfreq|gpu|drm|nvrm|nvidia|frequency|ftg|PHYT'
lspci 2>/dev/null || true
```
