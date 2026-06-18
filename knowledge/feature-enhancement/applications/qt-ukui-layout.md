# Qt/UKUI 应用界面布局

## 适用场景

- 在 KylinOS Desktop V11 / UKUI 上开发 Qt Widgets 桌面维护工具。
- 表格首行或所有行文字显示不全、被固定行高裁剪。
- 语言下拉框、组合框或下拉列表在 UKUI 主题下文字颜色与背景冲突，看不到当前选项。

## 诊断要点

- 检查 `QTableWidget` 是否使用了固定 `verticalHeader()->setDefaultSectionSize()`，同时没有 `ResizeToContents`。
- 检查是否所有列都设置为 `QHeaderView::Stretch`。长应用 ID、版本、路径和中文说明在窄列中会被压缩，若同时使用固定行高就会裁剪。
- 检查是否没有设置 `setWordWrap(true)`、`setTextElideMode(Qt::ElideNone)`，以及单元格没有 tooltip。
- 检查 `QComboBox` 是否依赖系统主题默认颜色。UKUI 深浅主题或 token 样式可能覆盖组合框前景色、下拉列表背景色和选中态。

## 推荐实现

- 表格统一配置：
  - `setWordWrap(true)`
  - `setTextElideMode(Qt::ElideNone)`
  - `verticalHeader()->setSectionResizeMode(QHeaderView::ResizeToContents)`
  - `horizontalHeader()->setMinimumSectionSize(...)`
  - 按列设置 `ResizeToContents` 与 `Stretch`，不要所有列都无差别 `Stretch`。
- 每次填充或刷新表格数据后调用 `resizeRowsToContents()`。对于少量行的维护工具，这个开销可接受，能避免高 DPI、字体或主题变化后裁剪。
- 长文本单元格同时写入 `setToolTip(text)`，让用户鼠标悬停可查看完整内容。
- 路径、应用 ID、说明列优先使用 `Stretch` 或允许横向滚动；状态、大小、数量列优先 `ResizeToContents`。
- `QComboBox` 在应用级 stylesheet 中显式设置：
  - 当前框 `background`、`color`、`border`
  - `QComboBox QAbstractItemView` 的 `background`、`color`、`selection-background-color`、`selection-color`
  - 必要时设置 `setMinimumWidth()` 和 `setSizeAdjustPolicy(QComboBox::AdjustToContents)`

## 验证

```bash
cmake -S . -B build -G Ninja
cmake --build build
timeout 8s env QT_QPA_PLATFORM=offscreen ./build/<app>
```

离屏启动只验证进程和样式不会崩溃；真实裁剪、悬停和语言栏可见性仍需在 UKUI 桌面中打开应用确认。
