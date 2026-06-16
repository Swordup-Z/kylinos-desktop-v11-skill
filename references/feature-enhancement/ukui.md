# 系统功能增强：UKUI 桌面

## 适用场景

- 增强 UKUI 全局搜索，例如添加 Bing/Google、自定义命令 provider、命令配置图形界面。
- 通过源码级客制化改变 UKUI 默认行为。
- 托盘、设置页、快捷键等系统功能的非故障类增强。

## 知识入口

进入 UKUI 增强索引后，按全局搜索搜索引擎、自定义命令 provider 或设置页图形化配置继续读取具体知识。

- [`../../knowledge/feature-enhancement/ukui/README.md`](../../knowledge/feature-enhancement/ukui/README.md)

## 最小诊断

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' ukui-search
gsettings list-recursively org.ukui.search.settings 2>/dev/null || true
```
