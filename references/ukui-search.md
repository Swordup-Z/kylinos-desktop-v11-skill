# UKUI 全局搜索

## 定位

这是 UKUI 全局搜索结果来源、软件商店结果、互联网搜索引擎设置和源码级扩展的分类入口。

## 适用场景

- 全局搜索出现软件商店未安装应用。
- 需要屏蔽软件商店搜索 D-Bus 提供者。
- 默认互联网搜索引擎选项写死，需要新增或隐藏选项。

## 先读知识章节

- 全局搜索结果来源和软件商店结果屏蔽：[`../knowledge/ukui/search.md`](../knowledge/ukui/search.md)
- 如果需要源码级修改搜索引擎：[`../knowledge/source-rebuild/README.md`](../knowledge/source-rebuild/README.md)，再读 [`../knowledge/source-rebuild/ukui-search-web-engine.md`](../knowledge/source-rebuild/ukui-search-web-engine.md)

## 最小诊断

```bash
gsettings list-recursively org.ukui.search.settings
strings /usr/lib/*/ukui-control-center/libsearch-ukcc-plugin.so | rg -n 'baidu|sougou|360|bing|google' || true
```
