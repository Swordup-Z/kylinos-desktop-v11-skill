# 系统功能增强：UKUI 桌面

## 适用场景

- 增强 UKUI 全局搜索，例如添加 Bing/Google、自定义命令 provider、命令配置图形界面。
- 通过源码级客制化改变 UKUI 默认行为。
- 托盘、设置页、快捷键等系统功能的非故障类增强。

## 按子场景读取

- 全局搜索默认搜索引擎增强：[`../../knowledge/feature-enhancement/ukui/search-web-engine.md`](../../knowledge/feature-enhancement/ukui/search-web-engine.md)
- 全局搜索自定义命令 provider 和图形化配置：[`../../knowledge/feature-enhancement/ukui/search-command-provider.md`](../../knowledge/feature-enhancement/ukui/search-command-provider.md)
- 需要源码重编译、patch 保存或本地客制化索引：[`source-rebuild.md`](source-rebuild.md)

## 最小诊断

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' ukui-search
gsettings list-recursively org.ukui.search.settings 2>/dev/null || true
```
