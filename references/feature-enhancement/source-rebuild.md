# 系统功能增强：源码重编译

## 适用场景

- 系统设置界面或后端逻辑写死，需要源码级新增功能。
- 需要保存本地源码 commit、patch、构建清理策略和后续升级迁移路径。
- 例如 UKUI 全局搜索添加搜索引擎、自定义命令 provider 或设置页配置入口。

## 知识入口

进入源码重编译索引后，按“通用源码流程”“本地客制化索引”“组件级增强实现”选择具体知识；不要同时读取所有源码增强章节。

- [`../../knowledge/feature-enhancement/source-rebuild/README.md`](../../knowledge/feature-enhancement/source-rebuild/README.md)

## 最小诊断

```bash
dpkg-query -W -f='${binary:Package} ${Version} ${Source}\n' <package>
apt-cache policy <package>
test -d /data/usershare/kylinos-local-sources && find /data/usershare/kylinos-local-sources -maxdepth 2 -name CUSTOMIZATION.md -print
```
