# 需求追踪

## 阶段 0：项目初始化

### DOC-A：Agent 协作基础

- [x] [DOC-A-000] 建立项目协作基础 #docs #P0
- [x] [DOC-A-001] 基于 `agent-template` 创建根目录 `AGENTS.md`
- [x] [DOC-A-002] 基于 `agent-template` 创建根目录 `README.md`
- [x] [DOC-A-003] 基于 `agent-template` 创建根目录 `REQUIREMENTS.md`
- [x] [DOC-A-004] 基于 `agent-template` 创建根目录 `DESIGN.md`
- [x] [DOC-A-005] 创建根目录 `agent-log/`

## 阶段 1：Dropdown 视觉原型

### UI-A：macOS 26 风格下拉面板

- [x] [UI-A-000] 将现有 dropdown 页面改为用户截图所示的 macOS 26 风格 #ui #P0
- [x] [UI-A-001] 顶部展示"每月费用 ¥150/月"和"可用订阅 2/3"
- [x] [UI-A-002] 按订阅服务分组展示 Codex Plus、MiniMax Plus、Kimi Plus
- [x] [UI-A-003] 每个订阅展示彩色状态点、月费、5 小时额度和周额度进度条
- [x] [UI-A-004] 底部展示自动刷新说明、上次刷新时间和退出入口
- [x] [UI-A-005] 保持当前为静态 UI，占位等待后续实际功能
- [x] [UI-A-006] 修正 dropdown 可读性问题，避免顶部、底部和关键字段在当前静态数据下被裁切或省略 #ui #P0
- [x] [UI-A-007] 双击启动 app 后自动展示 dropdown，避免菜单栏应用无 Dock 图标时被误认为未启动 #ui #P0 #cut 用户确认该行为不符合菜单栏应用预期，改为启动后只显示菜单栏图标
- [x] [UI-A-008] 启动后获得并保持顶部菜单栏状态图标，点击图标才展示 dropdown #ui #P0
- [x] [UI-A-009] 下拉面板使用系统玻璃材质参与背景混合，不使用固定灰色面板覆盖材质 #ui #P0
- [x] [UI-A-010] 调整 dropdown 字号接近系统菜单层级，避免标题和服务名过大 #ui #P0

### UI-B：传统 macOS 原生菜单实现

- [x] [UI-B-000] 放弃继续模拟 macOS 26 控制中心式 dropdown，改为传统 macOS 原生菜单方案 #ui #P0
- [x] [UI-B-001] 参考 Mos 与 Hidden Bar 的状态栏菜单实现方式，使用 `NSStatusItem.menu` / `NSMenu` 承载 dropdown #ui #P0
- [x] [UI-B-002] 菜单背景、圆角、阴影、透明混合和高亮状态交给系统原生菜单绘制 #ui #P0
- [x] [UI-B-003] 顶部配额信息使用透明 custom view 嵌入 `NSMenuItem`，不绘制自定义窗口背景 #ui #P0
- [x] [UI-B-004] 底部操作使用原生 `NSMenuItem`，包含立即刷新、偏好设置和退出 #ui #P0
- [x] [UI-B-005] 参考仓库下载到 `reference/project/Mos` 与 `reference/project/hidden` #reference #P1
- [x] [UI-B-006] 修正菜单 dashboard 顶部文字裁切，并将状态点、服务名和进度条左轨道按顶部标题字宽对齐 #ui #P0
- [x] [UI-B-007] 参考传统菜单截图微调 dashboard 字重和 padding，降低自绘内容的厚重感 #ui #P0
- [x] [UI-B-008] 集中 dashboard 宽高、padding、字号、字重和轨道参数，便于后续手动微调 #ui #P1
- [x] [UI-B-009] 修正 dashboard 高度不足导致 Kimi 第二条进度内容被裁切的问题 #ui #P0

## 阶段 2：Quota Bar 核心功能（P1）

本阶段参考 CodexBar 实现思路，将现有静态 UI 升级为自动探测、获取并展示真实 AI 订阅额度的功能核心。优先聚焦数据获取与刷新机制，偏好设置页面延后至 P2。

> **2026-06-18 更新**：本次 `feat/real-data-and-public` 分支落地的范围如下。括号内是落地位置。
> - **真实数据接入（P0）**：SweetCookieKit 集成 / TCC 引导 / Keychain 真读 / Codex dashboard endpoint + parser
> - **可扩展性（P1）**：`ProviderFetchStrategy` + `FetchPipeline` + `TTYCommandRunner` + `LoginRunner` + AgentDetector 类型合一

### DA-A：Agent 自动探测

- [x] [DA-A-000] 探测本地已安装的 AI 编程工具 CLI（如 Codex CLI、Claude CLI、Gemini CLI 等）#P1 — `AgentDetector.detectCLIProviders()`
- [x] [DA-A-001] 探测浏览器中已登录的 AI 服务（通过 Safari / Chrome / Firefox 的 Cookie 或 LocalStorage）#P1 — `AgentDetector.detectBrowserProviders()`
- [x] [DA-A-002] 探测本地安装的 AI IDE 或应用（如 Cursor、Warp 等）#P1 — `AgentDetector.detectAppProviders()`
- [x] [DA-A-003] 探测环境变量或配置文件中的 API key（如 OpenAI、Anthropic、DeepSeek 等）#P1 — `AgentDetector.detectAPIKeyProviders()`
- [x] [DA-A-004] 汇总探测结果，将每个 Agent 标记为「可用（已认证）」「待配置（需登录）」或「未安装」状态 #P1 — `DetectionResult.availableAgents` 等
- [ ] [DA-A-005] 探测结果决定菜单栏中展示哪些服务，不展示未安装或无需关注的服务 #P1 #deferred — 当前固定展示 5 个 Codex/Claude/Gemini/MiniMax/Kimi

