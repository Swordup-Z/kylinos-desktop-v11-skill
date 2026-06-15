# KARE 与宿主机边界

## 定位

这是 KARE/Kaiming namespace、应用入口和宿主机路径不一致问题的分类入口。

## 适用场景

- 应用内 hostname 显示 `kare`。
- 开始菜单、固定项或桌面入口仍指向 KARE 应用。
- 从 KARE 环境误启动 UKUI 面板或系统工具。

## 先读知识章节

- KARE namespace、hostname、入口覆盖和恢复：[`../knowledge/applications/kare-namespace.md`](../knowledge/applications/kare-namespace.md)

## 最小诊断

```bash
hostname
ps -ef | rg -i '<app>|kare|kaiming' | rg -v rg || true
command -v <app-command> || true
```
