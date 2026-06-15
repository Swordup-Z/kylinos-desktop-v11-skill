# 应用安装与包管理

## 定位

这是宿主机应用安装、AppImage、第三方 apt 源、KARE 误装边界的分类入口。

## 适用场景

- 命令行安装应用、卸载应用、清理第三方源或公钥错误。
- AppImage 安装、图标、桌面入口、`libfuse.so.2` 缺失。
- 判断应用装在宿主机还是 KARE 环境。

## 先读知识章节

- 应用安装与包管理具体流程：[`../knowledge/applications/application-installation.md`](../knowledge/applications/application-installation.md)
- KARE namespace 与宿主机边界：[`../knowledge/applications/kare-namespace.md`](../knowledge/applications/kare-namespace.md)

## 最小诊断

```bash
mm-cli -s
command -v <app-command> || true
dpkg -S <path> 2>/dev/null || true
apt-cache policy <package>
```
