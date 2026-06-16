# 系统问题修复：应用与隔离

## 适用场景

- 应用安装、卸载、第三方 apt 源、公钥错误。
- AppImage 缺少 FUSE 或桌面入口异常。
- KARE/Kaiming 宿主机路径、hostname、开始菜单入口、误装到隔离环境。

## 知识入口

进入应用与隔离索引后，按实际问题选择“安装/卸载/AppImage/第三方源”或“KARE/Kaiming 隔离/桌面入口”知识。

- [`../../knowledge/system-repair/applications/README.md`](../../knowledge/system-repair/applications/README.md)

## 最小诊断

```bash
mm-cli -s
command -v <app-command> || true
dpkg -l | rg -i '<package-or-app>' || true
ps -ef | rg -i '<app-keyword>' | rg -v rg || true
```
