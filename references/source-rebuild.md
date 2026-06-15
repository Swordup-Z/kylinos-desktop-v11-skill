# 源码重编译

## 定位

这是需要修改系统组件源码、重新构建系统二进制或评估 ABI 风险的问题分类入口。

## 适用场景

- 系统设置界面或后端逻辑写死，配置级方案无法满足需求。
- 需要替换系统共享库、控制中心插件或系统服务。
- 需要评估源码版本、候选 git 节点、ABI/SONAME/依赖/RPATH 风险。

## 先读知识章节

- 源码重编译通用流程：[`../knowledge/source-rebuild/README.md`](../knowledge/source-rebuild/README.md)
- UKUI 全局搜索搜索引擎修改：[`../knowledge/source-rebuild/ukui-search-web-engine.md`](../knowledge/source-rebuild/ukui-search-web-engine.md)

## 最小诊断

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <package>
apt-cache policy <package>
apt-cache showsrc <source-package> 2>&1 | sed -n '1,80p'
```
