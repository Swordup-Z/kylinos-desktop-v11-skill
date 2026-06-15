# 系统问题修复：应用与隔离

## 适用场景

- 应用安装、卸载、第三方 apt 源、公钥错误。
- AppImage 缺少 FUSE 或桌面入口异常。
- KARE/Kaiming 宿主机路径、hostname、开始菜单入口、误装到隔离环境。

## 先读知识章节

- [`../../knowledge/system-repair/applications/installation.md`](../../knowledge/system-repair/applications/installation.md)
- [`../../knowledge/system-repair/applications/isolation.md`](../../knowledge/system-repair/applications/isolation.md)

## 最小诊断

```bash
mm-cli -s
command -v <app-command> || true
dpkg -l | rg -i '<package-or-app>' || true
ps -ef | rg -i '<app-keyword>' | rg -v rg || true
```