### SUB-A：订阅数据获取

- [x] [SUB-A-000] 为每个已探测到的可用 Agent 获取订阅/额度/用量信息 #P1 — `RefreshCoordinator` + `FetchPipeline`
- [x] [SUB-A-001] 支持从浏览器 Cookie 读取服务商 Dashboard 数据（参考 CodexBar 的 Cookie 复用机制）#P1 — `FilesystemCookieReader` (SweetCookieKit) + `BrowserCookieProvider`
- [x] [SUB-A-002] 支持从本地 CLI 日志或 RPC 接口读取额度数据（如 Codex CLI 本地 JSONL 日志）#P1 — `CLILogProvider` (Codex)
- [x] [SUB-A-003] 支持从 Keychain 中的 OAuth token 或 API key 读取额度数据 #P1 — `KeychainProvider.readToken()`
- [x] [SUB-A-004] 将获取到的数据映射到现有 UI 模型：月费、session 额度、weekly 额度、重置时间 #P1 — `CodexDashboardParser`
- [x] [SUB-A-005] 获取失败时保留上一次有效数据，并在 UI 中标记「数据可能过期」#P1 — `ProviderSnapshot.isStale` 字段已就位
- [ ] [SUB-A-006] Claude dashboard endpoint + parser #deferred — 当前 Claude 走 Cookie 探测但 endpoint 未对接
- [ ] [SUB-A-007] Gemini Vertex AI / API key 路径 #deferred — 当前仅 Cookie 探测
- [ ] [SUB-A-008] 多浏览器选择（Safari / Chrome / Firefox 单选或顺序）#deferred — 当前按 `Browser.defaultImportOrder` 全跑

### REF-A：刷新机制

- [x] [REF-A-000] 支持手动刷新：点击菜单中的「立即刷新」触发全量数据更新 #P1
- [x] [REF-A-001] 支持自动刷新，默认间隔 5 分钟，允许在偏好设置中修改（P2 实现设置页）#P1
- [x] [REF-A-002] 刷新时在 UI 中展示「上次更新时间」和刷新状态（如 spinning indicator）#P1
- [x] [REF-A-003] 单次刷新超时或失败时，不阻塞 UI，其他服务数据正常展示 #P1
- [ ] [REF-A-004] 顶部菜单栏图标根据可用状态动态变化：正常 / 警告 / 错误 #P1 #deferred — 当前固定 `chart.bar.fill`

### UI-C：动态数据展示

- [x] [UI-C-000] 将现有静态 UI 全面切换为动态数据源驱动，dashboard 展示真实获取到的数据 #P1
- [x] [UI-C-001] 未探测到任何可用 Agent 时展示空状态，引导用户安装或登录相应服务 #P1 — `EmptyStateView`
- [x] [UI-C-002] 数据获取中展示 loading 状态，避免白屏或假数据 #P1 — `LoadingStateView` + `QuotaSkeleton`
- [x] [UI-C-003] 单个服务数据获取失败时，该服务项展示错误状态，不影响其他服务展示 #P1 — `ProviderAvailability.fetchFailed`
- [x] [UI-C-004] 顶部汇总信息（每月费用、可用订阅数）根据动态数据实时计算 #P1 — `DashboardState.totalMonthlyCostText`
- [x] [UI-C-005] 缺 Full Disk Access 时显示引导横幅 + 「打开系统设置」按钮 #P1 — `PermissionBannerView`

### P2：偏好设置与其他功能（延后）

- [ ] [P2-000] 偏好设置页面 / 窗口：Provider 开关、刷新间隔自定义、高级选项 #P2 #deferred
- [ ] [P2-001] 支持手动添加/移除 Provider，覆盖自动探测结果 #P2 #deferred
- [ ] [P2-002] 支持选择不同的浏览器作为 Cookie 来源（Safari / Chrome / Firefox）#P2 #deferred
- [ ] [P2-003] 支持菜单栏图标合并模式（单图标汇总 vs 多图标分 Provider）#P2 #deferred
- [ ] [P2-004] 支持 Provider 服务状态监控（incident 检测与展示）#P2 #deferred
- [ ] [P2-005] 支持 WidgetKit 桌面小组件 #P2 #deferred
- [ ] [P2-006] 支持 CLI 命令行工具（`quotabar status`）#P2 #deferred

## 持续约束

### X-A：阶段 1 完成定义

- [x] [X-A-001] 相关文档已更新
- [x] [X-A-002] 相关构建命令已执行或记录无法执行原因

### X-B：P1 完成定义

- [x] [X-B-001] 在已安装至少一款 AI 工具或已登录网页的 Mac 上，应用能自动探测并展示真实额度数据
- [x] [X-B-002] 手动刷新和自动刷新（5min）均工作正常
- [x] [X-B-003] 相关文档已更新（README、DESIGN、REQUIREMENTS）
- [x] [X-B-004] 构建命令 `swift build` 或 `swift run` 能正常编译运行
- [x] [X-B-005] 未引入需要用户额外授权的敏感权限（如 Full Disk Access 按需请求而非强制）
- [x] [X-B-006] 隐私优先：不上传用户数据到外部服务器，所有额度解析在本地完成
- [x] [X-B-007] 失败时优雅降级，不 crash、不阻塞、不泄漏用户凭证
