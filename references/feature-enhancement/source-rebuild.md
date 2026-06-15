# 系统功能增强：源码重编译

## 适用场景

- 系统设置界面或后端逻辑写死，需要源码级新增功能。
- 需要保存本地源码 commit、patch、构建清理策略和后续升级迁移路径。
- 例如 UKUI 全局搜索添加搜索引擎、自定义命令 provider 或设置页配置入口。

## 按子场景读取

- 源码重编译通用流程：[`../../knowledge/feature-enhancement/source-rebuild/README.md`](../../knowledge/feature-enhancement/source-rebuild/README.md)
- 本地源码客制化索引、commit、patch、构建清理：[`../../knowledge/feature-enhancement/source-rebuild/local-customization-index.md`](../../knowledge/feature-enhancement/source-rebuild/local-customization-index.md)
- UKUI 全局搜索搜索引擎增强：[`../../knowledge/feature-enhancement/ukui/search-web-engine.md`](../../knowledge/feature-enhancement/ukui/search-web-engine.md)
- UKUI 全局搜索自定义命令增强：[`../../knowledge/feature-enhancement/ukui/search-command-provider.md`](../../knowledge/feature-enhancement/ukui/search-command-provider.md)

## 最小诊断

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <package>
apt-cache policy <package>
test -d /data/usershare/kylinos-local-sources && find /data/usershare/kylinos-local-sources -maxdepth 2 -name CUSTOMIZATION.md -print
```
