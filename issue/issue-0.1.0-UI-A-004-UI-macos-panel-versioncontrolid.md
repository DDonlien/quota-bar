# UI-A：macOS 26 风格下拉面板

- ID：`0.1.0-UI-A-004`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.1.0 - Dropdown 视觉原型 / UI-A：macOS 26 风格下拉面板。
- 原稳定 ID：`0.1.0-UI-A-000`, `0.1.0-UI-A-001`, `0.1.0-UI-A-002`, `0.1.0-UI-A-003`, `0.1.0-UI-A-004`, `0.1.0-UI-A-005`, `0.1.0-UI-A-006`, `0.1.0-UI-A-007`, `0.1.0-UI-A-008`, `0.1.0-UI-A-009`, `0.1.0-UI-A-010`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.1.0-UI-A-000] 将现有 dropdown 页面改为用户截图所示的 macOS 26 风格 #ui #P0
- [x] [0.1.0-UI-A-001] 顶部展示"每月费用 ¥150/月"和"可用订阅 2/3"
- [x] [0.1.0-UI-A-002] 按订阅服务分组展示 Codex Plus、MiniMax Plus、Kimi Plus
- [x] [0.1.0-UI-A-003] 每个订阅展示彩色状态点、月费、5 小时额度和周额度进度条
- [x] [0.1.0-UI-A-004] 底部展示自动刷新说明、上次刷新时间和退出入口
- [x] [0.1.0-UI-A-005] 保持当前为静态 UI，占位等待后续实际功能
- [x] [0.1.0-UI-A-006] 修正 dropdown 可读性问题，避免顶部、底部和关键字段在当前静态数据下被裁切或省略 #ui #P0
- [x] [0.1.0-UI-A-007] 双击启动 app 后自动展示 dropdown，避免菜单栏应用无 Dock 图标时被误认为未启动 #ui #P0 #cut 用户确认该行为不符合菜单栏应用预期，改为启动后只显示菜单栏图标
- [x] [0.1.0-UI-A-008] 启动后获得并保持顶部菜单栏状态图标，点击图标才展示 dropdown #ui #P0
- [x] [0.1.0-UI-A-009] 下拉面板使用系统玻璃材质参与背景混合，不使用固定灰色面板覆盖材质 #ui #P0
- [x] [0.1.0-UI-A-010] 调整 dropdown 字号接近系统菜单层级，避免标题和服务名过大 #ui #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260629104500-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260629104500-utcp8-mavis.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> B，并且我也有发你参考图 /var/folders/x1/nj8gw6sj3tz36zt026sy8h2m0000gn/T/TemporaryItems/NSIRD_screencaptureui_P6vUFc/截屏2026-06-29 10.30.02.png

#### 完成工作

- [x] 新建 `SettingsComponents.swift`（4 个组件：Section / Group / Row / Divider）
- [x] `PreferencesSection.swift`：加 `tint: Color` 属性
- [x] `PreferencesScene.swift`：sidebar 彩色 icon + Section("title")，detail 用 ScrollView + 自定义组件
- [x] 重写 `GeneralSettingsView`（slider 拆两行）
- [x] 重写 `ModelsSettingsView`
- [x] 重写 `ActivationSettingsView`
- [x] 重写 `AboutSettingsView`
- [x] `PreferencesWindowController`：titlebar transparent + .fullSizeContentView
- [x] `swift build`：0 warning
- [x] `swift test`：20 tests in 4 suites passed
- [x] `make app`：打 .app（build/20260629-104317-feat-preferences/）
- [x] 启动验证：`lsappinfo` 查 windows=NULL（不弹空窗）
- [x] commit `e6a188d`

#### 更新的需求 ID

- `v0.3.0-PM-A-006` 偏好设置窗口——视觉风格升级到 macOS 26 系统设置

#### 验证方式

- `swift build`：0 warning
- `swift test`：20 tests in 4 suites passed
- 启动 .app：windows=NULL（空窗口 bug 持续修复）
- 视觉验证：让用户跑 .app，⌘, 打开偏好窗口，对比参考图

#### 备注

- 已知 trade-off：
  - `titlebarAppearsTransparent` + `.fullSizeContentView` 让 traffic light 浮在 sidebar 顶部，
    第一个 row 可能会被遮挡。**需要用户实机验证**，如有遮挡给 sidebar 加顶部 padding。
  - sidebar 选中行不手染蓝后，macOS 26 会自动用 glass 高亮（跟系统设置一致）。
  - Detail section title 改用 13pt semibold primary（小标题），与参考图「系统」「展开」等风格一致。
- `agent-log/branches/feat-preferences.md` 没更新（之前轮没建），下个 phase 收尾时统一建。
