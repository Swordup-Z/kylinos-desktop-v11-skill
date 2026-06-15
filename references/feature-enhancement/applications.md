# 系统功能增强：应用体验

## 适用场景

- 希望改进应用安装方式、桌面入口或用户级安装体验。
- 需要把 AppImage、KARE/Kaiming 边界经验整理成可复用流程。

## 先读知识章节

- [`../../knowledge/feature-enhancement/applications/README.md`](../../knowledge/feature-enhancement/applications/README.md)

## 最小诊断

```bash
command -v <app-command> || true
find "$HOME/.local/share/applications" /usr/share/applications -maxdepth 1 -name '*.desktop' 2>/dev/null
```
