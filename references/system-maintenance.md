# 系统维护

## 定位

这是 KylinOS Desktop V11 系统维护的基础分类入口。用于判断维护模式、安全边界、持久化修复和未覆盖问题的最小闭环。

## 适用场景

- 系统服务、系统包、设备节点、网络路由、系统路径、桌面环境、KARE/Kaiming、分区挂载、磐石架构、KSaf 策略或系统保护。
- 需要修改 `/usr`、`/etc`、`/opt`、`/dev`、systemd、系统包、分区或系统策略。
- 问题属于 KylinOS Desktop V11 桌面系统维护范围，但没有命中更具体分类。

## 先读知识章节

- 通用系统维护流程、维护模式、持久化修复和未覆盖问题闭环：[`../knowledge/system/system-maintenance.md`](../knowledge/system/system-maintenance.md)

## 最小诊断

```bash
mm-cli -s
uname -a
id
```

如果不是维护模式，只做诊断；系统级修改前先进入维护模式并重启。
