# 系统体检噪声清理

## 定位

这是系统体检后“非核心故障但会污染日志或健康检查结果”的分类入口。

## 适用场景

- `motd-news.service`、系统公告或新闻服务不需要。
- PAM 引用缺失模块、rsyslog 旧式配置、坏 timer 链接等低风险噪声。
- 全盘体检后需要区分真实故障和可清理噪声。

## 先读知识章节

- 系统噪声清理步骤和验证：[`../knowledge/system/system-health-noise.md`](../knowledge/system/system-health-noise.md)

## 最小诊断

```bash
systemctl --failed --no-pager
journalctl -p warning..alert -b --no-pager | tail -n 120
```
