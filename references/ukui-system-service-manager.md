# UKUI System Service Manager

## 定位

这是 `ukui-system-service-manager.service` 启动异常、D-Bus 名称占用和持久化修复的分类入口。

## 适用场景

- `ukui-system-service-manager.service` timeout。
- `QDBusError("", "")`。
- `org.ukui.serviceManager` 被孤儿进程占用。
- 登录、唤醒或重启后 UKUI 面板/任务栏异常，同时日志出现 `com.ukui.search.qt.systemdbus` 或 `org.ukui.serviceManager` activation timeout。

## 先读知识章节

- 服务异常诊断和 D-Bus activation 修复：[`../knowledge/ukui/system-service-manager.md`](../knowledge/ukui/system-service-manager.md)

## 最小诊断

```bash
systemctl status ukui-system-service-manager.service --no-pager
systemctl show ukui-system-service-manager.service -p After -p Before -p WantedBy --no-pager
busctl --system list | rg 'ukui.serviceManager|serviceManager' || true
```
