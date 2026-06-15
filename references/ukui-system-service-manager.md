# UKUI System Service Manager

## 定位

这是 `ukui-system-service-manager.service` 启动异常、D-Bus 名称占用和持久化修复的分类入口。

## 适用场景

- `ukui-system-service-manager.service` timeout。
- `QDBusError("", "")`。
- `org.ukui.serviceManager` 被孤儿进程占用。

## 先读知识章节

- 服务异常诊断和 D-Bus activation 修复：[`../knowledge/ukui/system-service-manager.md`](../knowledge/ukui/system-service-manager.md)

## 最小诊断

```bash
systemctl --user status ukui-system-service-manager.service --no-pager
busctl --user list | rg 'ukui.serviceManager|serviceManager' || true
```
