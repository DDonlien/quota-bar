# 任务清单

> **子功能索引**
> - [`site/REQUIREMENTS.md`](./site/REQUIREMENTS.md) — 营销主页（Astro 静态站，部署到 `quotabar.ddonlien.com`）。v0.1.0 主页首版已落地：纯 CSS/HTML mockup 还原菜单栏 + dropdown，6 家 provider 卡片，4 个卖点，下载按钮动态取最新 nightly DMG。

## Phase - v0.0.0 - 项目初始化

### sub/main: 建立项目协作基础

- [x] [0.0.0-DOC-A-000] 建立项目协作基础 #docs #P0
- [x] [0.0.0-DOC-A-001] 基于 `agent-template` 创建根目录 `AGENTS.md`
- [x] [0.0.0-DOC-A-002] 基于 `agent-template` 创建根目录 `README.md`
- [x] [0.0.0-DOC-A-003] 基于 `agent-template` 创建根目录 `REQUIREMENTS.md`
- [x] [0.0.0-DOC-A-004] 基于 `agent-template` 创建根目录 `DESIGN.md`
- [x] [0.0.0-DOC-A-005] 创建根目录 `agent-log/`

## Phase - v0.1.0 - Dropdown 视觉原型

### sub/main: 打磨 macOS 26 风格下拉面板

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

### sub/main: 切换为传统 macOS 原生菜单

- [x] [0.1.0-UI-B-000] 放弃继续模拟 macOS 26 控制中心式 dropdown，改为传统 macOS 原生菜单方案 #ui #P0
- [x] [0.1.0-UI-B-001] 参考 Mos 与 Hidden Bar 的状态栏菜单实现方式，使用 `NSStatusItem.menu` / `NSMenu` 承载 dropdown #ui #P0
- [x] [0.1.0-UI-B-002] 菜单背景、圆角、阴影、透明混合和高亮状态交给系统原生菜单绘制 #ui #P0
- [x] [0.1.0-UI-B-003] 顶部配额信息使用透明 custom view 嵌入 `NSMenuItem`，不绘制自定义窗口背景 #ui #P0
- [x] [0.1.0-UI-B-004] 底部操作使用原生 `NSMenuItem`，包含立即刷新、偏好设置和退出 #ui #P0
- [x] [0.1.0-UI-B-005] 参考仓库下载到 `reference/project/Mos` 与 `reference/project/hidden` #reference #P1
- [x] [0.1.0-UI-B-006] 修正菜单 dashboard 顶部文字裁切，并将状态点、服务名和进度条左轨道按顶部标题字宽对齐 #ui #P0
- [x] [0.1.0-UI-B-007] 参考传统菜单截图微调 dashboard 字重和 padding，降低自绘内容的厚重感 #ui #P0
- [x] [0.1.0-UI-B-008] 集中 dashboard 宽高、padding、字号、字重和轨道参数，便于后续手动微调 #ui #P1
- [x] [0.1.0-UI-B-009] 修正 dashboard 高度不足导致 Kimi 第二条进度内容被裁切的问题 #ui #P0

### sub/main: 完成 Dropdown 视觉原型验收

- [x] [0.1.0-QA-A-001] 相关文档已更新
- [x] [0.1.0-QA-A-002] 相关构建命令已执行或记录无法执行原因

## Phase - v0.2.0 - Quota Bar 核心功能

本阶段参考 CodexBar 实现思路，将现有静态 UI 升级为自动探测、获取并展示真实 AI 订阅额度的功能核心。优先聚焦数据获取与刷新机制，偏好设置页面延后至 P2。

> **2026-06-18 更新**：本次 `feat/real-data-and-public` 分支落地的范围如下。括号内是落地位置。
> - **真实数据接入（P0）**：SweetCookieKit 集成 / TCC 引导 / Keychain 真读 / Codex dashboard endpoint + parser
> - **可扩展性（P1）**：`ProviderFetchStrategy` + `FetchPipeline` + `TTYCommandRunner` + `LoginRunner` + AgentDetector 类型合一

### sub/main: 自动探测本地 AI 服务

- [x] [0.2.0-DATA-A-000] 探测本地已安装的 AI 编程工具 CLI（如 Codex CLI、Claude CLI、Gemini CLI 等）#P1 — `AgentDetector.detectCLIProviders()`
- [x] [0.2.0-DATA-A-001] 探测浏览器中已登录的 AI 服务（通过 Safari / Chrome / Firefox 的 Cookie 或 LocalStorage）#P1 — `AgentDetector.detectBrowserProviders()`
- [x] [0.2.0-DATA-A-002] 探测本地安装的 AI IDE 或应用（如 Cursor、Warp 等）#P1 — `AgentDetector.detectAppProviders()`
- [x] [0.2.0-DATA-A-003] 探测环境变量或配置文件中的 API key（如 OpenAI、Anthropic、DeepSeek 等）#P1 — `AgentDetector.detectAPIKeyProviders()`
- [x] [0.2.0-DATA-A-004] 汇总探测结果，将每个 Agent 标记为「可用（已认证）」「待配置（需登录）」或「未安装」状态 #P1 — `DetectionResult.availableAgents` 等
- [x] [0.2.0-DATA-A-005] 探测结果决定菜单栏中展示哪些服务，不展示未安装或无需关注的服务 #P1 — `RefreshCoordinator` 过滤 `.notInstalled` snapshot

### sub/main: 获取真实订阅与额度数据

- [x] [0.2.0-DATA-B-000] 为每个已探测到的可用 Agent 获取订阅/额度/用量信息 #P1 — `RefreshCoordinator` + `FetchPipeline`
- [x] [0.2.0-DATA-B-001] 支持从浏览器 Cookie 读取服务商 Dashboard 数据（参考 CodexBar 的 Cookie 复用机制）#P1 — `FilesystemCookieReader` (SweetCookieKit) + `BrowserCookieProvider`
- [x] [0.2.0-DATA-B-002] 支持从本地 CLI 日志或 RPC 接口读取额度数据（如 Codex CLI 本地 JSONL 日志）#P1 — `CLILogProvider` (Codex)
- [x] [0.2.0-DATA-B-003] 支持从 Keychain 中的 OAuth token 或 API key 读取额度数据 #P1 — `KeychainProvider.readToken()`
- [x] [0.2.0-DATA-B-004] 将获取到的数据映射到现有 UI 模型：月费、session 额度、weekly 额度、重置时间 #P1 — `CodexDashboardParser`
- [x] [0.2.0-DATA-B-005] 获取失败时保留上一次有效数据，并在 UI 中标记「数据可能过期」#P1 — `ProviderSnapshot.isStale` 字段已就位
- [x] [0.2.0-DATA-B-009] 未拿到真实 dashboard/usage 响应时不生成 Plus/Pro、价格或 100% 额度占位 #P1
- [x] [0.2.0-DATA-B-010] 订阅价格只在真实返回 plan/tier 后按官方价目映射；未知服务或未知档位显示 `—` #P1
- [x] [0.2.0-DATA-B-011] 按系统语言/地区选择展示货币，简体中文或中国区默认将 USD 订阅价按实时汇率换算为人民币 #P1
- [x] [0.2.0-DATA-B-012] 支持 Kimi 从 `~/.kimi-code/credentials/kimi-code.json` 读 OAuth token 调 `/apiv2/.../GetUsages` #P1 — `KimiAuthProvider`
- [x] [0.2.0-DATA-B-013] App Bundle 探测：服务只有桌面 App 没有 dashboard 时（如 Trae、Antigravity），识别后展示为「已安装，dashboard 待接入」 #P1 — `AppBundleProvider`
- [x] [0.2.0-DATA-B-006] Claude dashboard endpoint + parser — `BrowserCookieProvider` 支持 organizations → usage 二段请求，`ClaudeDashboardParser` 解析 usage payload
- [ ] [0.2.0-DATA-B-007] Gemini Vertex AI / API key 路径 #cut — 用户确认 Gemini 已被 Antigravity 代替，本项目不再主动接入 Gemini quota
- [ ] [0.2.0-DATA-B-008] 多浏览器选择（Safari / Chrome / Firefox 单选或顺序）#deferred — 当前按 `Browser.defaultImportOrder` 全跑
- [x] [0.2.0-DATA-B-014] Kimi Web 端点 Cookie 模式（`kimi-auth` cookie → GetSubscriptionStat）— `BrowserCookieProvider` POST `www.kimi.com/apiv2/kimi.gateway.membership.v2.MembershipService/GetSubscriptionStat`，支持 Bearer Token 认证和 `KimiSubscriptionStatParser` 解析 Work + Code 额度 #P1
- [x] [0.2.0-DATA-B-015] MiniMax Web 端点 Cookie 模式（`minimax.chat` cookie → coding_plan/remains）— Cookie 路径接入 `api.minimax.chat/v1/api/openplatform/coding_plan/remains`，Cloudflare/签名失败时安全降级
- [x] [0.2.0-DATA-B-016] Antigravity dashboard 端点（Antigravity 用 localhost probe，需本地运行）— `AntigravityDashboardProvider` 探测 language_server 端口和 csrf 后调用本地 GetUserStatus
- [ ] [0.2.0-DATA-B-017] 同一服务多身份合并/拆分（如 Kimi Code / Kimi Work、work + personal 账号）#P2 #deferred — 当前架构每个 ProviderKind 只返一条 snapshot
- [x] [0.2.0-DATA-B-018] 移除 Gemini 主动采集 pipeline，Google 系额度由 Antigravity 接替 #P1
- [x] [0.2.0-DATA-B-019] Provider pipeline 在首个数据源缺凭证时继续尝试后续数据源，避免 MiniMax/Kimi/Codex 因 API key 或 OAuth 缺失而跳过 Cookie/CLI fallback #P1
- [x] [0.2.0-DATA-B-020] Cookie dashboard 响应中的订阅档位/费用信息传递到 UI，MiniMax Web 路径支持 `current_package_name` 和已知 Coding Plan 价格映射 #P1
- [ ] [0.2.0-DATA-B-021] Trae Work 是否独立接入 #P2 #deferred — 官方已有 TRAE Work 与用量/订阅概念，值得作为独立 provider 继续调研；当前缺少已验证本地 CLI、App 或 dashboard endpoint，不并入 P1 核心
- [x] [0.2.0-DATA-B-028] Kimi 服务端下线 `GetSubscriptionStat`（2026-07 起返回 404）后，Work 月额度改从 `GetSubscription.balances[]`（FEATURE_OMNI/SUBSCRIPTION 的 amountUsedRatio）解析；档位/价格/续费日同响应的 goods.title / amounts / nextBillingTime；Code 5h/周额度由 CLI OAuth 经分层合并补齐 #P0 #bugfix — `KimiSubscriptionParser.parse` + `KimiDesktopTokenProvider`

### sub/main: 提供额度刷新机制

- [x] [0.2.0-FE-A-000] 支持手动刷新：点击菜单中的「立即刷新」触发全量数据更新，且 dropdown 保持打开 #P1
- [x] [0.2.0-FE-A-001] 支持自动刷新，默认间隔 5 分钟，允许在偏好设置中修改（P2 实现设置页）#P1
- [x] [0.2.0-FE-A-002] 刷新时在 UI 中展示「上次更新时间」和刷新状态（如 spinning indicator）#P1
- [x] [0.2.0-FE-A-003] 单次刷新超时或失败时，不阻塞 UI，其他服务数据正常展示 #P1
- [x] [0.2.0-FE-A-004] 顶部菜单栏图标根据可用状态动态变化：正常 / 警告 / 错误 #P1 — 4 态（normal / refreshing / warning / error）+ 最低 remaining% 数字徽标，`StatusBarController.refreshStatusItemAppearance()`
- [x] [0.2.0-FE-A-005] 菜单栏改为多 bar 视图（Liquid Glass 风格）：每个已配置订阅画 1 个垂直 bar，bar 数 = `.available` 订阅数，bar 颜色 = brand color，bar 顺序 = dashboard 顺序，bar 高度 = 最近重置 quota 的 remainingFraction；用完的（0%）仍画最小 bar 保证知情；未配置（needsConfiguration/notInstalled/fetchFailed）不画 bar #P1 — `StatusBarController.makeBarsImage()`
- [x] [0.2.0-FE-A-006] 菜单栏 status item 占位宽度随实际 bar image 宽度变化；在满足参考图圆角视觉的前提下，避免窄图标仍占 80pt 或 bar 间出现异常缝隙 #P1
- [x] [0.2.0-FE-A-007] 修正菜单栏图标绘制宽度与实际占位宽度不一致的问题，避免截图中 bar 图标视觉宽度较窄但 status item 点击/占位区域明显过宽 #P1
- [x] [0.2.0-FE-A-008] 校准菜单栏多 bar 的数值来源和高度映射，确保每个 bar 真实反映对应服务当前额度状态，而不是使用与实际剩余额度不匹配的占位或无效数值 #P1
- [x] [0.2.0-FE-A-009] 修正菜单栏 bar 绘制样式：当前 bar 圆角没有按预期绘制，应参考此前参考图恢复圆角外观，并确保高低不同的 bar 在小尺寸菜单栏图标中仍清晰可辨 #P1

### sub/main: 动态展示真实额度数据

- [x] [0.2.0-UI-A-000] 将现有静态 UI 全面切换为动态数据源驱动，dashboard 展示真实获取到的数据 #P1
- [x] [0.2.0-UI-A-001] 未探测到任何可用 Agent 时展示空状态，引导用户安装或登录相应服务 #P1 — `EmptyStateView`
- [x] [0.2.0-UI-A-002] 数据获取中展示 loading 状态，避免白屏或假数据 #P1 — `LoadingStateView` + `QuotaSkeleton`
- [x] [0.2.0-UI-A-003] 单个服务数据获取失败时，该服务项展示错误状态，不影响其他服务展示 #P1 — `ProviderAvailability.fetchFailed`
- [x] [0.2.0-UI-A-004] 顶部汇总信息（每月费用、可用订阅数）根据动态数据实时计算 #P1 — `DashboardState.totalMonthlyCostText`
- [x] [0.2.0-UI-A-005] 浏览器 Cookie 数据源缺 Full Disk Access 时按需显示引导横幅 + 「打开系统设置」按钮 #P1 — `PermissionBannerView`
- [x] [0.2.0-UI-A-006] 距离刷新较远时显示具体日期；明天/后天使用自然语言，避免"6天后"难以反应 #P1
- [x] [0.2.0-UI-A-007] 调整 dropdown 额度进度条颜色语义：进度条用于表达额度健康状态，剩余额度大于 30% 显示蓝色（macOS 系统蓝），0% 到 30% 显示橙色 #P1
- [x] [0.2.0-UI-A-008] 重新设计服务与进度条的颜色绑定方式：服务名称使用白色，菜单栏 bar 使用 provider brand color，dropdown 进度条使用额度健康色 #P1
- [x] [0.2.0-UI-A-009] 额度刷新倒计时统一使用两段紧凑格式显示，例如 `4d3h`、`4h3m`、`3m20s`；小于 1 天显示小时和分钟，小于 1 小时显示分钟和秒，更短时间如实显示 `0mXs` #P1

### sub/main: 完成核心功能验收

- [x] [0.2.0-QA-A-001] 在已安装至少一款 AI 工具或已登录网页的 Mac 上，应用能自动探测并展示真实额度数据
- [x] [0.2.0-QA-A-002] 手动刷新和自动刷新（5min）均工作正常
- [x] [0.2.0-QA-A-003] 相关文档已更新（README、DESIGN、REQUIREMENTS）
- [x] [0.2.0-QA-A-004] 构建命令 `swift build` 或 `swift run` 能正常编译运行
- [x] [0.2.0-QA-A-005] 未引入需要用户额外授权的敏感权限（如 Full Disk Access 按需请求而非强制）
- [x] [0.2.0-QA-A-006] 隐私优先：不上传用户数据到外部服务器，所有额度解析在本地完成
- [x] [0.2.0-QA-A-007] 失败时优雅降级，不 crash、不阻塞、不泄漏用户凭证

## Phase - v0.3.0 - UI 拖拽、订阅组语义与 dropdown 实时刷新

> 本阶段聚焦三个层面的修正：
> 1. 拖拽排序 UI 的"基于排序取值"语义从 quota 层升级到 **subscription group（订阅组）层**——
>    bar 高度 / 状态灯反映的是「用户排序后第一个订阅组里 remainingFraction 最差的 quota」，
>    而非"排序后第一个 quota"或"整 provider 最差"。
> 2. 订阅组（独立计费）边界显式化：每个 provider 至少 1 个订阅组，多订阅组 provider
>    （MiniMax General / Video、Antigravity Gemini / Other）独立拖拽、独立状态灯。
> 3. dropdown 实时刷新 + **streaming 刷新**：菜单打开期间 SwiftUI 自动响应 `coordinator.state`
>    变化（v0.3.0-UI-A-004），且 provider 完成一个就 publish 一个，不需要等全部刷新完成。

### sub/main: 建立订阅组语义

- [x] [0.3.0-DATA-A-000] `QuotaWindow` 增加 `subscriptionGroup` 字段，语义为「独立计费的订阅组」；fallback 到 `providerKind.rawValue`（未显式设的 parser 视为整个 provider = 1 个订阅组）#P1 — `QuotaModels.swift:subscriptionGroup`
- [x] [0.3.0-DATA-A-001] 所有 parser 显式设 subscriptionGroup：Codex=`"codex"`、Kimi=`"kimi"`（含 web + CLI 两条路径）、MiniMax CLI 按 `modelName.lowercased()`、Antigravity 主路径按 `group.displayName` / fallback 路径固定 `"Gemini"` + `"Other"` #P1
- [x] [0.3.0-DATA-A-002] `PreferencesStore.QuotaPreferences` 新增 `subscriptionGroupOrder: [String: [String]]` 字段（key = `providerKind.rawValue`），Codable 向后兼容（旧配置自动获得 `[:]`）#P1
- [x] [0.3.0-DATA-A-003] `ProviderSnapshot` 新增 `subscriptionGroups(customOrder:)` 与 `primarySubscriptionGroupWorstQuota(itemOrder:)` 两个方法：前者按订阅组分组（组顺序继承用户排序），后者取排序后第一个订阅组的 worst quota #P1
- [x] [0.3.0-DATA-A-004] 修正 `subscriptionGroups(customOrder:)` 的排序语义：`customOrder` 必须按订阅组 key 排序而不是 quota stableKey；Kimi Work / Code 无论来源如何都强制归为 `kimi` 单订阅组 #P1
- [x] [0.3.0-DATA-A-005] 恢复 Kimi Work 已验证数据路径：Work/Code 三条额度只由浏览器 `kimi-auth` cookie 调 `GetSubscriptionStat` 产生；`KimiAuthProvider` 保持 CLI Code-only fallback；`GetSubscription` tier/price 请求失败或超时不得阻塞 Work 额度显示 #P1

### sub/main: 支持订阅组拖拽排序与状态联动

- [x] [0.3.0-UI-A-000] 用户可上下拖拽 Provider 和多订阅组 Provider 下的订阅组，顺序实时生效并持久化；单条 quota row 不单独拖拽 #P1
- [x] [0.3.0-UI-A-001] 拖拽后 Provider 左侧状态灯颜色取「按订阅组排序后第一个订阅组的最差 quota」；多订阅组 provider 拖订阅组、单订阅组 provider 拖动不影响取值 #P1 — `MenuView.statusColor(itemOrder: subscriptionGroupOrder)`
- [x] [0.3.0-UI-A-002] 拖拽后顶部菜单栏 bar 高度取「按订阅组排序后第一个订阅组的最差 quota」；bar 取值与 quota 拖拽顺序解耦，只跟订阅组顺序绑定 #P1 — `StatusBarController.statusBarQuota(for:)`
- [x] [0.3.0-UI-A-003] Provider 区块本身支持上下拖拽排序，顺序实时生效并持久化 #P1
- [x] [0.3.0-UI-A-004] dropdown 实时刷新：`MenuView` 用 `@ObservedObject` 绑定 `RefreshCoordinator`，菜单打开期间 SwiftUI 自动响应 `coordinator.state` 变化，NSHostingView 原地重渲染；`StatusBarController.observeCoordinator` 移除 `needsRebuild` 缓冲 #P1
- [x] [0.3.0-UI-A-005] 多订阅组 provider UI 拆分：单订阅组 provider（Codex / Kimi）保持原 UI（planHeader 带状态灯 + quota rows 平铺）；多订阅组 provider（MiniMax / Antigravity）渲染多个 `SubscriptionGroupBlock`，block 只作为拖拽边界，不额外显示子组 header 或独立状态灯 #P1
- [x] [0.3.0-UI-A-006] 拖拽两层作用域：provider 整体 / subscription group（仅同 provider 内，payload = `"<kind>:<groupKey>"`）；quota row 不单独拖拽，组内多条额度作为整组移动 #P1
- [x] [0.3.0-UI-A-007] 恢复多订阅组 UI 对齐关系：provider header 保留唯一状态灯；订阅组标题和组内 quota 行沿用单订阅组内容缩进，不因额外状态灯产生错位 #P1
- [x] [0.3.0-UI-A-009] 修正多订阅组 dropdown 视觉回归：移除 “Gemini/Other/General/Video” 这类独立子组标签行，恢复 quota row 与单组 provider 相同的左缩进；整组拖拽仍绑定在不可见 `SubscriptionGroupBlock` 上 #P1
- [x] [0.3.0-UI-A-010] 计划头部右侧月费左侧展示「订阅/数据最后有效日期」灰色标签：11pt regular，secondary 灰，等宽数字，gap 6pt；格式 `yyyy/M/d` 无前导零（例如 `2026/6/25`，语义上「6/25 是最后有效天，26 数据过期」）；仅在 `availability == .available` 且 `monthlyPrice != nil` 时展示，`needsConfiguration` 仍显示隐藏按钮 #P1 — `ProviderSnapshot.subscriptionExpiresAt`（默认从 `quotas.map(\.resetsAt).max()` 推断）+ `MenuView.PlanHeader.expiresAtText`

### sub/main: 支持 Provider 增量刷新

> 旧实现：所有 provider 并发 fetch，但只在**全部完成**后才把 `state` 整体替换为新值——
> 即使 dropdown 已经能"实时刷新"（v0.3.0-UI-A-004），用户看到的也只是"白屏 → 一次完整数据出现"。
> 新实现：探测到安装后立刻注入 `.loading` placeholder，provider 完成一个就 apply 一个、
> publish 一次 `state`，UI 立即响应。菜单栏 bar 也按完成顺序逐个"动态增长"。

- [x] [0.3.0-FE-A-000] `ProviderAvailability` 新增 `.loading` 枚举值 + `ProviderSnapshot.loading(kind:)` 工厂：占位 snapshot，quotas 为空、tier/price 为 nil、`isStale = false`；UI 渲染为骨架 #P1 — `QuotaModels.swift`
- [x] [0.3.0-FE-A-001] `RefreshCoordinator.runRefreshCycle` 重写为 streaming：探测安装 → 立即按用户偏好顺序 seed `.loading` placeholders → 用 `withTaskGroup` 并发跑每个 provider → 每个 provider 完成（含 fallback）立即调用 `applyProviderResult` 在原位置替换 placeholder → 全部完成后计算最终 `refreshState` #P1 — `RefreshCoordinator.swift:runRefreshCycle`
- [x] [0.3.0-FE-A-002] `state.lastUpdated` 在每个 provider 完成时推进（`max(prev, fetchedAt)`），让顶部"上次更新 HH:mm"逐 provider 前进，用户看到"数据正在流入" #P1 — `RefreshCoordinator.applyProviderResult`
- [x] [0.3.0-FE-A-003] `MenuView.PlanSection` 加 `case .loading: QuotaSkeleton()`：loading snapshot 直接走骨架分支；`ReadyStateView` 把 `isLoading` 改为派生自 `snapshot.availability == .loading`，per-snapshot 独立判断 #P1 — `MenuView.swift`
- [x] [0.3.0-FE-A-004] `StatusBarController.drawableSnapshots` / `remainingFraction` / `makeBarsImage` 处理 `.loading`：bar 高度 50%、alpha 0.4（dimmed），区别于 needsConfiguration（alpha 1.0 50%）；tooltip 在 loading 时显示「刷新中」而不是 50% #P1 — `StatusBarController.swift`
- [x] [0.3.0-FE-A-005] `pickBestSnapshot` 和 `FetchPipeline.merge` 的 availability 优先级加上 `.loading`（priority 2，介于 needsConfiguration=3 和 notInstalled=1 之间），避免 exhaustiveness warning 影响新 case #P1
- [x] [0.3.0-FE-A-006] 拖拽订阅组后，菜单栏 bar 与当前可见状态灯立即按新的第一订阅组 worst quota 刷新；菜单打开期间 preferences 变化也触发 SwiftUI 重算 #P1
- [ ] [0.3.0-UI-A-008] 多订阅组 provider 的每个子组状态灯显示该子组自身 worst quota #cut 用户明确不需要每个子组独立状态灯，改由 provider header 唯一灯显示第一组 worst quota

### sub/main: 偏好设置与后续能力

> **2026-07-01 更新**：`preferences/main` 已合并回 main，第一版偏好设置窗口落地为
> AppKit `NSWindow` + SwiftUI 内容页，避免 accessory 菜单栏应用使用 SwiftUI `Settings`
> scene 时启动弹空窗口或 `Cmd+,` 无响应。后续能力（手动添加 Provider / WidgetKit /
> CLI 等）暂留 P2 deferred。

- [x] [0.3.0-PM-A-000] 偏好设置窗口骨架：macOS 26 系统设置风格 sidebar + detail，Liquid Glass，AppKit `PreferencesWindowController` 承载 SwiftUI 设置页 #P1
- [x] [0.3.0-PM-A-001] sidebar 分组：默认组（无标题）放「通用」「模型」；「Quota Bar」组放「激活」「关于」；激活/关于项展示分组标题，未分组项不展示 #P1
- [x] [0.3.0-PM-A-002] 「通用」页：刷新间隔、浏览器 Cookie 来源、语言（中文 / English）、菜单栏图标模式（合并 / 拆分，说明随当前选项切换）、登录时启动 toggle（后续接入 LoginService / SMAppService）#P1
- [x] [0.3.0-PM-A-003] 「模型」页：展示当前可配置的核心模型开关（Codex / MiniMax / Kimi / Claude / GLM），每行按「名称」+「供应商 | 当前真实接入方式（App / CLI / Web / API / 待接入）」展示；访问模式按现有 pipeline 支持情况显示 #P1
- [x] [0.3.0-PM-A-004] 「激活」页：展示未激活状态、激活邮箱输入和禁用态移除激活按钮；不展示占位设备 ID 或说明标题 #P1
- [x] [0.3.0-PM-A-005] 「关于」页：应用名 + 版本号 + 构建号（`Bundle.main` 读取）+ 开发者 Taobe + 检查更新 + 重置偏好按钮；不展示许可、平台和维护标题 #P1
- [x] [0.3.0-PM-A-006] 状态栏菜单恢复「偏好设置...」项（`Cmd+,`），点击触发 `PreferencesWindowController.shared.show()`，不再保留 `NSSound.beep()` 占位 #P1
- [x] [0.3.0-PM-A-007] `PreferencesStore.QuotaPreferences` 新增 `launchAtLogin: Bool` 字段（Codable 向后兼容，旧配置自动获得 `false`）#P1
- [x] [0.3.0-PM-A-012] 偏好设置视觉微调：左侧 sidebar 使用 macOS 26 原生 `NavigationSplitView` + `List(.sidebar)`，不手搓卡片背景；每页顶部使用固定 toolbar 标题（页面 icon + 标题，不显示返回/前进按钮）；说明小字与分割线遵循系统设置列表行样式，分割线保留左右 inset；Provider 等多对象列表收紧 padding 与开关尺寸；关于页保留应用信息、检查更新和重置入口；尽量移除侧边栏收起按钮 #P1
- [ ] [0.3.0-PM-A-008] 手动添加/移除 Provider 入口（覆盖自动探测结果）#P2 #deferred — 本次仅做"关闭自动探测结果"，手动添加不在本轮范围
- [ ] [0.3.0-PM-A-009] Provider 服务状态监控（incident 检测与展示）#P2 #deferred
- [ ] [0.3.0-PM-A-010] WidgetKit 桌面小组件 #P2 #deferred
- [ ] [0.3.0-PM-A-011] CLI 命令行工具（`quotabar status`）#P2 #deferred

## Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他）

> 用户电脑实测已装：
> - `/Applications/ZCode.app`（bundle id `dev.zcode.app`、version 3.1.2，智谱 BigModel Z Code 桌面 IDE），运行时主进程 + `zcode-cli` 进程在跑；
> - 千问桌面 App 未在 `/Applications`、`~/Applications`、`~/Library/Application Support` 找到，等用户确认实际安装位置。
>
> zcode 是 opencode 的 fork/skin（用 `https://opencode.ai/config.json` schema），走 anthropic 兼容 API；
> 凭证、配置、套餐额度本地缓存统一在 `~/.zcode/v2/` 目录下。

### feat/glm-provider: 调研智谱 BigModel Z Code Provider

- [ ] [0.4.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.zcode` 枚举值，`displayName = "Z Code"`、`brandColor`、`iconSymbol`、`bundleIdentifier = "dev.zcode.app"`、`credentialFiles = ["~/.zcode/v2/credentials.json"]`、`envVarNames = []` 等元数据补齐 #P1
- [ ] [0.4.0-DATA-A-001] `ZCodeAuthProvider` 实现：从 `~/.zcode/v2/config.json` 读启用 plan 的 API key + baseURL，对 plan endpoint 发 anthropic 兼容 API 拉 usage；解析剩余额度到 `[QuotaWindow]` #P1
- [ ] [0.4.0-DATA-A-002] 套餐映射：识别 `builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan` 4 种 plan，subscriptionGroup 按 plan 区分（每个 plan = 1 个订阅组）；价格映射到 `ProviderPricing` #P1
- [ ] [0.4.0-DATA-A-003] `ZcodeLoginRunner` + `InstallDetectorProvider`：探测 `dev.zcode.app` bundle 安装和 `~/.zcode/v2/config.json` 存在性，驱动 pipeline 串接 #P1
- [ ] [0.4.0-DATA-A-004] `Strategies.zcodePipeline()` 接入 `RefreshCoordinator`，凭证缺失时 fallback 到 Keychain / `needsConfiguration` 状态 #P1

### sub/main: 调研阿里通义千问桌面 App

- [ ] [0.4.0-DATA-B-000] 用户确认千问桌面 App 实际安装路径（`/Applications` / `~/Applications` / DMG 挂载点 / 第三方目录） #blocked — 用户已声明"已装"但实际未在常见位置发现，需要确认
- [ ] [0.4.0-DATA-B-001] 在 `ProviderKind` enum 新增 `.qwen` 枚举值，元数据补齐（`bundleIdentifier` 等安装探测需要用户提供）#blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-DATA-B-002] `QwenAppProvider` 实现：dashboard endpoint 走浏览器 Cookie 路径（参考 Kimi `BrowserCookieProvider` + `KimiSubscriptionStatParser`），凭证从浏览器 Cookie 读取 #blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-DATA-B-003] `Strategies.qwenPipeline()` 接入 `RefreshCoordinator`，bundle 安装但 Cookie 未登录时降级到 `needsConfiguration` #blocked — 依赖 [0.4.0-DATA-B-002]

### sub/main: 沉淀新 Provider 接入流程

- [ ] [0.4.0-DATA-C-000] 文档化新 Provider 接入流程（`AGENTS.md` 或 `macos/AGENTS.md`）：从「确认安装位置 → 找 dashboard API → 写 parser → 接入 pipeline → UI 验证」5 步模板，供后续 Provider 接入参考 #P2

### sub/main: 完成新 Provider 接入验收

- [ ] [0.4.0-QA-A-001] Z Code Provider：登录态正常时能在 dropdown 展示至少 1 个订阅组，下拉面板数字 / 状态灯 / bar 与其他 Provider 一致；未登录时降级到 `needsConfiguration` 不卡死
- [ ] [0.4.0-QA-A-002] 千问 Provider（实现后）：同上 #blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-QA-A-003] 文档已更新（README 列出已支持 Provider 清单 + 各 Provider 接入说明）
- [ ] [0.4.0-QA-A-004] `cd macos && swift build` / `swift run` 通过

### sub/main: 修正可用订阅计数语义

> Bug 修复：顶部「可用订阅 N/M」之前只看 `availability == .available`，导致 Kimi 红灯（worst quota 已耗尽）时 N/M 仍显示 4/4，与状态灯颜色不一致。
> 修复后 N/M 与状态灯走同一逻辑：top group worst quota `remainingFraction > 0` 才计为可用，红灯不计。

- [x] [0.4.0-UI-B-000] `DashboardState.availableCount` 改为只统计 `.available` 且 top subscription group worst quota `remainingFraction > 0` 的 snapshot；与 `ProviderSnapshot.statusColor(itemOrder:)` 的红灯判定走完全相同的逻辑（避免出现"灯红但 N/M 不动"的割裂）#bugfix — `QuotaModels.swift:availableCount`
- [x] [0.4.0-UI-B-001] `DashboardState.availabilityText` 同步标记 `@MainActor`（因 `availableCount` 需要读 `PreferencesStore.shared`，后者是 MainActor 隔离）#bugfix — `QuotaModels.swift:availabilityText`

## Phase - v0.5.0 - 发布自动化与工程卫生

> v0.5.0 不引入新功能，专注**用户能间接感知的质量门槛**与**工程卫生基础设施**：
> 发布自动化、PR 自动验证、dev 入口友好、测试基建落地。
>
> **范围说明**（本 phase 合并 `feat/price-update-date` 时由 agent 主动识别登记）：
> - **本 phase 只放用户能直接/间接感知的任务** + 工程卫生**基础设施**（CI / dev 入口 / 测试基建
>   等"持续提升代码质量"的能力）。One-time 清理（清单个 warning、挪个文件、改 `.gitignore`
>   这种一次性 housekeeping）由 cleanup PR 处理，不进 REQUIREMENTS。
> - **测试任务不进 REQUIREMENTS 顶层**。测试是所属功能任务的子任务，ID 形式为 `<parent>-test`
>   （如 `[0.4.0-DATA-A-001-test]`）。完整验收由"功能任务 + 测试子任务 + 完成定义"三者共同组成。
> - 任务是登记而非执行；执行时再单独开 worktree / 分支。

### sub/main: 提供发布自动化与 PR 验证

> 1. **修改后在本地自动打包** —— `AGENTS.md` 已要求（`./scripts/build-app.sh`），不需要 GitHub
>    代码自动化，agent 遵守 AGENTS 即可，无需本 phase 任务。
> 2. **提交后自动打包到 Release** —— 需要 GitHub Actions 自动化。
> 3. **PR 合并前自动验证** —— 工程卫生类，需要 GitHub Actions。

- [x] [0.5.0-CI-A-000] 已存在 `.github/workflows/release.yml` 在 main push 触发里加 `./macos/scripts/build-app.sh` 步骤（确保 main push 后自动产 .app 并发到 pre-release）；用户可感知：每个 commit 都自动有可下载的 .app #P1
- [x] [0.5.0-CI-A-001] `release.yml` 加 `cd site && npm ci && npm run build` 步骤，让营销主页（quotabar.ddonlien.com）跟着主仓一起更新 #P2
- [x] [0.5.0-CI-A-002] 新增 `.github/workflows/pr-check.yml`：PR 触发时跑 `swift build`（PR 合并前自动验证，避免坏改动进 main）#P1

### sub/main: 提供统一开发入口与测试基建

- [x] [0.5.0-ENG-A-000] 清掉 pre-existing Swift warning（`MiniMaxConfigProvider.swift:346` 的未使用 `prefix`、`EdgeCookieReader.swift` 的未使用 `placeholders`）；用户间接感知：build 输出干净，CI 日志少噪音 #P1
- [x] [0.5.0-ENG-A-001] `Makefile` 或 `scripts/dev.sh` 入口封装 `swift build` / `swift run` / `swift test` / `./scripts/build-app.sh` / `cd site && npm ci && npm run build`，README / AGENTS 里只引用这一个入口；用户/贡献者间接感知：上手命令更一致 #P2
- [x] [0.5.0-ENG-A-002] 根 `.gitignore` 加 `site/node_modules/` / `site/dist/` / `site/.astro/` 双保险（当前靠 `site/.gitignore` 排除，但根 ignore 双保险更稳；上次 rsync 误把这些拷到了 worktree）#P1
- [x] [0.5.0-ENG-A-003] `Package.swift` 加 `Tests/QuotaBarTests/` test target（测试用例本身作为各功能任务的 `<parent>-test` 子任务登记，不在 phase 顶层列具体测试）#P2
- [x] [0.5.0-ENG-A-004] `macos/build/latest` 改为相对软链，并由 `build-app.sh` 扫描同级时间戳构建目录后指向最新目录，避免本地绝对路径污染 Git 状态 #P1
- [x] [0.5.0-ENG-A-005] 打包产物使用用户可见名称 `Quota Bar.app`，并在 bundle 内接入最新圆角应用图标 `QuotaBar.icns` #P1

### sub/main: 完善用户可见文档入口

- [x] [0.5.0-DOC-A-000] `README.md` 的「快速开始」增补 site 子项目（`cd site && npm install && npm run dev`）的独立段落；当前 README 只在「目录结构」里提到 site/；用户可感知：能直接看到怎么本地跑 site 主页 #P2

## Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页）

> **问题**：v0.3.0-UI-A-010 落地的「订阅/数据最后有效日期」灰色标签当前值是 `quotas.map(\.resetsAt).max()`，语义上是「最晚 quota 窗口的下次重置时间」，**不是订阅到期日**。结果：
> - 只有 5h 窗口的 provider → 显示 5h 后的时间（完全不是订阅到期）
> - 5h + 周窗口 → 显示 7d 后（看起来"差不多对"，但跟真实续费日没关系）
> - 月度订阅 + 5h/周窗口 → 显示 30d 后（碰巧接近，但本质不是账单日）
>
> **解决思路**：用 headless 抓取各家订阅管理页（chatgpt.com/account、claude.ai/settings、cursor.com/dashboard 等），从 DOM 提取「续费日期 / 到期日」。比起"挨个研究私有 API"，**订阅页就是设计给用户看日期的**，一定有结构化的「下次扣费 / 到期」信息。Kimi 这类已经有 API 返回 `subscriptionBalance.expireTime` 的直接接。
>
> **找不到时**：直接 hide（`subscriptionExpiresAt = nil` → `MenuView.PlanHeader.expiresAtText` 返回 nil → UI 不显示）。**不再 fallback 到 max(resetsAt)**，因为那个值已经被验证是"乱写的"。
>
> **worktree 拆分**：每个 provider 一个独立 worktree，互不依赖；1 个 ARCH worktree 做基础架构（HARVESTER 协议 + WKWebView wrapper + fallback 改 hide）必须先落地，其余 5-6 个 provider worktree 后续并行开。

### feat/subscription-expiry: 建立订阅日期抓取基础架构

> 提供给各 provider 复用的 headless 抓取 + DOM 提取框架。Kimi 这种直接 API 返回 expireTime 的不走这个架构，但协议入口统一。

- [x] [0.6.0-ARCH-A-000] 设计 `SubscriptionDateHarvester` 协议：每个 provider 实现 `harvest(from data: Data) async throws -> Date?`，输入是抓到的页面 Data（或 WKWebView handle），输出是订阅到期日；找不到返回 nil #P1
- [x] [0.6.0-ARCH-A-001] `WKWebViewHeadlessLoader` 实现：注入 `WKHTTPCookieStore` cookie → 加载 URL → 等 `network idle` / 特定 DOM 节点出现 → 回调 `Data` 或 `String`；可在 `FetchPipeline` strategy 中复用，超时与现有 strategy 一致 #P1
- [x] [0.6.0-ARCH-A-002] 删 `ProviderSnapshot.init` 里 `quotas.compactMap(\.resetsAt).max()` fallback：找不到真实到期日时 `subscriptionExpiresAt = nil`（UI 自动不显示）；同时把 `subscriptionExpiresAt` 文档从"默认从 max(resetsAt) 推断"改成"nil = 不展示" #P1
- [x] [0.6.0-ARCH-A-003] `DashboardParser` 协议加 `parseSubscriptionExpiresAt(data: Date = Date()) -> Date?`，默认实现返回 nil；Kimi `KimiSubscriptionStatParser` 实现从 `subscriptionBalance.expireTime` 提取（这一改动给 Kimi 顺带补上）#P1
- [x] [0.6.0-ARCH-A-003-test] 给 harvester 协议 + fallback 改 hide 写单元测试：mock HTML feed 解析，验证 `subscriptionExpiresAt` 正确 / 不正确两种路径 #P1
- [x] [0.6.0-ARCH-A-001-test] `WKWebViewHeadlessLoader` 集成测试：mock URLProtocol 喂 HTML，验证 cookie 注入 + DOM ready 等待 + 超时降级 #P1

### feat/subscription-expiry: 接入 Kimi 真实订阅到期日

> Kimi 的 `GetSubscriptionStat` 响应里 `subscriptionBalance.expireTime` 可作为订阅续费日原始值，但页面语义是「下一次续费日」，UI 需要转换成「最后有效日」。历史上这个值曾被错塞到 Work quota 窗口的 `resetsAt`，需要保持额度周期和订阅日期两条语义分离。

- [x] [0.6.0-DATA-A-000] `KimiSubscriptionStatParser` 解析 `subscriptionBalance.expireTime` 后**不再塞给 Work quota 的 `resetsAt`**（Work 的 resetsAt 应该是月度窗口的滚动结束时间，跟 subscription 到期日是不同概念）#P1
- [x] [0.6.0-DATA-A-001] `KimiSubscriptionStatParser.parseSubscriptionExpiresAt(data:)` 返回 `subscriptionBalance.expireTime` 原始续费日；`BrowserCookieProvider` 按 `.nextRenewalDate` 转换成最后有效日后传给 `ProviderSnapshot.subscriptionExpiresAt` #P1
- [x] [0.6.0-DATA-A-002] Work quota 窗口的 `resetsAt` 保持 nil；`subscriptionBalance.expireTime` 仅用于 Work 行 refreshDescription，不进入额度窗口重置时间 #P1
- [x] [0.6.0-DATA-A-002-test] 单元测试：mock `GetSubscriptionStat` JSON 验证原始续费日可解析、Work quota `resetsAt` 不再等于 expireTime、最后有效日换算由 source 层负责 #P1

### feat/subscription-expiry: 接入 Codex 真实订阅到期日

> Codex (chatgpt.com) 的 `/backend-api/wham/usage` 只返回 quota 窗口，**不返回订阅到期日**。需要 headless 抓 `chatgpt.com/account/manage` 或 `chatgpt.com/settings/billing` 页面，提取「Next billing date」「Renewal date」之类 DOM 文本。

- [x] [0.6.0-DATA-B-000] `CodexHarvester` 实现：用 `WKWebViewHeadlessLoader` 加载 `https://chatgpt.com/#settings/Billing`，DOM 提取续费日期；找不到返回 nil；超时/Cloudflare challenge 失败时 source 管线降级 #P1
- [x] [0.6.0-DATA-B-001] `RefreshCoordinator` 在 Codex quota snapshot 成功后通过独立 source 管线补 `subscriptionExpiresAt`；日期失败不影响额度展示 #P1
- [x] [0.6.0-DATA-B-001-test] 单元测试：mock HTML（含"Next billing on July 25, 2026"等常见模式）验证 `CodexHarvester` 解析出正确 `Date` #P1

### feat/subscription-expiry: 接入 Claude 真实订阅到期日

> Claude (claude.ai) 的 `/api/organizations/{uuid}/usage` 不返回订阅到期日。需要 headless 抓 `claude.ai/settings/plan` 或 `claude.ai/account/billing`，提取「Next billing」「Renews on」之类。

- [x] [0.6.0-DATA-C-000] `ClaudeHarvester` 实现：加载 `https://claude.ai/new#settings/billing`，DOM 提取续费日期 #P1
- [x] [0.6.0-DATA-C-001] 通过独立 source 管线集成到 Claude snapshot enrichment #P1
- [x] [0.6.0-DATA-C-001-test] 单元测试：mock HTML 验证解析 #P1

### feat/subscription-expiry: 接入 Cursor 真实订阅到期日

> Cursor (cursor.com) 的 dashboard 走 `cursor.com/api/...`，但续费日通常在 `cursor.com/dashboard` 顶部"Plan"卡片里。需要 headless 抓页面。

- [x] [0.6.0-DATA-D-000] `CursorHarvester` 实现：加载 `https://cursor.com/dashboard`，提取"Pro plan renews on..."或类似 #P1
- [x] [0.6.0-DATA-D-001] 通过独立 source 管线集成到 Cursor snapshot enrichment #P1
- [x] [0.6.0-DATA-D-001-test] 单元测试：mock HTML 验证解析 #P1

### feat/subscription-expiry: 接入 MiniMax 真实订阅到期日

> MiniMax Web (minimaxi.com / api.minimaxi.com) 的 `coding_plan/remains` 不返回订阅到期日。需要 headless 抓 `minimaxi.com/user-center/payment/balance` 或类似。

- [x] [0.6.0-DATA-E-000] `MiniMaxHarvester` 实现：定位 MiniMax 订阅管理页 URL，提取续费日期 #P1
- [x] [0.6.0-DATA-E-001] 通过独立 source 管线集成到 MiniMax snapshot enrichment #P1
- [x] [0.6.0-DATA-E-001-test] 单元测试 #P1

### feat/subscription-expiry: 接入 Antigravity 真实订阅到期日

> Antigravity 是 Google 系的 IDE，订阅状态在 Google Cloud 控制台或 antigravity.google 域内。可能需要登录 Google account 后访问 antigravity.google/settings。

- [x] [0.6.0-DATA-F-000] `AntigravityHarvester` 实现：定位 Antigravity 订阅管理页 URL，提取续费日期；可能需要跟随重定向到 accounts.google.com 完成登录 #P1
- [x] [0.6.0-DATA-F-001] 通过独立 source 管线集成到 Antigravity snapshot enrichment #P1
- [x] [0.6.0-DATA-F-001-test] 单元测试 #P1

### feat/subscription-expiry: 调整订阅到期日展示规则

> `subscriptionExpiresAt = nil` 时 `MenuView.PlanHeader.expiresAtText` 已经返回 nil，UI 不显示。**但**需要确认：
> 1. dropdown 价格行 layout 不要因为 hide 产生跳动；
> 2. 把目前灰色的 "刷新时间未知" 文案在 quota row 里保留（那不是 subscriptionExpiresAt，是 quota resetsAt，是另一个字段）；
> 3. tooltip 提示用户"日期未配置"（可选，nice-to-have）

- [x] [0.6.0-UI-A-000] 验证 `MenuView.PlanHeader.expiresAtText == nil` 时 HStack 收缩正常（价格仍居右、不留空隙）#P1
- [x] [0.6.0-UI-A-001] 给 `expiresAtText` 加 `.help("...")` tooltip：显示「订阅续费日期」+ 完整 ISO 日期（让用户 hover 能看到精确时间）#P2

### sub/expiry: 建立订阅过期日独立 source 管线

> 用户补充：过期日和额度信息不冲突；本地安装但无付费订阅时仍可能有免费额度，应如实展示额度，同时过期日找不到就隐藏。订阅过期日不应只是额度 pipeline 的附属逻辑，而应有独立 source 层级和可追踪来源。

- [x] [0.6.0-ARCH-B-000] 抽象 `SubscriptionExpirySource` / resolver：按 provider 定义过期日 source 顺序、来源类型（API / app cache / CLI / browser API / headless DOM）、confidence 与目标 URL #P1
- [x] [0.6.0-ARCH-B-001] `RefreshCoordinator` 使用独立过期日 source resolver 补 `subscriptionExpiresAt`；即使额度 snapshot 来源是免费额度或本地安装路径，也不把“没有订阅过期日”视为额度失败 #P1
- [x] [0.6.0-ARCH-B-002] headless DOM source 使用用户确认的订阅页入口：Claude `https://claude.ai/new#settings/billing`、Codex `https://chatgpt.com/#settings/Billing`、MiniMax `https://platform.minimaxi.com/console/plan`、Kimi `https://www.kimi.com/membership/subscription?tab=quota`；GLM 暂无订阅，不接入过期日 source #P1
- [x] [0.6.0-ARCH-B-003-test] 单元测试覆盖 source registry 顺序、Kimi API 优先不走 headless、免费额度 snapshot 无过期日时仍保持 `.available` #P1

## Phase - v0.7.0 - 智谱 GLM Provider 接入（feat/glm-provider）

> **承接关系**：v0.4.0 phase 在用户电脑上已完成 zcode App 安装调研（`/Applications/ZCode.app`、bundle id `dev.zcode.app`、`~/.zcode/v2/` 目录布局、4 种 plan 标识），但 Provider 接入代码本身未落地。v0.7.0 把调研成果转为正式版任务，在 `feat/glm-provider` branch 上推进。
>
> **zcode 是什么**：智谱 BigModel Z Code（`https://zcode.z.ai`）桌面 IDE，是 opencode 的 fork/skin，走 anthropic 兼容 API；4 种 plan（`builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan`）覆盖智谱开放平台 + Z.ai 海外版两套站点。
>
> **为什么叫 GLM 而不是 zcode**：用户对外沟通时用「GLM」（智谱模型族名）覆盖度更广；内部 provider 名沿用 `zcode`（与 bundle id / config 路径一致），UI 显示名用 `Z Code`。
>
> **与 v0.6.0 第二批的关系**：v0.7.0 不属于 v0.6.0 第二批（第二批是 headless 抓订阅页拿订阅到期日）。GLM 接入是独立工作线（要做完整 provider + 套餐映射），所以单独立 phase。

### feat/glm-provider: 调研智谱 BigModel Z Code Provider 接入

> 任务继承自 v0.4.0 phase 的 `### feat/glm-provider: 调研智谱 BigModel Z Code Provider`（4 项），但每项提升到 v0.7.0 phase 顶层，确保 `feat/glm-provider` branch 推进时有稳定的 v0.7.0 编号。

- [ ] [0.7.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.zcode` 枚举值，`displayName = "Z Code"`、`brandColor`、`iconSymbol`、`bundleIdentifier = "dev.zcode.app"`、`credentialFiles = ["~/.zcode/v2/credentials.json"]`、`envVarNames = []` 等元数据补齐 #P1
- [ ] [0.7.0-DATA-A-001] `ZCodeAuthProvider` 实现：从 `~/.zcode/v2/config.json` 读启用 plan 的 API key + baseURL，对 plan endpoint 发 anthropic 兼容 API 拉 usage；解析剩余额度到 `[QuotaWindow]` #P1
- [ ] [0.7.0-DATA-A-002] 套餐映射：识别 `builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan` 4 种 plan，subscriptionGroup 按 plan 区分（每个 plan = 1 个订阅组）；价格映射到 `ProviderPricing` #P1
- [ ] [0.7.0-DATA-A-003] `ZcodeLoginRunner` + `InstallDetectorProvider`：探测 `dev.zcode.app` bundle 安装和 `~/.zcode/v2/config.json` 存在性，驱动 pipeline 串接 #P1
- [ ] [0.7.0-DATA-A-004] `Strategies.zcodePipeline()` 接入 `RefreshCoordinator`，凭证缺失时 fallback 到 Keychain / `needsConfiguration` 状态 #P1
- [x] [0.7.0-DATA-A-006] 合并 `preferences/main` 的 GLM / 智谱基础展示骨架：`ProviderKind.glm`、颜色/图标、BigModel/智谱环境变量与凭证路径、偏好设置模型页待接入展示；完整 Z Code pipeline 仍由本组未完成任务推进 #P1
- [ ] [0.7.0-DATA-A-005] site/DESIGN.md 中 `--provider-zcode` 的 brandColor 在 app DESIGN.md / QuotaModels 中同步落地（当前 web 占位 `#3866ff`，app 端选色待定）#P1

### feat/glm-provider: 集成 Z Code 菜单栏状态

> Z Code 接入后菜单栏多 bar 视图自动包含这个新 provider（无需单独代码改动，靠 `ProviderKind.allCases` 驱动）。但需要确认 menu bar 配色不冲突、bar 高度映射正确。

- [ ] [0.7.0-FE-A-000] Z Code 接入后菜单栏 status item 多 bar 自动包含；确认 5+ bar 时视觉清晰、无重叠 #P1
- [ ] [0.7.0-FE-A-001] Z Code 状态灯（brandColor）与其他 provider 在 dropdown / status bar 都正确渲染 #P1

### feat/glm-provider: 更新 Z Code 用户可见文档

- [ ] [0.7.0-DOC-A-000] README.md 的「已支持 Provider」列表追加 Z Code（含 4 种 plan 简要说明 + 安装路径）#P1

## Phase - v0.8.0 - 仓库结构适配新 Agent 模板

### sub/main: 按交付物职责重命名顶层目录

- [x] [0.8.0-DOC-A-000] 参考新的 `agent-template/AGENTS.md` 更新根 `AGENTS.md` 标准内容与项目专用内容 #docs #P1
- [x] [0.8.0-DOC-A-001] 将 macOS 原生应用目录从 `quota-bar/` 迁移为 `macos/`，并同步 README、Makefile、CI、Release 配置中的命令与路径 #docs #P1
- [x] [0.8.0-DOC-A-002] 将营销主页目录从 `web/` 迁移为 `site/`，并同步子项目文档、Vercel 配置和 CI 构建路径 #docs #P1
- [x] [0.8.0-DOC-A-003] 将 Git worktree 工作目录从 `.worktrees/` 迁移为 `worktrees/`，并通过 `git worktree move` 保持 Git 元数据一致 #docs #P1
- [x] [0.8.0-DOC-A-004] 清理 `agent-template/` 中嵌套 `.git` 和模板历史日志，仅保留模板文件与日志模板文件 #docs #P1
- [x] [0.8.0-DOC-A-005] 将根 `REQUIREMENTS.md` 与 `site/REQUIREMENTS.md` 的三级标题迁移为新模板要求的 `branch-name: feature description` 结构，保留既有稳定 ID #docs #P1
- [x] [0.8.0-DOC-A-006] 按更新后的 `agent-template/AGENTS.md` 将 worktree 目录统一为单数 `worktree/` #docs #P1
- [x] [0.8.0-DOC-A-007] 将 `main` 分支也迁入 `worktree/main/`，项目容器根目录不再作为开发工作区 #docs #P1 #cut 已验证不适合 GitHub Desktop / Agent 发现模型，改回 main 在根目录
- [x] [0.8.0-DOC-A-008] 将主仓库 Git 元数据迁入 `.repo/.git`，并修复所有 worktree 的 gitdir 指向 #docs #P1 #cut 已随 [0.8.0-DOC-A-010] 还原为根目录 `.git`
- [x] [0.8.0-DOC-A-009] 同步 README、AGENTS、REQUIREMENTS、日志中的 `.repo/` + `worktree/` 结构说明 #docs #P1 #cut 已改为 main 根目录 + 单数 `worktree/` 结构说明
- [x] [0.8.0-DOC-A-010] 将 `main` 分支恢复到项目根目录，保留其他分支在单数 `worktree/` 下，兼容 GitHub Desktop / Codex / Agent 发现模型 #docs #P1
- [x] [0.8.0-DOC-A-011] 修改 `agent-template/AGENTS.md`：`main` 默认保留在根目录，非 `main` worktree 使用单数 `worktree/` #docs #P1
- [x] [0.8.0-DOC-A-012] 按 `agent-template/app-agent-template/AGENTS.md` 将项目整理为容器目录 + `main/` + 平铺 branch worktree + `_builds/` 结构，并同步当前 `AGENTS.md` / `README.md` 参考内容 #docs #P1

## Phase - v0.9.0 - 持久化、来源索引与启动兜底

> 来自 `sub/main` 的需求登记。本阶段只在本次合并中进入需求文档，代码实现后续单独推进。
>
> **持久化边界**：
> - 可以持久化非敏感展示数据、来源索引和 last-known-good snapshot；
> - 不持久化 token、cookie、API key、refresh token 或完整个人账号标识；
> - 所有持久化文件放在 `~/Library/Application Support/QuotaBar/`。

### sub/main: 建立安全持久化模型

- [ ] [0.9.0-ARCH-A-000] 定义 Quota Bar 自有持久化目录：`~/Library/Application Support/QuotaBar/`；偏好、来源索引、last-known-good 快照都放在该目录下，不新增 `~/.quota-bar` 作为主路径 #P1
- [ ] [0.9.0-ARCH-A-001] 设计持久化 schema version 与向后兼容策略；所有持久化文件必须带 `schemaVersion`，读取失败时安全丢弃并回到实时抓取，不阻塞 app 启动 #P1
- [ ] [0.9.0-ARCH-A-002] 明确安全边界：持久化文件不得保存 token、cookie、API key、refresh token 或浏览器 Cookie 明文；敏感凭证仍只读取原始服务配置、浏览器 Cookie 或 macOS Keychain #P1
- [x] [0.9.0-SEC-A-000] App 启动时不得注册浏览器 Cookie Keychain 预授权弹窗；默认刷新链路不得主动触发浏览器密码 / 权限提示 #P0
- [x] [0.9.0-SEC-A-001] 默认禁用 SweetCookieKit 的 Chromium Keychain 解密（`BrowserCookieKeychainAccessGate.isDisabled = true`），杜绝 "Chrome Safe Storage" 密码弹窗；仅当用户在偏好设置显式选择 Chrome 浏览器来源时放开。订阅过期日 headless source 也随之默认无弹窗：优先 App 自有 WebView 会话，其次 Safari/Firefox 文件 Cookie（FDA 已授权时静默）#P0 — `AppDelegate.applyBrowserCookieKeychainPolicy`

### sub/main: 建立来源索引

- [ ] [0.9.0-DATA-A-000] 新增 provider source-index 文件，记录每个 provider 最近成功的数据来源，用于下次启动优先尝试最可能成功的 source #P1
- [ ] [0.9.0-DATA-A-001] 来源索引只保存非敏感元信息：providerKind、sourceKind、sourceId、成功时间、失败次数、最后错误摘要、相关本地路径或浏览器 profile 标识；不保存凭证内容 #P1
- [ ] [0.9.0-DATA-A-002] source-index 写入必须发生在 source 成功返回后；失败次数和最后错误摘要可更新，但不得把失败 source 提升为默认来源 #P1

### sub/main: 建立 last-known-good 快照

- [ ] [0.9.0-DATA-B-000] 新增 last-known-good 快照文件，保存每个 provider 最近一次真实刷新成功的额度、订阅状态、订阅过期时间、价格、档位、fetchedAt、sourceKind 与是否 stale 等信息 #P1
- [ ] [0.9.0-DATA-B-001] App 启动时先读取 last-known-good 快照作为 stale 初始展示，再异步刷新真实数据；UI 必须清晰标记 stale，避免误以为是最新数据 #P1
- [ ] [0.9.0-DATA-B-002] 刷新失败时可以保留 last-known-good 展示，但必须保留失败状态或 stale 标记，不能把旧快照伪装成本次成功刷新 #P1
- [ ] [0.9.0-DATA-B-003] last-known-good 快照写入前进行脱敏，不保存任何 token、cookie、API key、完整账号 ID 或浏览器 cookie 内容 #P1
- [ ] [0.9.0-DATA-B-004] 快照写入只发生在真实刷新成功或明确订阅过期状态确认后；占位 loading、未安装、纯抓取失败不得覆盖 last-known-good 快照 #P1

## Phase - v0.10.0 - 订阅过期识别与免费额度误判修正

> `sub/main` 原本使用 v0.8.0 记录 Codex 订阅过期识别；当前 `main` 已经用 v0.8.0 记录仓库结构迁移，因此合并到 main 时改登记为 v0.10.0，避免稳定 ID 冲突。
>
> **触发 bug**：用户实测发现 `~/.codex/auth.json` 的 id_token 里 `chatgpt_subscription_active_until = 2026-06-25`，但 Codex.app 在订阅过期后调 `wham/usage` 仍能拿到 200 OK，响应里的 `plan_type` 跌成 `"free"`，`rate_limit.primary_window.limit_window_seconds` 跳到 30 天，被旧 parser 错误显示成“月额度”。这说明“用 quota 数值反推订阅状态”不可靠。
>
> **本次 merge 边界**：先并入 Codex 已落地实现，修复已知 bug；所有 AI provider 的统一订阅过期识别作为后续需求登记，不在本次 merge 中扩展实现。

### sub/main: Codex 订阅过期识别

- [x] [0.10.0-ARCH-A-000] `JWTPayloadDecoder` 工具：解 JWT payload 部分（不验签，只读 base64url+JSON），失败返回 nil #P1
- [x] [0.10.0-ARCH-A-001] `OpenAIAuthPayload`：读取 `https://api.openai.com/auth` namespace 下的 planType、subscriptionActiveUntil、lastChecked、accountId、userId 等字段 #P1
- [x] [0.10.0-ARCH-A-002] `SubscriptionStatus`：区分 `.active(expiresAt)` / `.expired(lastPlan, expiredAt)` / `.free` / `.unknown` #P1
- [x] [0.10.0-ARCH-A-003] `CodexSubscriptionInspector`：从 `~/.codex/auth.json` 解 id_token → 映射成 `SubscriptionStatus`；失败一律返回 `.unknown`，不反推 #P1
- [x] [0.10.0-DATA-A-000] `CodexAuthProvider.fetchSnapshot` 在发 wham/usage 前先调 `CodexSubscriptionInspector.inspect()`；过期 / free 时返回 `availability: .subscriptionExpired(plan, expiredAt)` 的 marker snapshot #P1
- [x] [0.10.0-DATA-A-001] `CodexDashboardParser.parse` 对 `plan_type == "free"` 返回 nil，防止 free 月额度被解析成付费额度窗口 #P1
- [x] [0.10.0-DATA-A-002] `BrowserCookieProvider.fetchSnapshotImpl` Codex 路径在发请求前先调 `CodexSubscriptionInspector`，过期 / free 时返回 marker snapshot #P1
- [x] [0.10.0-DATA-A-003] `ProviderAvailability` / `QuotaFetchError` 新增 `.subscriptionExpired(plan, expiredAt)`，并在 UI / 状态栏 / fetch priority 中处理 #P1
- [x] [0.10.0-DATA-A-004] `MenuView.PlanSection` 对 `.subscriptionExpired` 只显示灰标提示，不渲染 quota rows #P1
- [x] [0.10.0-DATA-A-005] `StatusBarController` 对 `.subscriptionExpired` 显示 “已过期” tooltip，并以 0% bar 占位 #P1
- [x] [0.10.0-QA-A-000] 单元测试覆盖 JWT decode、auth payload、active/expired/free/unknown 状态、Codex parser free 防御与 expired marker 行为 #P1

### sub/main: 所有 AI Provider 统一订阅过期识别

- [ ] [0.10.0-DATA-B-000] 梳理所有已接入 provider 的权威订阅状态来源优先级：本地 auth / app cache / CLI / browser API / headless DOM；不要只依赖 quota 数值反推订阅是否有效 #P1
- [ ] [0.10.0-DATA-B-001] 为 Claude、Cursor、Kimi、MiniMax、Antigravity、GLM 等 provider 设计与 `CodexSubscriptionInspector` 等价的 inspector 或 source 规则；明确 free / expired / unknown / active 的判定边界 #P1
- [ ] [0.10.0-DATA-B-002] 统一处理“免费额度仍可用但付费订阅已过期”的 UI 语义：区分免费额度展示、付费订阅过期提示、以及真正的抓取失败 #P1
- [ ] [0.10.0-DATA-B-003] 为所有 provider 增加防御性 parser：当 dashboard 明确返回 free / expired / unpaid / trial-ended 等状态时，不把免费或降级额度误标成付费订阅额度 #P1
- [x] [0.10.0-DATA-B-004] MiniMax `coding_plan/remains` / `mmx quota` 返回 `no active token plan subscription`（HTTP 200 + 非 0 status_code）时映射为 `notSubscribed`（订阅已到期/未订阅），不再显示「待配置」或抓取失败 #P1 — `MiniMaxCLIProvider.indicatesNoActiveSubscription`
- [ ] [0.10.0-QA-B-000] 为统一订阅过期识别补测试矩阵：active、expired、free、unknown、免费额度存在、dashboard 字段缺失、字段 schema 变化 #P1

### sub/main: 分组分层获取方案落地（5 agent × 4 信息）

> 用户要求：现有 5 个 provider（Codex / Kimi / MiniMax / Antigravity / Z Code）的 4 种信息
> （安装情况、额度、过期日、档位和费用）都能正确获取，且用户最多只需在系统设置里做一次
> 常规操作（授予 Full Disk Access）。层级顺序：本地 API/RPC → CLI → 浏览器 Cookie（静默）→
> App 内 WebView 授权（一次登录，永久静默）。

- [x] [0.10.0-ARCH-B-000] `FetchPipeline.runSequential` 支持分层合并：首个成功来源做基底 snapshot，后续 strategy 只为缺失层（quota scope / plan）补数据；`expectedQuotaScopes` 声明 provider 完整额度的 scope 集合（Kimi = work + code）#P0 — `FetchPipeline.mergeLayers`
- [x] [0.10.0-ARCH-B-000-test] 分层合并测试：work-only 基底合并 CLI code 窗口、基底失败回退、同 scope 不重复追加 #P1 — `FetchPipelineLayeredMergeTests`
- [x] [0.10.0-ARCH-B-001] `SubscriptionExpiryResolver`：snapshot 已带日期直接采用（不再为已知日期跑 headless）；headless source 优先 App 自有 WebView 会话（`WKWebsiteDataStore.default()`，由 WebView 授权窗口写入），浏览器 Cookie 退居其次 #P0
- [x] [0.10.0-UI-C-000] dropdown 中「有额度但缺订阅到期日、且日期依赖 headless 订阅页」的 provider，价格左侧显示「授权获取日期」可点击引导，打开 App 内 WebView 登录一次后自动获取 #P1 — `MenuView.PlanHeader.canOfferWebAuthorizationForDate`
- [x] [0.10.0-ARCH-B-002] App WebView 会话桥接到**额度层**：`AppWebViewSessionCookieReader` 读 `WKWebsiteDataStore.default()`，与 `BrowserCookieProvider` 组合复用全部 dashboard endpoint / parser；作为 Codex / Claude / Kimi / MiniMax 额度管线的最后一层默认启用（无弹窗）。Claude 由此获得默认唯一的额度路径（organizations → usage）#P0 — 用户反馈「claude/antigravity 用 webview 授权后依旧没有额度」的修复
- [x] [0.10.0-ARCH-B-003] `SubscriptionExpirySource` 支持**可执行的 browserAPI source**（`SubscriptionExpiryAPIRequest`）：用会话 Cookie（App WebView 会话优先，浏览器 Cookie 兜底）调 JSON API 提取日期。Codex 注册 `accounts/check` 的 `entitlement.expires_at` 为 P1，headless 账单页（hash 路由 SPA，DOM 提取长期 nil）降为兜底 #P0
- [x] [0.10.0-ARCH-B-004] `WKWebViewHeadlessLoader` 增加 SPA settle 延迟：didFinish 后等 2s 再提取 outerHTML，缓解 hash 路由页面 didFinish 时目标内容未渲染的问题 #P1
- [x] [0.10.0-ARCH-B-005] `QuotaFetchError.fallbackPriority`：`subscriptionExpired` / `notSubscribed`（服务端权威订阅状态）提升到最高优先级，管线全失败时不被权限/凭证类错误覆盖成「待配置」#P1
- [x] [0.10.0-DATA-B-005] MiniMax 增加**真实 CLI 命令层** `MiniMaxCommandProvider`：执行 `mmx quota show --output json`（非 TTY 已验证），解析 remains 形状输出与 `{"error":...}` 包裹（no active subscription → notSubscribed）；GUI 不继承 shell PATH，按 Homebrew / `~/.local/bin` 候选路径查找 #P1 — 呼应「所有 CLI 路径都应该是 CLI 里执行命令」
- [x] [0.10.0-UI-C-001] accessory app 补 `NSApp.mainMenu`（App + Edit 菜单）：修复 WebView 授权窗口 / 偏好设置输入框无法 Cmd+V 粘贴（无 Edit 菜单则快捷键无处派发）#P0 — `AppDelegate.installMainMenu`
- [x] [0.10.0-UI-C-002] 恢复 dropdown「偏好设置...」菜单项（`Cmd+,` → `PreferencesWindowController.shared.show()`）；preferences/main 手动合并进 main 时该菜单项被漏掉，注释还停留在 beep 占位时代 #P0 — 复检 v0.3.0-PM-A-006

### sub/main: AGY 真实 CLI 层 + Claude 额度修复 + 获取方案审计

> 用户用 `agy` 进入交互 CLI、`/usage` 查看额度演示了真实操作路径；同时反馈 Claude webview 授权后仍无额度；并指出 README 矩阵存在同列多个同优先级（Codex 两个 P2、GLM 两个 P2 两个 P3 等）的错误，要求全面审计矩阵与实现一致性。

- [x] [0.10.0-DATA-B-006] `AntigravityCLISessionProvider`：IDE / 已运行 agy 进程都不可用时，拉起临时 `agy` 交互会话（`/usr/bin/script` 提供 PTY）、复用其本地 RPC（委托 `AntigravityDashboardProvider(.cli)`）取结构化额度，成功或超时后立即终止会话；接入 antigravity 管线排在 `antigravity-cli` 之后、keychain 之前 #P0 — 不驱动 `/usage` TUI 文本解析（`agy --print "/usage"` 实测会被当自然语言 prompt 消耗额度，明确排除）
- [x] [0.10.0-DATA-B-007] `ClaudeDashboardParser` 改用真实响应形状：`five_hour`/`seven_day`/`seven_day_sonnet`/`seven_day_opus` 顶层字段（经 CodexBar `ClaudeWebAPIFetcher` 与 Claude-Usage-Tracker `ClaudeAPIService` 两个独立参考实现交叉验证），修复此前只认 `usage`/`limits` wrapper key、对真实响应恒返回空数组的 bug；`usageURL(from:)` 增加多 org 优先级（chat 能力 > 非 api-only > 第一个）避免选中纯计费 org #P0 — 根因确认：Claude 一直没额度不是弹窗/授权问题，是 parser 形状写错
- [x] [0.10.0-DATA-B-008] CLI 命令探测支持**候选命令名列表**（`ProviderKind.cliCommands`）：MiniMax 实际命令是 `mmx`（旧 `minimax` 保留兼容）、Antigravity 实际命令是 `agy`（旧 `antigravity` 保留兼容），候选同类同优先级、命中即止；`InstallDetectorProvider.findCommand` 增加 Homebrew / `~/.local/bin` 等候选目录直查（GUI app 的 launchd PATH 不含这些路径，此前 `which` 单独查找会失败）#P0
- [x] [0.10.0-DOC-A-001] README 四张矩阵表全面审计重写：统一「同列内优先级唯一、同格内多个同类文件/命令共享格优先级」规则，修复 Codex 两个 P2、GLM 两个 P2 两个 P3 等冲突；Provider 获取表改为反映实际统一探测顺序（凭证文件 → App Bundle → CLI → 环境变量）；额度/过期日/档位表按当前实现逐格核对（Kimi GetSubscription、MiniMax mmx 已验证、Codex accounts/check P1、Claude 待验证标记等）#P1

### sub/main: Claude 配置 / CLI / RPC 三项验证与实现

> 用户要求验证 README 里 Claude 的三处「待验证」（配置文件→API、CLI、本地 RPC），并提示可参考已下载的 CodexBar/ClaudeBar/Claude-Usage-Tracker 三个参考仓库交叉核实。核实后发现均可转为确定结论并直接实现，而不只是更新文档。

- [x] [0.10.0-DATA-B-009] `ClaudeOAuthUsageProvider`：读 `~/.claude/.credentials.json` 的 `claudeAiOauth.accessToken`/`subscriptionType`，直调 `GET https://api.anthropic.com/api/oauth/usage`（`anthropic-beta: oauth-2025-04-20`），响应字段与 web session 端点一致，复用抽出的 `ClaudeUsageWindowParser`；接入 Claude 管线为新 P1（配置文件 → API），排在 App WebView 会话之前，401→missingCredentials、429→transient #P0 — 端点/字段经 CodexBar `ClaudeOAuthUsageFetcher` 源码交叉验证，未接触本机 Keychain
- [x] [0.10.0-DATA-B-010] `ClaudeAuthStatusCLIProvider`：执行 `claude auth status --json`（实测确认非交互、结构化、无副作用），失败/未登录抛 `missingCredentials`；只贡献订阅档位（`subscriptionType`），不伪造额度；接入管线为 OAuth provider 之后的 CLI 层，供凭证文件缺失（如仅 Keychain 存储）时兜底档位 #P1
- [x] [0.10.0-DATA-B-011] 修正 `KeychainProvider` 对 Claude 的 service/account 猜测：`defaultKeychainService` 从虚构的 `"com.anthropic.claude"` 改为经 CodexBar 源码确认的真实 Keychain generic password service 名 `"Claude Code-credentials"`；`defaultKeychainAccount` 支持返回 `nil`（service-only 匹配，不再要求固定 account——Claude Code 写入的 account 属性是运行时动态值，无法硬编码）；`KeychainProvider`/`hasToken` 的 account 参数改为可选，其余 provider 行为不变 #P1
- [x] [0.10.0-DATA-B-012] `ProviderPricing` 新增 Claude Pro 价格映射（$20/月，官网公开价确认）；Max（5x/20x）等更高档位的 `subscriptionType` 字符串未经真实账号验证，不猜测映射 #P2
- [x] [0.10.0-DOC-A-002] README 额度/过期日/档位表按上述验证结果更新：Claude 配置→API 从「待验证」改为已验证 P1（含端点/字段说明）；本地 RPC 从「待验证」改为「跳过：已核实无本地 RPC 可用」（`claude gateway` 是企业 auth/telemetry 代理非用量接口）；CLI 命令行从「待验证」改为「跳过额度：已核实无结构化额度 CLI」+ 档位表新增 P3 `claude auth status`；过期日表「配置文件/token payload」从「待验证」改为「跳过：`expiresAt` 是 access token 有效期非订阅到期日」（与 Kimi OAuth 同类陷阱）；「CLI 指令」从「待验证」改为「跳过：已核实不返回到期日」#P1

### sub/main: 面向全网用户的 hardcoded 路径 / 假设审计

> 用户明确本应用是面向全网用户售卖的商用软件，不是只给开发者本人用；要求不管本机环境如何，按理论上可行的方案把实现做好，并检查全部实现有没有 hardcoded 路径。审计范围：全部 Provider 实现、CLI 路径探测、Keychain 查询、货币/价格假设、个人信息残留。

- [x] [0.10.0-ARCH-C-000] 新增 `CLICommandLocator` 共享工具：两级解析——先查一批常见固定安装目录（Homebrew 双架构、MacPorts、用户级 `~/.local/bin` 等），命中失败再退化到登录 shell 解析（`$SHELL -lc 'command -v <cmd>'`，source 用户真实 shell 配置，覆盖 nvm / asdf / pnpm 等任意版本管理器或自定义 PATH）；按命令名做进程内缓存（一次 App 生命周期只解析一次）；拒绝含 shell 元字符的命令名，防止拼进 `-lc` 字符串被注入 #P0 — 此前 `MiniMaxCommandProvider`/`AntigravityCLISessionProvider`/`ClaudeAuthStatusCLIProvider`/`InstallDetectorProvider` 各自维护一份不完整、互相不一致的固定路径清单，只覆盖 Homebrew 默认前缀，漏掉 nvm/asdf/pnpm/MacPorts 等真实用户会用到的安装方式
- [x] [0.10.0-ARCH-C-001] `MiniMaxCommandProvider` / `AntigravityCLISessionProvider` / `ClaudeAuthStatusCLIProvider` 改为默认走 `CLICommandLocator`（显式传入候选路径时仍走原候选列表，保持测试确定性）；`InstallDetectorProvider.findCommand` 同步改为委托 `CLICommandLocator`，移除原本因未设置 PATH 而形同虚设的裸 `which` fallback，四处路径探测收敛为单一实现 #P0
- [x] [0.10.0-DATA-B-013] 修正 `ClaudeAuthStatusCLIProvider` 的路径漂移 bug：existence 检查用的候选列表和实际执行的 `runProcess` 各自硬编码了一份独立列表，可能不一致；改为解析路径后作为参数传给 executor（与 MiniMax/Antigravity 两个 provider 已有模式一致）#P1
- [x] [0.10.0-DATA-B-014] `KeychainProvider.readToken()` 的 service-only（account=nil）查询路径改为 `kSecMatchLimitAll` 取全部匹配项后按 `kSecAttrModificationDate` 选最近修改的一条，而不是 Keychain 内部枚举顺序里任意一条——覆盖重装 / 多版本 CLI 各自写入同 service 不同条目的场景 #P1
- [x] [0.10.0-QA-B-000] 审计确认无需改动的项：`NSHomeDirectory()` 全部用法均动态取当前用户主目录（非 hardcode）；代码/测试/README/REQUIREMENTS 无残留个人用户名、邮箱、真实 org ID；`PreferredCurrency`/`ExchangeRateProvider` 的 USD/CNY 双档设计是既有文档化范围，非 bug；未发现任何架构（arm64/x86_64）分支判断 #P2
- [ ] [0.10.0-DATA-B-015] `EdgeCookieReader` 硬编码只读 `Microsoft Edge/Default` 单一 profile，多 profile（如工作/个人分账号）用户可能登录在非 Default profile 中；浏览器 Cookie 路径当前已是显式启用的最后兜底层，非默认路径，暂不提升优先级 #P2 #deferred — 呼应既有 `0.2.0-DATA-B-008` 多浏览器/多 profile 选择的 deferred 项，一并留待后续处理

### sub/main: 修复 Claude 额度真正的根因（子进程环境裁剪）+ Keychain 凭证兜底

> 用户反馈打包后 Claude 仍然没有额度，并指出参考的三个仓库都不需要 WebView，最多是系统设置里做一次性授权。实测复现：不是 WebView/授权设计的问题，是 `ClaudeAuthStatusCLIProvider`/`MiniMaxCommandProvider` 生成子进程时把环境变量整体替换成只有 `HOME`（或 `HOME`+`TERM`），导致 `claude auth status` 读不到本机真实登录态（`loggedIn` 变成 `false`）——跟 WebView、跟浏览器都没关系。

- [x] [0.10.0-DATA-B-016] 修复 `ClaudeAuthStatusCLIProvider` / `MiniMaxCommandProvider` 的子进程环境裁剪 bug：`process.environment` 此前整体替换成 `["HOME": ...]`（或加 `TERM`），改为继承 `ProcessInfo.processInfo.environment` 完整环境后只覆盖必需的个别键；已用 `env -i HOME=... USER=... claude auth status --json` 实测复现根因（只给 HOME 时 `loggedIn: false`，补上 `USER` 后恢复 `loggedIn: true` + 正确 `subscriptionType`）#P0 — `AntigravityCLISessionProvider` 未设置 `process.environment`（默认继承完整环境）不受影响；`TTYCommandRunner.runRaw` 一直是正确的合并写法，本次两处新代码复刻了旧的错误写法
- [x] [0.10.0-DATA-B-017] `ClaudeOAuthUsageProvider` 增加 Keychain 凭证兜底：`~/.claude/.credentials.json` 不存在或解析失败时，改读 Keychain `"Claude Code-credentials"`（`ClaudeKeychainCredentialsReader`，取最近修改条目，同 0.10.0-DATA-B-014 的选择逻辑），同一套 JSON 解析复用两个来源；读取时**不设** `interactionNotAllowed`，允许系统弹出一次性「始终允许」授权（读取另一 App 写入的 Keychain 条目的标准流程，等价用户所说的"系统设置里开"，与浏览器 Cookie Keychain 静默降级的 0.9.0-SEC-A-001 是不同凭证来源，不适用同一条禁令）#P0 — 让只有 Keychain、没有凭证文件的机器（本机即是）也能不经 WebView 拿到真实额度

### sub/main: Claude statusLine hook 额度捕获（不依赖 Keychain 的 app 化方案）

> 用户指出 3 个参考仓库 + 新提供的 ping-island、vibe island 都能"像 Codex 一样用 app/配置拿额度"，要求不用 Keychain，可以用 FDA/辅助功能等系统权限。查 ping-island 源码（`HookInstaller.swift`）发现真正机制：Claude Code CLI 的 `statusLine` hook 会把包含 `rate_limits` 的 JSON 喂给用户配置的 statusLine 命令——这是 Claude Code 自己的官方能力，不需要 OAuth token、不需要 Keychain、不需要子进程。本机已安装的 Vibe Island（同类闭源商用 App，`~/.vibe-island/bin/vibe-island-statusline`）用完全相同的手法验证了这一机制真实有效。

- [x] [0.10.0-ARCH-D-000] `ClaudeStatusLineHookInstaller`：把一个极小脚本（不依赖 `jq`，只用 POSIX `grep`/`sed`）注册为 `~/.claude/settings.json` 的 `statusLine.command`，捕获 Claude Code 自己渲染终端状态栏时携带的 payload（含 `rate_limits`）到本地缓存文件；若用户已有非本安装器写入的 statusLine 配置则不覆盖、返回 `.skippedExistingStatusLine`（与 ping-island `isManagedStatusLine` 逻辑一致）；提供 `install()`/`uninstall()`，路径全部可注入以便测试不触碰真实文件 #P0
- [x] [0.10.0-ARCH-D-001] `ClaudeStatusLineUsageProvider`：读取上述缓存文件，解析 `rate_limits.{five_hour,seven_day}`（`used_percentage`/`utilization` 同义字段，`resets_at` 支持 epoch 数字/ISO8601/缺失三种形态，字段形状经 ping-island 测试夹具与本机 Vibe Island 真实缓存 `~/.vibe-island/cache/rl.json` 双重交叉验证）；缓存超过 6 小时视为陈旧，退化到下一层（配置文件/Keychain → API），不展示过期数字 #P0 — 接入 Claude 管线为新 P1（在 OAuth 之前），零权限、零子进程，是本次「不用 Keychain、app 自己能拿到」诉求里唯一完全不涉及 Keychain 的路径
- [x] [0.10.0-PM-A-013] 「模型」偏好页新增「Claude Code 额度捕获（实验）」开关（`PreferencesStore.claudeStatusLineHookEnabled`），显式 opt-in 才会修改用户的 `~/.claude/settings.json`；开启成功/跳过（已有自定义 statusLine）/失败三种结果都有对应提示文案；关闭时只移除本安装器写入的 statusLine 引用，不动用户自己的配置 #P1
- [x] [0.10.0-DOC-A-003] README 额度获取表新增「本地 hook 缓存（Claude 专属）」行，标注为 Claude 新的默认 P1（原配置/凭证 → API 降为 P2，App WebView 会话降为 P3），注明经 ping-island 源码与本机 Vibe Island 真实缓存交叉验证 #P1

### sub/main: Preferences provider 列表遗漏 + dropdown Claude 消失架构 bug + 分层诊断日志 + dropdown 显示规则重写

> 用户实测发现两个真实 bug：Preferences「模型」页 provider 列表漏了 Antigravity；dropdown 里 Claude 彻底不显示（比"没额度"更严重）。同时要求新增结构化分层获取诊断日志，并按详细规格重写 dropdown 名称栏/额度栏的显示逻辑。

- [x] [0.10.0-BUG-A-000] `ModelsSettingsView.visibleProviders` 补上 `.antigravity`（此前只有 codex/minimax/kimi/claude/glm 五项，agy 完全没有开关行）#P0
- [x] [0.10.0-BUG-A-001] 修复 dropdown 里 Claude 完全不显示：根因是 `FetchPipeline.runSequential` 在只有 tier-only CLI 兜底层成功（`quotas=[]`）、且后续额度层全部失败时，仍返回 `availability=.available` 的"幽灵成功" snapshot；`RefreshCoordinator.applyProviderResult` 对 `.available` 原本判定 `keepAfterApply = !quotas.isEmpty`，导致这条 snapshot 被直接移除。`.available` 只可能来自至少一个 strategy 成功，不存在"什么都没有"的空 available，改为始终 `keepAfterApply = true`；额度缺失的展示交给 dropdown 新的"打开 WebView 授权"提示（0.10.0-UI-B-000）兜底，不再让整个 provider 消失 #P0
- [x] [0.10.0-ARCH-E-000] 新增 `ProviderCheckLog` actor + `ProviderCheckLogStore`：按用户规格实现结构化分层获取诊断日志，格式 `<yyyy.mm.dd_hh.mm.ss> - <ProviderName>: <CheckStep>, <MethodName>: <Result>`；CheckStep 对应 README 四层获取矩阵（Provider 获取/额度获取/过期日获取/档位与费用获取）；按 provider 缓冲、该 provider 本轮工作完全结束才整段落盘，保证同一 provider 的行始终连续输出，check step / method name 按真实调用顺序自然满足；结果里明示缓存命中/失效、成功获取到的信息、失败原因 #P0
- [x] [0.10.0-ARCH-E-001] 确认并保留现有并发模型：`RefreshCoordinator` 对安装探测和 pipeline+过期日阶段都用 `withTaskGroup` 做 provider 间并发；单个 provider 内部（`FetchPipeline.runSequential`、`SubscriptionExpiryResolver.resolve`）都是严格 for 循环顺序执行——已经符合"provider 内顺序检查、provider 间并发检查"，本次只新增日志埋点，不改变原有并发架构 #P0
- [x] [0.10.0-ARCH-E-002] 埋点覆盖三处：`InstallDetectorProvider.detectSources`（App Bundle / CLI 命令 / 环境变量 / 凭证文件逐项命中与否，含"上次成功来源缓存"命中/失效提示）、`FetchPipeline.runSequential`（每次 strategy 尝试按 `supportedLayers ∩ {quota, plan}` 各记一条，一次 fetch 同时贡献额度+档位时记两条）、`SubscriptionExpiryResolver.resolve`（每个 expiry source 尝试的成功/失败明细）#P0
- [x] [0.10.0-PM-A-014] Preferences 新增「日志」sidebar 页（`DiagnosticsSettingsView`），只读展示 `ProviderCheckLogStore` 落盘内容，支持刷新/复制全部/清空 #P1
- [x] [0.10.0-UI-B-000] dropdown 名称栏重写（`PlanHeader`）：左侧 `<ProviderName> · <TierName>`（TierName 缺失时省略"·"）；右侧按"TierName 缺失 → 到期日缺失 → 都齐全"三级 cascade 决定显示"打开 WebView 授权"提示还是真实到期日+价格；价格缺失时整组（货币符号/费用/周期）直接不渲染，不再显示"—"占位；到期日显示不再要求价格同时存在（原逻辑错误地把两者耦合）#P1
- [x] [0.10.0-UI-B-001] dropdown 额度栏重写：`.available` 但 `quotas.isEmpty`（tier-only 兜底层成功、额度层还没拿到）时渲染新增的 `QuotaAuthPromptRow`——有 WebView 授权入口的 provider 显示蓝色可点击"打开 WebView 授权"，没有的显示灰色"暂无额度数据"；不再是空白 VStack #P1
- [x] [0.10.0-CLEAN-A-000] 删除已无调用方的 `ProviderSnapshot.displayName`（原 `"\(kind.displayName) \(subscriptionTier)"` 拼接，被 0.10.0-UI-B-000 拆成独立的 ProviderName/TierName 两个 Text 后不再需要）#P2

### sub/main: 日志上线首日实测反馈——排序 bug、Claude 价格 bug、dropdown 待配置态显示规则

> 上线新日志当天用户实测发现：Z Code 等 `.needsConfiguration` provider 在 dropdown 里同时显示原始技术性 reason 文本和 WebView 授权按钮，观感混乱；`.notSubscribed` 应该用统一"未订阅或订阅已过期"文案而不是拼原始 reason；日志页标签"获取日志"应简化为"日志"。用户直接读了一段真实日志，进一步发现两个此前没被注意到的真实 bug（这正是新增诊断日志的价值——第一次实测就抓出真问题）。

- [x] [0.10.0-BUG-A-002] `FetchPipeline.orderedStrategies` 删除"按上次成功来源缓存重排"逻辑：原实现只要任一层有缓存的 preferred source，就把所有 `supportedLayers` 覆盖满三层的 strategy 整体提到最前，与各自在数组里的声明位置无关。实测复现两处真实错误：Kimi 的 `kimi-webview`（声明最后、本该是最后一道兜底）排到 `kimi-auth`（声明第二、真正的常规 CLI OAuth 层）前面；Claude 的 `claude-auth-status-cli`（P3 兜底）因为是"上次成功来源"排到 `claude-statusline`（声明第一、零权限 P1）前面。**中间态**先改成恒定按数组声明顺序执行、完全不看缓存；用户随后指出这也不对（见 0.10.0-BUG-A-004），最终版本是"缓存优先试、失败才完整走声明顺序" #P0
- [x] [0.10.0-BUG-A-003] `ClaudeAuthStatusCLIProvider.parseStatusOutput` 补上 `ProviderPricing.localizedMonthlyPrice(kind: .claude, tier:)` 调用：此前硬编码 `monthlyPrice: nil`，导致只靠这条 CLI 兜底层拿到档位（如 "Pro"）的用户永远看不到价格，即使 `ProviderPricing` 里已经有 `(.claude, "pro") → $20` 的映射。价格是从档位名字查静态公开定价表，不是"伪造额度"，跟这里保持为空的 quotas 是两回事 #P0
- [x] [0.10.0-UI-B-002] dropdown `.needsConfiguration` 分支重写：不确定是否订阅时（拿数据失败、凭证问题等），有 `webAuthorizationURL` 的 provider 只显示清爽的「打开 WebView 授权」按钮，不再同时堆一段原始技术性 reason 文本；没有授权入口的才退回显示原始 reason #P1
- [x] [0.10.0-UI-B-003] dropdown `.notSubscribed` 分支重写：改为统一显示"未订阅或订阅已过期"（灰色，无按钮），不再拼接原始 reason；这个状态只在服务端明确告知"没有有效订阅"时触发，跟"不清楚是否订阅"的 `.needsConfiguration` 是两种不同确定性，不应该用同一种"待配置 · reason"文案 #P1
- [x] [0.10.0-PM-A-015] Preferences sidebar「获取日志」标签简化为「日志」#P2

### sub/main: 缓存优先级语义纠正 + dropdown 隐藏按钮与 Preferences 开关状态统一

> 用户纠正 0.10.0-BUG-A-002 的"完全不看缓存、恒定按声明顺序"过于绝对：正确语义是"每层如果有缓存，优先检查缓存；缓存没有返回结果，才按声明顺序完整跑一遍（不是默认就重跑）"。同时指出 dropdown 的隐藏（叉）按钮应该对所有没拿到真实额度的 provider 一致提供，且点击效果必须等同于 Preferences 里把该 provider 关掉——不能是"dropdown 里看不见了、后台还在正常刷新"的假隐藏。

- [x] [0.10.0-BUG-A-004] `FetchPipeline.effectiveOrder`/`cachedFirstStrategy`：只有当本轮所需的**全部**层（额度 + 档位）的「上次成功来源索引」一致指向同一个 strategy id 时，才把它提到最前单独先试一次；试完无论成败，剩余 strategy 依然按 pipeline 声明顺序完整跑一遍（跳过刚试过的那个，避免同一轮重复调用）。层与层之间不一致、或任一层完全没有缓存记录，都视为"信息不全"，直接走完整声明顺序，不取巧——这也是为什么 `quotaOnlySourceCannotShadowFullSource` 这条既有测试还能通过：它只给 quota 层记了缓存，跟 plan 层不一致。新增两条回归测试锁定"层一致时优先且提前于声明顺序"和"缓存来源本轮失败后仍完整 fallback"两种场景 #P0
- [x] [0.10.0-UI-B-004] dropdown 隐藏（叉）按钮从"只在 `.needsConfiguration` 出现"改为"所有没有真实额度数据的 provider 都出现"（`.needsConfiguration` / `.notSubscribed` / `.subscriptionExpired` / `.available` 但 `quotas.isEmpty`），已有真实额度的 provider 不提供（没有"不想用"的诉求，误触代价也更高）#P1
- [x] [0.10.0-ARCH-F-000] 删除 `RefreshCoordinator.hiddenKinds`（内存态、手动刷新会被 `clearHidden()` 清空的临时隐藏集合），改为统一读写 `PreferencesStore.isEnabled(kind:)`（持久化）。`hide(kind:)` 现在直接调用 `PreferencesStore.setEnabled(false, for:)`；`runRefreshCycle` 的 `activeProviders` 过滤也改读同一个持久化状态。dropdown 隐藏按钮和 Preferences「模型」页的开关现在是同一份状态的两个入口，任一边改动都会真正阻止该 provider 发起请求，而不是只在 UI 上视觉隐藏 #P0
- [x] [0.10.0-ARCH-F-001] `RefreshCoordinator` 新增 `applyEnabledFilterChange()`，订阅 `.quotaPreferencesDidChange` 通知：立即把刚被关闭的 provider 从 `state.snapshots` 摘掉；刚被重新启用但 `state.snapshots` 里还没有它的 provider，立刻触发一次 `refreshNow()`，不用等下一个 5 分钟自动周期 #P1

### sub/main: dropdown 全局规则纠正 + 日志页体验 + 日志内容可读性统一

> 用户截图指出一批具体问题：日志页清空后 ScrollView 收缩变窄；停留在日志页时新记录不会自动出现，要切一次 tab 才行；Claude 明明没拿到额度却是绿灯（状态灯全局规则错误）；灰色/蓝色 WebView 授权提示的下划线不统一；并贴了一段真实日志，指出 Kimi 的额度/档位两层看起来"交叉"、`kimi-desktop-token` 这类 MethodName 看不出属于哪一类来源、Z Code 额度层只跑了一次、以及追问 Claude 的 OAuth/Keychain 到底为什么读不到凭证。

- [x] [0.10.0-UI-C-000] `DiagnosticsSettingsView` 的日志 `ScrollView` 内容 `VStack` 加 `.frame(maxWidth: .infinity, alignment: .leading)`：清空后只剩一行短提示文字时，原来没有这个约束会让整个 ScrollView（进而整个设置页）收缩到刚好包住那行字的宽度 #P1
- [x] [0.10.0-ARCH-G-000] 新增 `Notification.Name.providerCheckLogDidChange`，`ProviderCheckLogStore.append`/`clear` 落盘后在主线程 post；`DiagnosticsSettingsView` 订阅它调用 `reload()`——停留在日志页时，刷新周期写入的新记录会实时出现，不用切一次 tab 才触发 `onAppear` 重新读取 #P1
- [x] [0.10.0-BUG-A-005] `ProviderSnapshot.statusColor` 的 `.available` 分支修复：`primarySubscriptionGroupWorstQuota` 为 nil（tier-only 兜底层成功、额度层还没拿到，如 Claude 常见的 CLI-only 状态）时，原来用 `?? 1.0` 兜底把"不知道剩多少"当成"剩 100%"画绿灯；改为这种情况下返回灰色"未知"灯，跟 loading/needsConfiguration 同一套语义 #P0
- [x] [0.10.0-UI-C-001] 统一 WebView 授权提示的下划线规则：header 里两处灰色引导（TierName 缺失 / 到期日缺失）保持下划线；`QuotaAuthPromptRow`（额度栏蓝色引导）去掉误加的 `.underline()`——颜色本身已经表明可点击，蓝色 + 下划线是重复强调，之前两者没统一 #P1
- [x] [0.10.0-ARCH-G-001] 诊断日志层输出顺序修正：`FetchPipeline.logAttempt` 原来用 `relevantLayers.sorted(by: { $0.rawValue < $1.rawValue })` 按字母序排（"plan" < "quota"），导致同一次成功调用先输出「档位与费用获取」再输出「额度获取」，跟额度层排 README 四层矩阵第 2 层、档位排第 4 层的既定顺序自相矛盾，看起来像"交叉"。改为固定用 `[.quota, .plan]` 显式顺序 #P0
- [x] [0.10.0-ARCH-G-002] 诊断日志 MethodName 统一：新增 `ProviderSourceKind.checkLogLabel`/`SubscriptionExpirySourceKind.checkLogLabel`，把 Provider 获取/额度获取/档位与费用获取/过期日获取四层的 MethodName 统一改成同一套分类词汇（"配置/凭证 → API"「CLI 命令」「本地 App / RPC」「App WebView 会话」「浏览器 Cookie」「Keychain」等，对应 README 五级来源排序的用词），不再直接用 `kimi-desktop-token` 这类单看名字猜不出类别的 strategy id 当 MethodName；具体 id 移到 `result` 里（格式："来源 <id>：<结果>"）#P0
- [x] [0.10.0-BUG-A-006] 修正 `QuotaProviderStrategy.sourceKind` 对 `"minimax-cli"` 的误分类：这个 id 是历史命名遗留，实际实现读 `~/.mmx/config.json` 的 API key 直调 `coding_plan/remains`，并不真的执行 `mmx` 命令（真正的 CLI 层是另一个 id `minimax-mmx-cli`），原来的 `id.contains("cli")` 通配会把它错分类成"CLI 命令"；新增日志用到 `checkLogLabel` 后这个误分类会直接暴露给用户，借这次统一顺手修掉 #P1
- [x] [0.10.0-INVESTIGATE-A-000] 排查 Claude OAuth/Keychain 凭证读取失败：用户机器上 `claude auth status --json`（CLI 层）能成功返回 `subscriptionType: pro`，说明本机确实登录有效；但 `ClaudeOAuthUsageProvider` 的文件路径（`~/.claude/.credentials.json` 不存在，已确认）和 Keychain 路径（`security find-generic-password -s "Claude Code-credentials"` 确认条目真实存在，service/account 与代码预期完全匹配）都读不到有效 accessToken。代码走读未发现查询逻辑本身的 bug。最可能的解释：`build-app.sh` 用 ad-hoc 签名（`--sign -`）+ 固定 `--identifier`重签，但 ad-hoc 签名本身在每次重新构建后 CDHash 会变化，可能导致 macOS 对 Keychain 第三方条目的"始终允许"信任判定无法跨构建持久化——与已知的 TCC/Accessibility 权限持久化问题（v0.12.0 Developer ID 签名规划）是同一根因类别 #P1

### sub/main: 对照参考项目源码，Claude Keychain 读取改走 `security` CLI

> 用户直接问"你发的 4 个开源项目是怎么获得 claude 额度的"，要求对照 CodexBar / ClaudeBar / Claude-Usage-Tracker / ping-island 的真实源码，而不是继续靠猜。读了 CodexBar 的 `docs/KEYCHAIN_FIX.md` 和 `ClaudeOAuthCredentials.swift`、ClaudeBar 的 `ClaudeCredentialLoader.swift`，找到了此前 0.10.0-INVESTIGATE-A-000 一直没验证到的具体可执行修复。

- [x] [0.10.0-BUG-A-007] `ClaudeKeychainCredentialsReader.readCredentialsJSON()` 从直接调 `SecItemCopyMatching`（`kSecMatchLimitAll` + `kSecReturnData` + `kSecReturnAttributes` 一次性查询）改为 `Process` 调 `/usr/bin/security find-generic-password -s "Claude Code-credentials" -w`，参考 ClaudeBar 的真实实现（`ClaudeCredentialLoader.loadFromKeychain`）。关键原因：`/usr/bin/security` 是 CDHash 永不变的 Apple 签名系统二进制，用户「始终允许」的信任记在它的身份上，不受本项目 ad-hoc 签名（`--sign -`）每次重新构建后 CDHash 变化的影响——而直接调 Security.framework 时信任是记在自己 App 的签名身份上的，这正是 0.10.0-INVESTIGATE-A-000 排查时怀疑的根因。CodexBar 的 `docs/KEYCHAIN_FIX.md` 也独立佐证了"不同查询形状 macOS 分别记忆授权"这一点（它们用了另一种解法：把 metadata-only 查询和单条 secret-data 查询拆成两次不同形状的调用）#P0
- [x] [0.10.0-ARCH-H-000] `ClaudeOAuthUsageProvider` 新增 `keychainReader` 注入点（默认走真实 `readCredentialsJSON`），修复了顺手改动暴露的测试隔离问题：原来两个"应该抛 missingCredentials"的测试因为直接调用真实 Keychain 读取，在已登录 Claude Code 的开发机上会意外读到真实凭证、进而对 `api.anthropic.com` 发起真实网络请求；现在测试显式注入返回 nil 的 reader #P0
- [x] [0.10.0-ARCH-H-000-test] 新增 `ClaudeKeychainCredentialsReaderTests`：验证对一个真实不存在的占位 service 名调用 `readViaSecurityCLI` 返回 nil（跨机器确定性成立，不依赖开发机是否登录过 Claude）#P1

### sub/main: 日志格式二次调整 + Claude 额度条标题统一 + 更新功能现状确认

> 用户反馈日志格式"冒号逗号混排"不好读，要求改成管道分隔的层级/方案/结果/内容；截图指出 Claude 的额度条显示"Session"/"Weekly"前缀，跟 Codex 只显示周期标签不一致；询问 Preferences 更新功能现状（要求走 v0.11.0 记录的 ad-hoc 签名 workaround，不是 v0.12.0 的 Developer ID 方案）。

- [x] [0.10.0-ARCH-I-000] `ProviderCheckLog` 行格式从 `<Provider>: <Step>, <Method>: <Result>`（冒号逗号混排，成败判断混在自由文本里）改成 `<Provider> | <Step> | <Method> | <成功/失败/跳过> | <详细内容>`：新增独立的 `Outcome` 枚举（`.success`/`.failure`/`.skipped`），跟自由文本的 `detail` 彻底分开，一眼就能扫到成败，不用从长句子里找"成功"/"失败"字样。改动覆盖 `InstallDetectorProvider`/`ProviderFetchStrategy`/`SubscriptionExpirySources` 三处全部约 22 个调用点；`ProviderCheckLogTests` 同步更新 + 新增 `.skipped` 状态的落盘测试 #P0
- [x] [0.10.0-BUG-A-008] Claude 额度条标题统一：`ClaudeUsageWindowParser`（`DashboardEndpoints.swift`）和 `ClaudeStatusLineUsageProvider` 的 `five_hour`/`seven_day` 窗口 title 从 `"Session"`/`"Weekly"` 改成空字符串，跟 Codex 的 `primary`/`secondary` 窗口一致——这两个窗口只是同一份额度的两个时间维度，不是 Kimi Work/Code、MiniMax General/Video 那种需要区分的不同 scope，不应该显示前缀名称；legacy 的 `seven_day_sonnet`/`seven_day_opus` 分支保留各自的区分标题（它们是真正不同的 scope：不同模型的独立额度池）。相关测试改用 `periodSeconds` 而不是 `title` 区分窗口 #P1
- [x] [0.10.0-DOC-A-004] 确认 Preferences 更新功能（`UpdateChecker.swift` + `AboutSettingsView.swift` + `install-update.sh` + `release.yml`）已在 v0.11.0 完整落地并接入真实 `DDonlien/quota-bar` 仓库，release workflow 也确认真实产出 `.dmg` 资产；本轮未发现需要新增的缺口，仅做现状确认，不重复建设 #P2

### sub/main: 更新检查改为纯版本号比较 + dropdown 隐藏按钮实时刷新 + GLM/Z Code 开关关联修复

> 用户实测发现三个问题：装好最新构建后「关于」页仍提示"有更新"（根因见 0.10.0-DOC-A-004 之后的时区 bug 修复只是治标）；用户明确指出更新判断不该依赖发布/构建时间，同一版本重复打包不该被当成"有更新"，要求改成纯版本号比较，并给出 `vX.Y.Z-<git-sha>` 格式规则、X.Y.Z 由 Agent 维护；dropdown 隐藏（叉）按钮点击后要关闭再打开 dropdown 才生效；Preferences「模型」页的 Z Code/GLM 开关与 dropdown 隐藏状态没有关联（只有 MiniMax 是好的）。

- [x] [0.10.0-ARCH-J-000] `UpdateChecker.swift` 彻底移除按发布/构建时间比较的设计：删除 `UpdateChannel` 枚举与 `UpdateCandidate.channel`/`publishedAt` 字段、`buildDate(fromBundleVersion:)`、`pickUpdate` 的 `currentBuildDate` 参数和 10 分钟缓冲逻辑；`SemanticVersion.init?(tag:)` 改为剥离首个 `-` 之后的任意后缀（如 git short sha）再解析 `X.Y.Z`；`pickUpdate` 简化为纯语义化版本号比较——取候选中 `X.Y.Z` 最高且严格大于当前版本的那个，同一 `X.Y.Z`（不管 sha 是否不同）不算更新 #P0
- [x] [0.10.0-ARCH-J-001] 新增仓库根目录 [`VERSION`](../VERSION) 文件（内容 `0.10.0`）作为版本号唯一权威来源；`build-app.sh` 改为读取该文件 + `git rev-parse --short HEAD`，始终写入 `CFBundleShortVersionString = "<VERSION>-<sha>"`，移除原来的 `VERSION` 环境变量 + 空值走 `"1.0"` 的双通道分支；`.github/workflows/release.yml` 同步移除 `workflow_dispatch` 的手动 `version` 输入，push main / 手动触发都统一走"读 VERSION 文件 + 当前 sha 打 tag"这一条路径，不再产出 `nightly-<sha>` 与 `vX.Y.Z` 两种 tag #P0
- [x] [0.10.0-ARCH-J-002] `AboutSettingsView` 移除 `version == "1.0"` 的 nightly 特殊展示分支：所有版本都是真实 `X.Y.Z-sha`，"已是最新版本"直接显示 `v\(version)` #P1
- [x] [0.10.0-DOC-A-005] `AGENTS.md` 新增「版本号维护规则」小节：`VERSION` 文件权威来源、Agent 按改动量级判断 PATCH/MINOR/MAJOR 的启发式、每次改动 `VERSION` 必须在 agent-log 里写明原因；`README.md`「更新策略」章节同步改写，不再提 nightly/stable 两条通道 #P1
- [x] [0.10.0-BUG-A-009] `RefreshCoordinator` 的 `.quotaPreferencesDidChange` 订阅从 `.receive(on: RunLoop.main)` 改为 `.receive(on: DispatchQueue.main)`：`RunLoop.main` 默认用 `.default` run loop mode，dropdown 的 `NSMenu` 鼠标 tracking 期间是 `.eventTracking` mode，`.default` 模式排的任务要等菜单关闭才会跑，这正是"点了叉不会立刻隐藏，要关闭再打开 dropdown 才生效"的根因；`hide(kind:)` 额外同步直接调用一次 `applyEnabledFilterChange()`，不完全依赖异步通知链路的时机 #P0
- [x] [0.10.0-BUG-A-010] `ModelsSettingsView.visibleProviders` 把幽灵 kind `.glm`（从未接入任何真实 pipeline）换成实际在跑的 `.zcode`——此前 Preferences 切 "GLM" 开关和 dropdown 隐藏 "Z Code" 是两个完全独立的 `ProviderOverride` 记录，互不影响；`providerVendor(.zcode)` 的展示文案从 `"Z Code"` 改为更准确的 `"智谱 / Z.ai"` #P0
- [x] [0.10.0-QA-A-001] `UpdateCheckerTests` 全面重写以匹配新 API：删除所有 channel/发布时间相关测试（`stablePreferredOverNightly`、`nightlyRecommendedByPublishDate`、`parsesBuildDate` 等），新增覆盖"git sha 后缀被忽略"、"发布时间更新但版本号更低的候选不会被选中"、"相同 X.Y.Z 不同 sha 不算更新"三个场景 #P1

### sub/main: 诊断日志误报"额度获取失败"修正

> 用户贴了一段真实日志问"为什么 claude、antigravity 额度一会有一会没有，日志里都是失败"。排查确认额度数据本身没有被覆盖或丢弃——`FetchPipeline.mergeLayers` 是纯追加逻辑，已经拿到的额度不会被后续失败的来源清空；dropdown 显示的其实是刷新过程中某一刻的瞬时状态（Antigravity 的 `antigravity-cli-session` 要拉起一个临时 `agy` 会话，整轮加上过期日 resolver 耗时近 20 秒，比 Codex/Kimi 这类本地文件直读的 provider 慢一个数量级，中途截图容易看到还没刷新完的旧状态）。但排查过程中确实发现日志本身有一处误报：分层合并阶段，某个来源只是为了补档位（plan）层被重试，如果它失败，日志会连带记一条"额度获取失败"，即使额度早就被更早的来源满足——这正是用户看到"日志里都是失败"这种误导观感的来源之一。

- [x] [0.10.0-BUG-A-011] `FetchPipeline.logAttempt` 新增 `onlyLayers` 参数：分层合并阶段（`runSequential` 的补层分支）调用时传入 `missing`（本轮实际缺失、值得重试的层），不再无条件按 `strategy.supportedLayers` 全量记录；这样一个只支持补档位场景下失败的来源，不会在「额度获取」步骤留下一条虚假的失败记录（额度早已被更早的来源满足）。首次尝试（`merged == nil` 时）不受影响，此时确实在为全部所需层探测 #P1 — `ProviderFetchStrategyTests.mergeBranchFailureOnlyLogsMissingLayer`

### sub/main: 「刷新间隔」偏好从未真正生效

> 用户反馈"我发现刷新间隔改了不会同步真的生效"。排查确认这是一个从未接通的架构性 bug：偏好设置的 Picker 只写入 `PreferencesStore.preferences.refreshIntervalSeconds` 并 persist，但 `RefreshCoordinator.refreshInterval`（自动刷新循环真正读取、dropdown「自动刷新 N 分钟」文案也读取的字段）是构造函数传入的独立值，从来没有跟这个偏好同步过——不仅运行中改动不生效，连**应用启动时**都不会读取上次保存的偏好（`StatusBarController` 构造 `RefreshCoordinator` 时没有传 `refreshInterval` 参数，永远吃构造函数自己的默认值 5 分钟）。也就是说这个偏好设置从实现以来就是摆设，不是这次改动引入的回归。

- [x] [0.10.0-BUG-A-012] `StatusBarController.init` 默认构造 `RefreshCoordinator` 时显式传入 `refreshInterval: PreferencesStore.shared.preferences.refreshIntervalSeconds`，应用启动时会真正读取上次保存的偏好，不再永远固定 5 分钟 #P0
- [x] [0.10.0-BUG-A-013] `RefreshCoordinator` 的 `.quotaPreferencesDidChange` 订阅新增 `applyRefreshIntervalChange()`：检测到 `PreferencesStore.preferences.refreshIntervalSeconds` 变化时同步更新 `self.refreshInterval`，并重启自动刷新循环（`stop()` + `start()`）让新间隔立刻生效，不需要等当前这轮 `Task.sleep` 走完、也不需要重启 app #P0 — 未新增自动化测试：`PreferencesStore.shared` 是硬编码单例、直接读写真实 `preferences.json`，没有像其余 store 那样支持注入临时目录，强行测试会触碰用户真实偏好文件，跟本次会话已确立的"不在测试里碰真实用户状态"原则冲突；已用 `swift build`/`swift test`（181 全过）验证不引入回归，逻辑本身很直接（读值、比较、必要时重启）

### sub/main: 偏好设置摆设字段全面审计 + WebView 授权修复 + 移除浏览器 Cookie 文件读取

> 用户要求排查代码仓库里是否还有类似"刷新间隔"那种看着接通实际没用的摆设设置。审计（含一个只读排查 subagent）发现：`providerOverrides.isForcedVisible`、`incidentMonitoringEnabled`、`advanced` 的 `currencyCode`/`showResetDates` 都是没有 UI、没有消费方的纯死字段；`advanced.providerTimeoutSeconds` 有意图但从未接通到 `RefreshCoordinator.providerTimeout`（同一类"两份独立副本"问题）；`browserSource`（Cookie 来源选择）唯一的运行时效果被一个没有 UI 的环境变量挡死，对真实用户完全不可达。用户确认后要求：接通 `providerTimeoutSeconds`、删除纯死字段，并追问 browserSource 对应的浏览器 Cookie 文件读取路径是否已经被 App WebView 授权会话取代——核实后确认两者功能等价，用户要求直接删除浏览器 Cookie 文件读取整条路径，只保留 WebView 会话。
>
> 在执行删除前，用户报告了一个更紧急的真实 bug："打开 WebView 后即使登录了 Claude/Antigravity，仍然提示需要打开 WebView 授权，拿不到到期日/档位/金额"。排查确认这不是数据丢失（`FetchPipeline.mergeLayers` 纯追加，不会清空已成功的层），而是三个真实缺口：(1) Antigravity 的 pipeline 里根本没有注册任何 WebView 会话额度/档位策略——`missingTierNeedsAuth`/`QuotaAuthPromptRow` 只看 `webAuthorizationURL != nil` 就展示授权引导，对 Antigravity/Z Code 这种登录了也拿不到档位的 provider 是个兑现不了的承诺；(2) `WebAuthorizationController` 关闭授权窗口后不会触发任何刷新，用户登录完看到的还是登录前的失败状态；(3) 没有 `WKUIDelegate` 处理登录页常见的 `window.open()` 弹窗式 SSO，可能导致某些登录流程卡在半途。

- [x] [0.10.0-BUG-A-014] `ProviderKind.webViewQuotaCapableKinds` 新增静态集合（`WebAuthorizationController.swift`），显式声明哪些 provider 真的注册了能解出额度/档位的 WebView 会话策略（codex/claude/minimax/kimi）；`MenuView.PlanHeader.missingTierNeedsAuth`、`QuotaAuthPromptRow`、`.needsConfiguration` 分支三处判断都改为同时检查这个集合，不再对 Antigravity/Z Code 展示一个登录了也没用的"打开 WebView 授权"引导 #P0
- [x] [0.10.0-BUG-A-015] `WebAuthorizationController` 关闭主授权窗口时 post 新通知 `.webAuthorizationWindowDidClose`；`RefreshCoordinator` 订阅并调用 `refreshNow()`，登录完关掉窗口立即触发一次刷新，不用等 5 分钟自动周期或自己想起来手动刷新 #P0
- [x] [0.10.0-ARCH-K-000] `WebAuthorizationController` 新增 `WKUIDelegate` 实现（`createWebViewWith`/`webViewDidClose`），承接登录页用 `window.open()` 发起的 SSO 弹窗（尤其 Google 账号登录常见）；此前没有这个 delegate，WebKit 会静默丢弃这类弹窗请求，脚本以为窗口打开了，实际登录流程可能卡在半途 #P1
- [x] [0.10.0-ARCH-K-001] 彻底移除浏览器 Cookie 文件读取路径：删除 `FilesystemCookieReader`（Safari/Chrome/Firefox 真实文件读取，基于 SweetCookieKit）、`EdgeCookieReader.swift`（SQLite 直读）、`BrowserSourcePreference`/`browserSource` 偏好及其 UI、`browserCookieStrategiesEnabled`/`QUOTABAR_ENABLE_BROWSER_COOKIE` 环境变量开关、`AppDelegate.applyBrowserCookieKeychainPolicy()`、`Strategies.swift` 四个 pipeline 里的 `-cookie`/`-edge` 策略注册；`SubscriptionExpiryResolver`/`WKWebViewHeadlessLoader` 的浏览器 Cookie 兜底分支一并移除，只保留 App WebView 会话（`AppWebViewSessionCookieReader`）单一路径；`Package.swift` 移除 `SweetCookieKit` 依赖。核实过这条路径此前被环境变量挡死、对真实用户不可达，且和 App WebView 会话功能完全重叠，删除无回归风险 #P1 — 更新 `CodexAuthProviderInspectorThrowTests.swift`/`SubscriptionExpirySourcesTests.swift` 的调用签名，删除已整体过时的 `WKWebViewHeadlessLoaderTests.swift`（3 个测试全部针对被删除的浏览器 Cookie 入口路径）
- [x] [0.10.0-CLEAN-A-001] 删除纯死代码：`ProviderOverride.isForcedVisible`（无 UI、无消费方）、`incidentMonitoringEnabled`（同上）、`AdvancedPreferences.currencyCode`/`showResetDates`（同上）及各自的 getter/setter #P2
- [x] [0.10.0-BUG-A-016] 接通 `advanced.providerTimeoutSeconds`：新增 `ProviderTimeoutOption` 离散选项（10/15/20/30 秒，跟 `RefreshIntervalOption` 同一设计）+ `PreferencesStore.setProviderTimeout`/`currentProviderTimeoutOption`；`GeneralSettingsView` 新增「Provider 刷新超时」Picker；`StatusBarController`/`RefreshCoordinator` 启动时读取、运行中通过 `applyProviderTimeoutChange()` 实时同步——此前这个字段有意图（默认值 30，`RefreshCoordinator.providerTimeout` 默认值却是不同步的 10）但从未接通，跟 `refreshIntervalSeconds` 是同一类 bug #P1

### sub/main: dropdown 授权文案统一 + Preferences 新增 API Key 配置入口

> 用户看到 dropdown 里 Antigravity/Z Code 直接展示原始技术性报错（"Antigravity HTTP 500: {...}"、"BigModel Start 可用，但未返回额度数值；builtin:..."），追问"为什么 agy/opencode/zcode 不显示打开 WebView 授权"，并给出标准：不能走 WebView 授权的 provider，应该统一显示"在 Preferences 中通过 API Key 授权"或"未获取到授权"两种灰字之一，不能再暴露原始 reason。同时指出 Preferences「模型」页的"获取模式"文案应该如实反映实现，并要求给支持 API Key 的 provider（参考 Zed 的"已配置/Reset"交互，视觉沿用本页原生 macOS 26 风格）在 Preferences 里加一行真正的手动输入入口——不只是 MiniMax，Z Code 也要有（用户贴的 Zed 截图里 GLM/Z.ai provider 正好也是纯 API Key 模式）。

- [x] [0.10.0-BUG-A-017] `MenuView` 的 `.needsConfiguration` 分支重写为三级判断（替换原来"MiniMax 特判内联输入框 / else 展示原始 reason"的二分支）：`apiKeyCapableKinds` → 灰字"在 Preferences 中通过 API Key 授权"；`webViewQuotaCapableKinds` → 保留原有蓝色可点击"打开 WebView 授权"；两者都不支持（Antigravity/opencode 等）→ 灰字"未获取到授权"，不再拼接原始技术性 reason（HTTP 状态码 JSON、内部错误链等只留在诊断日志里）#P0
- [x] [0.10.0-ARCH-L-000] 新增 `ProviderKind.apiKeyCapableKinds = [.minimax, .zcode]` 静态集合（跟 `webViewQuotaCapableKinds` 同一维护模式，新增/移除某 provider 的手动 key 支持时必须同步改这里）#P0
- [x] [0.10.0-ARCH-L-001] 新增 `ZCodeManualKeyStore`（`ZCodeAuthProvider.swift`）：Quota Bar 自己独占的 `~/Library/Application Support/QuotaBar/zcode-api-key.json`，供没装官方 Z Code CLI、只想手动粘贴 key 的用户使用；`ZCodeAuthProvider.configPaths` 把它排在最前，复用现有 `flattenStrings`/`isLikelyAPIKey` 通用解析逻辑识别，不需要额外解析代码 #P1 — `ZCodeAuthProviderTests`：missing-by-default、save/read 掩码显示、拒绝空 key 三个新测试
- [x] [0.10.0-PM-A-016] 「偏好设置 → 模型」页新增「API Key 配置」区块（`APIKeyConfigRow`），MiniMax 和 Z Code 各一行：展示"已配置 · 掩码 key"/"未配置"状态 + "配置/重置"按钮，点开后是原生 `SettingsRow` 风格的输入框（复用 dropdown 已有的 `APIKeyTextField`）；交互参考 Zed 的 provider 设置页（用户提供截图），视觉不复刻、沿用本页其余行的 macOS 26 原生风格。同步删除 dropdown 里原来 MiniMax 专属的内联输入框 `MiniMaxKeyInputField`（连带贯穿 5 层 View 的整条 `onSaveKey` 回调链），入口统一收敛到 Preferences #P0
- [x] [0.10.0-ARCH-L-002] 新增 `.providerCredentialsDidChange` 通知：Preferences 里保存 API key 成功后 post，`RefreshCoordinator` 订阅并 `refreshNow()`，不用等自动刷新周期——跟 `.webAuthorizationWindowDidClose` 同一类"用户刚做完授权动作应该立刻看到结果"的诉求 #P1
- [x] [0.10.0-DOC-A-006] 全面核对 `ModelsSettingsView.providerAccessModes` 跟 `Strategies.swift` 实际 pipeline 是否一致（用户反馈"这一页应该如实显示我们支持的获取模式"）：Codex/Kimi 的 "CLI" 改成更准确的 "Config"（默认 pipeline 没有真实 CLI 子进程执行）；Claude/Antigravity 补上遗漏的 "Keychain"；MiniMax/Z Code 统一用 "API" 标注——现在这个词对应一个真实可操作的能力（上面新增的手动输入入口），不再只是描述性标签 #P1

### sub/main: 日志页刷新按钮 + 灰字精简 + 并发架构核实

> 用户反馈三点：「日志里的刷新按钮没用」；「Provider 刷新超时」/「刷新间隔」下方的灰色说明文字不需要；诊断日志"现在是全刷新完了才会出来，其实应该逐条输出的"。同时贴了一段真实日志追问"claude又获取不到额度了"——Antigravity 单独耗时 31 秒（`antigravity-cli-session`），其余 6 个 provider 的日志行全部标着同一秒的时间戳，看起来像是被 Antigravity 卡住、全部堆到一起才出来。

- [x] [0.10.0-BUG-A-018] 「偏好设置 → 日志」页的「刷新」按钮此前只是重新读一遍已经落盘的日志文件——如果后台没有恰好在点击前跑完一轮真实刷新，点了跟没点一样。改名「立即刷新」，新增 `.manualRefreshRequested` 通知，`RefreshCoordinator` 订阅并调用 `refreshNow()`；日志页本身已经在监听 `.providerCheckLogDidChange`，新日志写入时会自动展示，不需要按钮自己重读 #P0
- [x] [0.10.0-CLEAN-A-002] 删除「通用」页「刷新间隔」/「Provider 刷新超时」两行下方的说明性灰字（用户反馈不需要，设置项名称本身已经足够清晰）#P2
- [x] [0.10.0-INVESTIGATE-A-001] 排查"诊断日志全刷新完才出来、其余 provider 都卡到 Antigravity 完成才显示"的疑似并发 bug：用 `log stream` 抓取真实 unified log，在本机对同一批 provider 单独触发一轮刷新做对照实验，实测 `withTaskGroup` 里全部 7 个 provider 的 "▶️ start pipeline" 确实在同一毫秒内并发发起，opencode/zcode/kimi/minimax/claude/codex 各自独立在 0.05–2.6 秒内完成并各自 flush 落盘——`RefreshCoordinator`/`FetchPipeline` 的并发设计和逐 provider 落盘逻辑本身没有 bug，只有 Antigravity 因为要拉起临时 `agy` 会话轮询确实需要约 30 秒。用户贴的那段日志之所以"全部堆在同一秒"，最可能的原因是当时同一台机器上同时跑着 2-3 个 Quota Bar 实例（本轮会话过程中多次直接观测到），各自的自动刷新周期互相竞争 CPU/子进程/共享磁盘文件，造成偶发的多秒延迟，不是代码层面的序列化 bug；已在过程中发现并核实一处真实但影响很小的代码坏味道（`AntigravityCLISessionProvider.agyPIDs()` 用同步阻塞的 `Process.waitUntilExit()`，没有像 `CLICommandLocator.locate` 那样包一层后台 continuation），评估后判断修复它需要把 `ManagedSession`/`SessionLauncher` 整条接口改成 async（牵动测试注入点），而这两次 `pgrep` 调用本身只有几十毫秒、不足以解释观测到的数十秒延迟，收益不确定、风险不小，本轮不做，记录为已知的小项债务 #P2 — 结论：不需要代码修复，建议用户平时只保留一个 Quota Bar 实例运行
- [x] [0.10.0-INVESTIGATE-A-002] 排查"claude 又获取不到额度"：贴的日志显示 `claude-oauth` 因为 Anthropic 服务端限流失败（"Claude usage 端点限流，稍后重试"，瞬时状况非 bug），`claude-webview` 因为 App 内 WebView 会话没有登录态失败（"未登录"），`claude-auth-status-cli` 只贡献档位（Pro/¥136）没有额度；顺手核实了日志里完全没出现 `claude-keychain` 这一行的原因——`QuotaProviderStrategy.supportedLayers` 对含 "keychain" 的 id 只声明 `[.provider]`（`Strategies.swift:42-44`），FetchPipeline 判断"额度层缺失时是否值得重试这个来源"时因为 `.quota` 跟 `[.provider]` 不相交直接 `continue` 跳过，不会调用 `fetch()`，自然也不会有日志——这是刻意设计（Keychain 只能证明凭证存在，从来生成不了额度数字），不是遗漏的 bug，不需要改 #P2 — **注：本条"claude-webview：未登录 = 状态事实非 bug"的结论已被下一条 `0.10.0-BUG-A-019` 推翻，是真 bug，见下条**

### sub/main: claude-webview「未登录」误报的真正根因——WKWebsiteDataStore 冷启动未预热

> 用户对上一条 `0.10.0-INVESTIGATE-A-002` 的结论明确反驳，贴出一段覆盖 11:06–11:58（约 52 分钟、50+ 轮刷新）的完整日志：`claude-webview` 连续约 50 分钟每轮都报"未登录"，用户确认自己全程已经在 App 内 WebView 登录过；直到用户手动重新打开一次登录窗口之后，`claude-webview` 才在当天 11:58:05 首次成功。用户同时提出疑问："之前的某个版本 Claude 能完全正常获取额度、即使不依赖 WebView"，怀疑本轮会话引入了回归。

- [x] [0.10.0-BUG-A-019] 根因定位：全 App 范围内，除了 `WebAuthorizationController.openAuthorization` 这一次性登录窗口外，没有任何代码会创建 `WKWebView` 实例；而 `RefreshCoordinator.start()` 在 `StatusBarController` 初始化时就立即触发第一轮刷新（`AppDelegate.applicationDidFinishLaunching` → `StatusBarController()` → `coordinator.start()`），也就是说冷启动后很可能一次 `WKWebView` 都没创建过，`WKWebsiteDataStore.default()` 背后的 WebKit 网络进程/Cookie 存储从未被真正初始化，`httpCookieStore.allCookies()`（`AppWebViewSessionCookieReader`/`BrowserCookieReader.swift:40`）因此长期停留在"进程未就绪"的空态，即使磁盘上早已持久化了真实登录 Cookie——这跟用户描述的现象（已登录但读不到、手动重开登录窗口后突然恢复）完全吻合。修复：新增 `WebKitSessionWarmup`（`WKWebViewHeadlessLoader.swift`），在 `AppDelegate.applicationDidFinishLaunching` 里于 `StatusBarController()` 构造之前，先创建一个不可见（frame `.zero`、不挂窗口）的 `WKWebView` 并 `await` 一次 `httpCookieStore.allCookies()`，强制该 data store 提前完成初始化——效果等价于用户手动打开一次登录窗口，但不需要用户参与，且发生在第一轮刷新的 Cookie 读取之前 #P0
- [x] [0.10.0-INVESTIGATE-A-003] 排查用户提出的"回归"疑虑："我什么都没改，但之前的版本 Claude 不依赖 WebView 也能正常获取额度"：贴的日志显示 `claude-oauth` 的失败原因在 11:56:27 从"限流，稍后重试"变成了"Claude OAuth token 已过期，请重新 claude login"——这是本地 OAuth token 真实过期（需要用户重新 `claude login`），是账号/凭证的自然状态变化，不是本项目代码在本轮会话里引入的回归。合理的完整解释：用户本地 OAuth token 在今天之前一直有效，`claude-oauth` 一直单独就能覆盖额度，`claude-webview` 这条本来就存在的冷启动 bug 全程处于"从未被真正需要过、所以从未被注意到"的潜伏状态；今天 token 过期后，`claude-oauth` 第一次真正失效，`claude-webview` 变成唯一还有希望的层，这个潜伏已久的 bug 才第一次变得"要命"、被用户观测到——不是回归，是同一个一直存在的 bug 第一次有了被暴露的条件。已在上条一并修复；同时建议用户重新执行一次 `claude login` 刷新真实 OAuth token（`claude-oauth` 仍然是最直接、最快的额度层，WebView 只是兜底）#P1

### sub/main: dropdown「未获取到授权」误报 + 授权补救优先级规则重新定义

> 用户看到 Antigravity 订阅到期当天，dropdown 显示"未获取到授权"，指出这不合理——Antigravity 明明是"没有额度"（订阅过期），而不是"没有登录"，且质问"同样的代码，昨天还能获取到授权"。借这个具体案例，用户完整定义了一套新的 dropdown 额度提示规则：(1) 任何途径获得额度就如实显示；(1.1) 非授权途径明确判定"已过期/未订阅"时展示对应定论文案（`.subscriptionExpired`/`.notSubscribed`，MiniMax 现状正确）；(2) 所有非授权途径都试过仍无额度时，才展示授权途径引导，且按 FDA（未实现不展示）> WebView > API 的优先级展示第一个这个 provider 真正支持的补救入口；(3) 只有当所有该 provider 支持的授权途径都已确认完成授权但仍无额度时，才展示"没有额度信息"这类终态文案。

- [x] [0.10.0-BUG-A-020] 定位 Antigravity 具体误报根因：`antigravity-cli`/`antigravity-cli-session` 返回的 HTTP 500（`GetCascadeModelConfigData() is nil`）在 `AntigravityDashboardProvider` 里映射成 `QuotaFetchError.transient`（模糊错误，不是明确的"订阅已过期"信号，不满足用户规则 1.1 的"额度信息明确已过期"标准），`RefreshCoordinator.availabilityFallback` 对 `.transient` + 已检测到 App 安装的情况统一映射成 `.needsConfiguration`；而 `MenuView` 的 `.needsConfiguration` 分支此前对"两种授权能力都不支持"的 provider 一律展示"未获取到授权"——但 Antigravity 既不是 `webViewQuotaCapableKinds`（登录窗口只服务到期日抓取，不产出额度，见 `webViewQuotaCapableKinds` 顶部说明）也不是 `apiKeyCapableKinds`，也没有 FDA，对这个 provider 来说根本不存在任何授权补救动作可以提示用户去做——"未获取到授权"是个兑现不了的承诺 #P0
- [x] [0.10.0-ARCH-L-003] 新增 `ProviderKind.availableAuthRemediationTiers`（`WebAuthorizationController.swift`）：按用户定的 FDA > WebView > API 优先级，只列出这个 provider 真正实现了的补救 tier（目前 FDA 未实现，永远为空）。`MenuView` 的 `.needsConfiguration` 分支和 `QuotaAuthPromptRow`（`.available` + 空 quotas 的兄弟状态，此前只判断 WebView、完全没考虑 API Key，MiniMax 落到这个分支时会静默漏掉 API 引导）统一改用这个属性做展示决策：列表第一项是 `.webView` → 「打开 WebView 授权」按钮；`.apiKey` → 「在 Preferences 中通过 API Key 授权」；列表为空 → 不再展示任何"去授权"文案，改成跟 opencode 现有展示一致的诚实文案"暂无额度数据"。同时修正了此前 `.needsConfiguration` 分支里 API 判断排在 WebView 判断前面的顺序（跟用户"WebView 优先于 API"的规则相反，之前会让 MiniMax 一律先展示 API 引导、永远不会展示 WebView 授权按钮）#P0 — 范围说明：只实现了"按优先级展示第一个可用 tier"，没有实现"如果优先级更高的 tier 已确认完成授权但仍无额度，就自动升级展示下一个 tier"这层更细的判断（那需要单独建模"每个 tier 是否已完成授权"的状态，`QuotaFetchError`/`ProviderAvailability` 目前还没有这个维度），先按优先级固定展示第一个 #P1
- [x] [0.10.0-INVESTIGATE-A-004] 顺手核实了一处无关但真实存在的问题：跑 `swift test` 时，`ProviderFetchStrategyTests.swift` 里的测试 stub（"quota-source"/"plan-filler"）没有给 `ProviderCheckLog` 注入独立临时文件，写穿了真实用户机器上的 `~/Library/Application Support/QuotaBar/provider-check.log`——已用 `spawn_task` 单独派发（`task_9a5b6e04`），后续由用户在独立会话里跑完：`FetchPipeline` 新增 `checkLog: ProviderCheckLog = .shared` 注入点，测试改成显式构造独立临时文件的 `ProviderCheckLog`，删掉了原来靠 `ProviderCheckLog.resetForTesting()` 直接清空 `.shared` 内存缓冲区的黑魔法；验证过重跑测试后真实日志文件不再新增任何测试数据 #P2

### sub/main: API Key 配置行视觉优化 + opencode 手动 Key 支持

> 用户给了一张「API Key 配置」区块的截图，要求"优化一下这里的视觉呈现，给opencode加上api配置功能"。

- [x] [0.10.0-BUG-A-021] 修复 `APIKeyConfigRow.statusText` 里字面量反引号原样显示的问题：`SettingsRow.subtitle` 原本是 `String?`，走 `Text(_ content: some StringProtocol)` 初始化器，不会像 `Text(_ key: LocalizedStringKey)` 那样解析 Markdown，"当前 `sk-xxx`" 里的反引号只会被渲染成两个字面字符，而不是等宽代码样式。改法：`SettingsRow.subtitle` 类型改成 `Text?`（新增一个 `String?` 重载保持其余 5 处调用点不用改），`statusText` 用 `Text` 插值把技术性的值（占位符当前值 / 掩码后的 key）单独标成等宽字体，跟说明文字拼在一起 #P1
- [x] [0.10.0-PM-A-017] 「API Key 配置」区块顶部加一行说明文字（"给没有官方登录方式、或不想装官方 CLI 的 Provider 手动粘贴 API Key，仅保存在本机。"），对齐本页其余 section（Claude 额度捕获等）都有说明文字的惯例，之前这个区块顶部只有标题，缺少上下文 #P2
- [x] [0.10.0-ARCH-L-004] opencode 加入 `ProviderKind.apiKeyCapableKinds`，新增 `OpenCodeManualKeyStore`（`OpenCodeAuthProvider.swift`，跟 `ZCodeManualKeyStore` 同款设计：Quota Bar 自己独占的 `~/Library/Application Support/QuotaBar/opencode-api-key.json`）。`OpenCodeAuthProvider.fetchSnapshot` 在 `~/.local/share/opencode/auth.json` 没有任何已配置 provider 时，回退检查这个手动 key store——存在就返回 `.available` + 空 quotas + 档位 "BYOK"（手动粘贴的 key 反推不出 auth.json 里具体是 Go/Zen 哪一档，统一按最保守的 BYOK 展示）。`OpenCodeAuthProvider` 新增 `manualKeyConfigPath` 注入参数（避免重蹈 `0.10.0-INVESTIGATE-A-004` 的覆辙，测试不碰真实文件）。`APIKeyConfigRow` 的 `reload`/`save`/`missingHint` 三处 switch 补上 `.opencode` 分支；`providerAccessModes` 里 opencode 的获取模式从 `["Config"]` 改成 `["Config", "API"]` #P1 — 新增 `OpenCodeManualKeyStoreTests`（missing-by-default/save-read 掩码/拒绝空 key）+ `OpenCodeAuthProviderTests` 补一条手动 key 回退成功的测试

### sub/main: 「日志」偏好页明显卡顿

> 用户反馈"日志页特别卡，肯定有问题，这么简单的功能（加上我的mac配置很高）其他页面都不卡"。

- [x] [0.10.0-BUG-A-022] 根因：`DiagnosticsSettingsView.logView` 用的是 `VStack`（不是 `LazyVStack`）包住 `ForEach`，而 `ProviderCheckLogStore.readRecentLines()` 默认最多返回 2000 行——`VStack` 会立即创建/布局全部 2000 个 `Text` 行，不管 360pt 高的可视区域实际只显示约 25 行；页面订阅了 `.providerCheckLogDidChange`（一次刷新周期里最多 7 个 provider 各 flush 一次、各触发一次通知）会调用 `reload()`，每次都要重新铺满这 2000 个视图——这正是"这么简单的功能却很卡"的原因：不是日志系统本身重，是这一屏渲染方式选错了容器。改成 `LazyVStack` 后只创建实际进入视口的行，滚动/刷新开销跟总行数基本无关 #P0

### sub/main: 粘贴 API Key 后应用崩溃（真实 SIGSEGV）+ 输入框改用原生 TextField

> 用户反馈"输入api密钥后应用会直接crush（只是粘贴甚至没有回车），以及你的输入框还是很不macos26"。

- [x] [0.10.0-BUG-A-023] 这次没有停留在猜测——直接从 `~/Library/Logs/DiagnosticReports/QuotaBar-2026-07-09-000952.ips` 读到真实崩溃报告：`EXC_BAD_ACCESS`/`SIGSEGV`（空指针解引用），主线程堆栈落在 WebKit 处理来自 WebContent 进程的异步 IPC 消息、提交 remote layer tree 时（`RemoteLayerTreePropertyApplier::applyHierarchyUpdates`），跟 API Key 输入框本身的代码完全不在同一条调用链上——粘贴动作只是恰好跟这次异步 IPC 回调撞在同一个 run loop tick，不是直接因果关系。最可疑的诱因：`0.10.0-BUG-A-019`（昨天）新增的 `WebKitSessionWarmup` 创建了一个 frame `.zero`、**永远不挂任何 `NSWindow`/superview** 的 `WKWebView`，长期存活却从未有真实的宿主环境——这跟 App 里其余所有 `WKWebView` 用法（`WebAuthorizationController` 登录窗口、`WKWebViewHeadlessLoader` 抓取窗口）都不一样，那些全部挂在真实 `NSWindow` 上。修复：给预热用的 `WKWebView` 一个真实的 `NSWindow`（永远不 `orderFront`，屏幕外坐标、不可见，只是给 WebKit 一个正常宿主环境），跟已知稳定的登录窗口用法保持一致 #P0
- [x] [0.10.0-CLEAN-A-003] 顺手做了一次简化：`APIKeyTextField`/`FocusTextField`（AppKit `NSTextField` 包装 + 两个全局 `NSEvent` 本地监听器拦截 `Cmd+V`/`mouseUp`）最初是专门为 dropdown 里 `NSMenu` tracking-mode 的内联输入框做的变通（`NSMenu` 的 modal 事件循环会挡住标准 Edit 菜单/焦点）——那个内联输入框已经在更早的改动里删掉了，`APIKeyConfigRow` 现在唯一还在用它的地方是 Preferences 的普通 `NSWindow`，那里完全用不上这套 AppKit workaround。改成原生 SwiftUI `TextField`（`.textFieldStyle(.roundedBorder)`），既解决了"还是很不 macOS 26"的视觉反馈，也顺手删掉了两个不再需要、却仍在全局拦截键盘/鼠标事件的 `NSEvent` 监听器（不确定是否跟 `0.10.0-BUG-A-023` 那次崩溃有关，但确认是不必要的额外风险面，删掉没有坏处）#P1

### sub/main: 授权 tier 完成度判断落地 + 已授权时隐藏虚假 WebView 引导

> 用户反馈两点：opencode 粘贴 API Key 后"无事发生"（key 实际保存成功、Preferences 里也显示已配置，但 dropdown 依然提示"在 Preferences 中通过 API Key 授权"）；"webview还是不行，登陆了根本检测不到"（Claude WebView 已登录，dropdown header 仍显示"打开 WebView 授权"）。

- [x] [0.10.0-INVESTIGATE-A-005] 先读真实诊断日志核实"webview 检测不到"：00:33 起**每一轮**都是 `claude-webview：获取到 2 条额度窗口 | 成功`——`0.10.0-BUG-A-019` 的预热修复实际已生效，dropdown 里 Claude 的 89%/29% 额度正是 WebView 会话取到的（statusline/oauth 限流/CLI 同轮全部失败）。真正失败的是过期日层：`claude-billing-settings-page：页面里未提取出日期`（登录态有效、页面能加载，但 DOM 里解析不出日期）。用户看到的"打开 WebView 授权"是 `PlanHeader.canOfferWebAuthorizationForDate` 在日期缺失时的引导——已登录的用户再点一次也不会有任何新结果，这个虚假引导正是"检测不到"错觉的来源（下条修复）#P0
- [x] [0.10.0-BUG-A-024] 落地此前 `0.10.0-ARCH-L-003` 明确留白的"tier 完成度"判断：新增 `ProviderKind.manualAPIKeyIsConfigured`（各 kind 读各自 key 存储，占位符不算）和 `firstPendingAuthRemediationTier()`（按 FDA > WebView > API 优先级返回第一个**还没完成授权**的 tier；`.webView` 已完成 = App WebView 会话存储有该 provider dashboard 域的 Cookie，`.apiKey` 已完成 = 手动 key 已真实配置；全部完成或没有任何 tier 返回 nil）。`MenuView` 的 `.needsConfiguration` 分支抽成 `NeedsConfigurationRow`、`QuotaAuthPromptRow` 一并改用这个异步判断（初值用静态能力列表第一项避免闪烁，`.task(id: fetchedAt)` 每轮刷新后重判）：待完成 tier 是 `.webView` → 授权按钮，`.apiKey` → 灰字指 Preferences，nil → 终态"暂无额度数据"。opencode 配好 key 后现在正确显示终态文案 #P0
- [x] [0.10.0-BUG-A-025] `PlanHeader` 的两处"打开 WebView 授权"引导（`missingTierNeedsAuth` 档位缺失、`canOfferWebAuthorizationForDate` 日期缺失）都加上 `!webViewSessionAuthorized` 条件（`.task(id: fetchedAt)` 异步查 `appSessionHasCookies`，初值 false——未知时宁可多显示引导也不隐藏真正需要的入口）：已登录的 provider 不再展示一个已经兑现过的授权承诺，Claude 现在 header 右侧只显示价格、不再有误导性的授权链接 #P0
- [x] [0.10.0-INVESTIGATE-A-006] claude.ai 账单/设置页的订阅到期日提取持续失败（"页面里未提取出日期"）——用户澄清根因：**iOS（Apple 内购）订阅的到期日只在 Apple 侧可见，claude.ai 网页上根本不存在这个数据**，提取不出来是数据不存在而非解析 bug。结论：(1) 隐藏兜底已到位（`0.10.0-BUG-A-025`：已授权时不显示假引导，日期一栏留空）；(2) 直接付款（网页 Stripe）用户的提取路径保留 `ClaudeHarvester` 不动，等有直接付款账号的真实样本再验证其选择器是否有效 #P2

### sub/main: opencode WebView 额度层（workspace Go 页）

> 用户提供了真实入口："浏览器额度，其中长的占位符登陆了就会有：https://opencode.ai/workspace/wrk_.../go"；"订阅日期"在 Stripe 客户门户（短期 session 链接）；"cli指令我不确定"。要求给 opencode 接上浏览器侧的额度和过期日。

- [x] [0.10.0-DATA-B-019] 新增 `OpenCodeWorkspaceProvider`（`opencode-webview`）：读 sst/opencode 真实源码确认 console 是 SolidStart 应用、数据走 `"use server"` 内部 RPC 没有公开 JSON API，因此走 headlessDOM：先加载 `https://opencode.ai/auth`（已登录时 302 到 `/workspace/{lastSeenWorkspaceID}`，`routes/auth/index.ts`），正则出 `wrk_` id，再加载 `/workspace/{id}/go`，按 `data-slot="usage-item"/"usage-value"/"reset-time"` 结构锚点（`lite-section.tsx`）解析 Rolling/Weekly/Monthly 三条**已用**百分比——标签是 i18n 的，解析只认结构和顺序不认文字。周期标签按 5h/7d/30d 映射（rolling 窗口时长是服务端配置 ZEN_LIMITS，代码里读不到，按当前产品实际 5 小时标注并在注释里声明该假设）。reset 文案（"Resets in 3 hours 25 minutes"/中文等价）尽力解析成秒得出 `resetsAt`，解析不出不阻塞额度展示 #P1 — `OpenCodeWorkspaceProviderTests`：wrk_ id 提取、结构顺序解析、未订阅推广页零结果、reset 文案中英/兜底/不可识别 4 组测试
- [x] [0.10.0-DATA-B-020] opencode 订阅续费日：Stripe 客户门户的 session URL 是服务端动态生成的短期链接（`Billing.generateSessionUrl` server action），无法预先构造、不接。替代：Go 的月用量窗口锚定在订阅日（`analyzeMonthlyUsage(timeSubscribed:)`），monthly 重置时刻即下一个月度账单日——用解析出的 monthly reset 作为续费日代理，`subscriptionExpiresAtSource = .headlessDOM`、confidence `.medium` #P2
- [x] [0.10.0-ARCH-L-005] opencode 接入 WebView 授权体系：`webAuthorizationURL = https://opencode.ai/auth`（已登录/未登录两种状态都落在正确页面）、加入 `webViewQuotaCapableKinds`、`dashboardCookieDomains = ["opencode.ai"]`、pipeline 追加 `opencode-webview` 层、Preferences 获取模式改 `["Config", "Web", "API"]`。dropdown 的授权引导按既定优先级自动生效：未登录 WebView 时显示「打开 WebView 授权」（现在是真实可兑现的入口），WebView/API 都完成仍无额度才显示终态文案 #P1
- opencode CLI 指令：调研未发现 opencode CLI 有额度查询命令（docs 无相关子命令），用户自己也说"cli指令我不确定"——不接，等官方出了再说。

### sub/main: opencode Go 页解析器真实首跑 0 结果的修复

> `0.10.0-DATA-B-019` 刚接入就被用户实测的真实日志打脸：`opencode-webview` 能正确发现 workspace id、加载 Go 页，但连续多轮都是"Go 页面已加载但未解析出额度条"——解析器完全没工作。

- [x] [0.10.0-BUG-A-026] 根因：`parseUsageItems` 最初是照 sst/opencode 仓库里的原始 JSX 源码写的正则，但 console 是 SolidStart 应用，真实渲染出的 HTML 会被 SSR hydration 在每段动态文本前后插入 `<!--$-->`/`<!--/-->` 注释标记（如 `<span data-slot="usage-value"><!--$-->0<!--/-->%</span>`），源码里根本看不出这层——数字和 `%`/文字之间被注释隔开，旧正则 `\d+\s*%`（数字/百分号相邻）和 `[^<]*`（reset-time 取值遇到第一个 `<` 就停）两种写法都直接失配。定位方式：给 `fetchSnapshot` 加了一段临时调试代码，在解析失败时把渲染后的 HTML 落盘到 App 自己的数据目录，重新打包、等真实一轮刷新命中失败分支后，直接读这个文件拿到了用户真实登录会话下的原始 DOM——不是继续对着 GitHub 源码猜。修复：`usage-value`/`reset-time` 都先用非贪婪正则拿到 `<span>...</span>` 之间的完整内容，新增 `stripHydrationComments` 统一剥掉里面的 HTML 注释再解析纯文本。用真实落盘的 HTML 直接验证过（三条用量：滚动 0%/重置 5 小时、每周 57%/重置 3 天 22 小时、每月 28%/重置 29 天 15 小时，跟页面上 SolidJS 传过来的 `resetInSec` 原始数据吻合），验证通过后删掉了临时调试代码 #P0 — 用真实抓到的 DOM 片段替换了 `OpenCodeWorkspaceProviderTests` 里原来手写的 fixture，新增一条 `stripHydrationComments` 单测；真机重新打包验证 `opencode-webview：获取到 3 条额度窗口`，过期日也顺带对上（月度重置日代理）
- [x] [0.10.0-BUG-A-027] 用户截图指出 opencode 三条额度的重置时间栏跟其余 provider 格式不统一（显示 opencode.ai 页面原文"重置于 5 小时..."/"重置于 3 天 22..."，其余 provider 是统一的 "4h59m"/"6d15h" 紧凑格式）。根因：`OpenCodeWorkspaceProvider` 直接把页面上的 i18n 原文塞进了 `refreshDescription`，没有走 MiniMax/Z Code 等其余 provider 都在用的共享格式化函数 `QuotaResetText.description(for:relativeTo:)`。修复：改成用已经解析出的 `resetsAt` 时间调用同一个函数生成 `refreshDescription`，页面原文只留作 `parseResetSeconds` 的解析输入，不再直接展示给用户。真机验证（`snapshots.json` 落盘结果）：三条额度分别是 `5h0m`/`3d22h`/`29d15h`，跟 Codex/Claude 那一栏的格式完全一致 #P1

### sub/main: API Key 配置行展开态的对齐问题

> 用户给了一张 Z Code 展开编辑态的截图，指出三点：不应该多一条分割线；输入框应该直接代替原来的灰字占位符；输入框左端要跟名称对齐、保存按钮要跟取消按钮对齐。

- [x] [0.10.0-BUG-A-028] 根因：`APIKeyConfigRow` 展开编辑态之前是叠两个 `SettingsRow` + 一个 `SettingsDivider(leading: 36)` 拼出来的——多出的分割线就是这么来的；输入框那一整行（`TextField` + 「保存」按钮）传给的是第二个 `SettingsRow` 的 `label:` 参数而不是 `subtitle:`（`SettingsRow.subtitle` 类型是 `Text`，塞不进一个可交互控件），导致同时传的 `subtitleLeading: 36` 对它完全不生效——`label` 从 `horizontalPadding`（16pt）算起，没有对齐到名称文字的 36pt 起始位置；「保存」按钮也不在跟「取消」同一个 trailing 列里，是紧跟在 `label` HStack 内部的输入框右边。修复：不再复用 `SettingsRow`，改成手动拼一个 `VStack`（跟 `SettingsRow` 完全一致的 padding/字号/颜色常量保持视觉统一）：名称行和「取消/配置」按钮共享一个 `HStack`（trailing 列），下面直接跟一行——非编辑态是灰字状态说明，编辑态换成 `TextField` + 「保存」按钮，`.padding(.leading, 36)` 手动对齐到名称文字下方；「保存」跟随 `TextField` 在同一个 `HStack` 里、贴着行末，跟上一行「取消」按钮共享同一个右边界。整个过程没有再引入任何分割线 #P1

### sub/main: opencode Go 价格固定 $10/月

> 用户反馈 opencode 一直显示"价格=未获取"，指出目前 opencode Go 只有一档订阅（$10/月），可以先写死这个价格占位，同时要做好本地化换算。

- [x] [0.10.0-DATA-B-021] `ProviderPricing.usdMonthlyPrice` 的 `(kind, tier)` 价格表里补上 `(.opencode, "go") → 10`（对应 `OpenCodeWorkspaceProvider` 里硬编码传入的 `tier: "Go"`——不是从页面解析出来的，只要 workspace 确认订阅了 Go 就是这个价格，官网目前只有这一档）。价格表已有的本地化换算逻辑（`localizedMonthlyPrice`：美元区直接显示 `$10/月`，人民币区按 `ExchangeRateProvider` 实时汇率换算显示 `¥XX/月`）自动生效，不需要额外写换算代码 #P2 — 真机验证：`opencode-webview：档位=Go，价格=¥68/月`（$10 × 当前汇率）。如果 opencode 以后上线多档定价，这里要同步改成从页面解析，注释里已经留了提醒。

### sub/main: 菜单栏图标分层显示（新功能）

> 用户提供两张参考 SVG（"2 sub.svg"/"2 sub-front.svg"）+ 需求描述：实心 bar 固定显示最短周期额度（比如 5 小时），一个虚线/纹理层显示次短周期额度（比如周额度）；如果次短周期比最短周期剩得少，纹理层要叠在实心层前面（参考图 2 的叠放关系）；最左/最右两个 bar 的顶部外侧圆角只在接近容器顶部时才有，bar 变矮后圆角要自然过渡消失，不能凭空浮在中间。

- [x] [0.10.0-FEAT-A-001] `QuotaModels.swift` 新增 `ProviderSnapshot.primarySubscriptionGroupTopTwoQuotasByPeriod(itemOrder:)`：按周期长短（不是剩余多少）从第一个订阅组里排出最短 + 次短两条额度——跟已有的 `primarySubscriptionGroupWorstQuota`（按"剩余最少"选值，可能是 5 小时也可能是周额度，取决于哪个更紧张）是完全不同的选择逻辑，这里身份固定，不会因为剩余比例变化而互换 #P1
- [x] [0.10.0-FEAT-A-002] `StatusBarController` 新增 `layeredFractions(for:)`：套用新的选层方法算出 primary（固定最短周期）/secondary（固定次短周期，只有一条 quota 时为 nil）两个比例；`makeBarsImage` 每个 bar 最多画两层，叠放顺序按谁更高决定——次短周期更高（更常见）时纹理层先画成背景、实心层叠在前面；次短周期更矮时实心层先画、纹理层叠在前面。纹理层的画法是裁剪到 bar 形状内的 45° 手绘斜线阵列（图标只有个位数 pt 宽，`NSColor(patternImage:)` 那套在这个尺度下不好精确控制）——关键坑点：纹理层叠在**已经画满的实心层前面**时，半透明白色斜线画在纯白底上完全没有对比度，视觉上等于没画；改用 `.destinationOut` 复合模式把斜线"擦"进已经画好的实心区域、露出底下的菜单栏背景，不管纹理层底下是透明画布还是已经不透明都看得清（这个 bug 是渲染测试图直接肉眼看出来的，不是靠猜） #P0
- [x] [0.10.0-FEAT-A-003] `BarsImageLayout.barPath` 重写：最左/最右 bar 的顶部圆角改成跟"bar 顶边离容器顶边的距离"挂钩的 `adaptiveTopRadius`——距离为 0（bar 顶到頂）给足 `barRadius`，距离达到 `barRadius` 或更远收缩到 0，中间线性过渡；底部圆角固定不受影响（bar 永远贴底）。原来的三个重复分支（单 bar/最左/最右各自手写贝塞尔路径）合并成一个支持四角各自独立半径的 `roundedRectPath` 辅助函数，减少重复代码。分层显示下两层各自独立按自己的高度算顶部圆角，不受另一层影响 #P1
- [x] [0.10.0-QA-A-001] 把 `makeBarsImage`/`layeredFractions`/`BarsImageLayout` 从 `private` 松到默认 internal，配合 `@testable import` 直接单元测试（`StatusBarLayeredBarsTests`，8 个测试：选层逻辑、`layeredFractions` 各状态分支、顶部圆角自然过渡、中间 bar 恒定直角）。另外写了一个临时渲染脚本，把真实渲染结果导出成放大 8 倍的 PNG（叠一层深色背景，因为图标本身是白色内容+透明背景，直接看白底 PNG 完全看不见）直接肉眼核对——就是靠这张图发现了上面 `0.10.0-FEAT-A-002` 里说的"白色斜线叠在纯白底上完全看不见"的 bug，验证完两种叠放情况 + 圆角自然过渡都正确后删掉了这个临时脚本，不留在正式测试里 #P1

### sub/main: Claude 又刷新不到额度——排查是否是 bug

> "看下log，又刷新不到 claude了，which肯定是可用的，感觉是某种bug"（附一段真实诊断日志，2026.07.10 起 Claude 的额度获取开始出现新的失败原因："Cookie 已过期，请重新登录"）。

- [x] [0.10.0-INVESTIGATE-A-007] 读真实诊断日志核实：`claude-webview` 层这次的失败详情从此前的"获取到 N 条额度窗口｜成功"变成了"来源 claude-webview：Cookie 已过期，请重新登录｜失败"——这是 `BrowserCookieProvider.performRequest` 收到 Anthropic 服务端返回的 `401/403` 后产生的信号，代表 App 本地存的 Cookie 对象确实还在、但服务端已经不认这个会话了（真实的服务端 session 过期，不是"没登录"，也不是本地判断逻辑的 bug）。同一轮里 CLI 层（`claude-auth-status-cli`）拿到了档位/价格但拿不到额度窗口、oauth 层被限流——三层凑不出完整数据，所以 dropdown 目前展示的是"暂无额度数据"这个终态文案。修复方式是用户手动重新走一次 WebView 授权（重新登录 claude.ai），不是代码改动 #P1
- [x] [0.10.0-BUG-A-029] 顺带定位到一个真实 UX 缺口：`firstPendingAuthRemediationTier()` 判断 WebView tier"已完成"只看本地是否存有该 provider dashboard 域的 Cookie 对象（`appSessionHasCookies`），不看服务端这次请求实际是否还认这个 Cookie；所以"Cookie 对象还在、但服务端已判定过期"这种情况下，dropdown 会误判 WebView tier 已完成、直接展示终态"暂无额度数据"，而不是重新引导用户去重新授权——这本该是最贴切的修复提示。这次没有动这处：要把"上一次请求具体是哪种失败"这个信号一路传回 `ProviderSnapshot` 目前没有现成字段，属于有真实架构成本的改动，先记录、留作后续单独任务，不在这次顺手改掉 #P2

### sub/main: 诊断日志按刷新轮次分隔 + 可配置保留轮数 + 新的在最上面

> "看下log...另外日志增加2个功能：\n* 每一次刷新之间做分割，做成：换行 / [刷新额度] - yyyy.dd.mm - hh.mm.ss / 换行\n* 然后增加一个保留次数功能，决定保存最近几次刷新的日志，不要像现在这样无限保存\n* 确保是新的在上面"

- [x] [0.10.0-FEAT-A-004] `RefreshCoordinator.runRefreshCycle()` 最前面（早于任何 provider 的 record/flush）新增调用 `ProviderCheckLog.shared.beginCycle(retainCycles:)`，往日志文件写入一条 `[刷新额度] - <时间戳>` 分隔头，让这一轮的全部日志行都跟在这条头后面。时间戳格式沿用日志本来就在用的 `yyyy.MM.dd_HH.mm.ss`（跟用户原话里的 `yyyy.dd.mm` 不完全一致，为了跟已有每行时间戳格式统一没有另起一套）#P1
- [x] [0.10.0-FEAT-A-005] `ProviderCheckLogStore` 新增 `readRecentLines()` 的分轮解析：先按 `[刷新额度]` 分隔头把文件切成一个个轮次块，再把**块的顺序**整体反转（块内每一行原有的先后顺序不变），使最新一轮排在最上面——磁盘上的物理写入顺序完全不变，只有读出来展示的顺序变了，不需要改动任何 append 逻辑 #P1
- [x] [0.10.0-FEAT-A-006] 新增可配置的保留轮数：`AdvancedPreferences.logRetentionCycles`（默认 20）+ `LogRetentionOption`（10/20/50/100 档）+ `PreferencesStore.setLogRetentionCycles`/`currentLogRetentionOption`；`DiagnosticsSettingsView` 按钮行里加一个 `Picker` 让用户直接切换。`beginCycle` 每次写分隔头之后都会调用新增的 `truncateToRecentCycles`，超出保留轮数的最旧轮次直接从磁盘删掉，替换掉原来"只按 4000 行硬截断、轮次概念上无限保存"的行为（`truncateIfNeeded` 按行数硬截断保留作为兜底，两者不冲突）#P1
- [x] [0.10.0-CLEAN-A-004] 设计取舍：一开始按用户原话字面加了"换行 + 头 + 换行"，但 `readRecentLines()`/`truncateIfNeeded()` 全部用 `content.split(separator: "\n", omittingEmptySubsequences: true)` 解析文件——这个选项会把文件里所有字面空行在读取/截断这两步全部吃掉，字面空行永远不可能真正保留下来、更不可能展示出来。改成分隔头本身不含字面空行（跟其余日志行一样只带一个尾随换行符），"换行"的视觉间隔改在 `DiagnosticsSettingsView.logView` 展示层实现：识别 `line.hasPrefix("[刷新额度]")` 的行，加大上下 padding + 加粗 + 强调色，效果等价但不依赖一个实际上不可能生效的存储层假设 #P2
- [x] [0.10.0-QA-A-002] `swift test` 全量 205 个测试通过（原 203 基线 + `ProviderCheckLogTests` 新增 2 条：`beginCycleOrdersNewestFirst` 验证跨轮次新的在最上面、轮内顺序不乱；`beginCycleTrimsOldestCyclesBeyondRetention` 验证超出保留轮数后旧轮次被截断）。重新打包、真机重启验证：真实日志文件里 `[刷新额度] - 2026.07.10_11.28.08` 分隔头正确插入在这一轮全部 provider 日志之前 #P1


## Phase - v0.11.0 - 真实自动更新（ad-hoc 预开发版）+ semver 发版

> **现状**：
> - `AboutSettingsView` 的「检查更新」是占位（点击只跳 GitHub Releases 页面）
> - `release.yml` 打的 tag 是 `nightly-<sha>`，`CFBundleShortVersionString` 硬编码成 `"1.0"`
> - `.app` 产物 `unsigned and not notarized`（`release.yml:124`），用户首次打开要「右键 → 打开」
> - 没有 helper 脚本，更新替换无任何实现
>
> **本 phase 目标**（在没有 Apple Developer Program 的前提下，把 update 机制全部跑通）：
> 1. 「检查更新」变真：调 GitHub Releases API → 解析 semver + nightly 两种 tag → 比版本 → 后台下载 → helper 替换。
> 2. 引入 semver 发版路径，保留 nightly 作为常规 push 自动打包。
> 3. helper 脚本和主 .app 都用 ad-hoc 签名（`--sign -`），先把更新流程本身打透。
>
> **本 phase 关键立场**（**延续到 v0.12.0** 的设计边界）：
> - **不引入 cert 改动**：build script 维持 `--sign -` ad-hoc 签名，**无 notarize** 步骤；首次打开仍需「右键 → 打开」（本机用一次后 macOS 记住）。
> - **TCC 权限保留为 best-effort**：ad-hoc 签名下 macOS 可能把替换后的 .app 当成新 app，正式形式化保障要等 v0.12.0 切到 Developer ID。
> - **helper 脚本也用 ad-hoc**：本机使用可接受；v0.12.0 同步升级为 Developer ID。
> - **本 phase 内任何签名相关改动都 defer 到 v0.12.0**。
>
> **与 v0.12.0 的关系**（这是关键的「延续性」设计）：
> - v0.11.0 是 v0.12.0 的**预开发版**，**不重写 update 流程**。v0.12.0 在 v0.11.0 已落地的 update 机制上**仅升级签名链 + notarize**。
> - v0.12.0 的具体差异（v0.11.0 已经完成、v0.12.0 不动的部分）：UpdateChecker / 状态机 / UI / semver workflow / helper 替换逻辑。
> - v0.12.0 唯一改的是：build script 签名身份、notarize 步骤、helper 脚本签名、cert 一致性断言、相关文档。
> - 共享资产：bundle identifier `com.taobe.quotabar` 在 v0.11.0 阶段就锁死，v0.12.0 升级 cert 时直接复用，避免 TCC 权限被清。
>
> **worktree 拆分**：所有任务在 `update/main` 单 worktree 推进；v0.12.0 在同一 worktree 继续。

### update/main: 引入 semver 发版路径

> 保留 nightly 作为默认 push 自动打包路径；新增 `workflow_dispatch` 触发的 semver 发版路径。
> 引入 semver 并不意味着丢弃 nightly —— nightly 仍是 dev 日常节奏，semver 是「对外稳定版」标记。

- [x] [0.11.0-CI-A-000] `release.yml` 新增 `workflow_dispatch` 输入项 `version`（形如 `v0.11.0`），触发 semver 发版；main 自动 push 路径继续产出 `nightly-<sha>` 不变 #P1
- [x] [0.11.0-CI-A-001] semver 发版路径 tag = `version` 输入值（如 `v0.11.0`）、`prerelease: false`；产物上传到同名 GitHub Release；DMG 名称 `QuotaBar-<version>.dmg`；macOS `CFBundleShortVersionString` 同步写入 `0.11.0`（去前导 `v`）#P1
- [x] [0.11.0-CI-A-002] `build-app.sh` 接受 `VERSION` 环境变量：默认空时走 nightly 行为（`CFBundleShortVersionString = "1.0"` 保持），传入 `v0.11.0` 时写入 `CFBundleShortVersionString = "0.11.0"`；脚本内对 `VERSION` 走严格 `vX.Y.Z` 校验，非合法格式立即 fail，不静默回退 #P1
- [x] [0.11.0-CI-A-003] `CFBundleVersion` / `QBDisplayBuild` 统一日期戳 `YYMMDD.HHMMSS.branch`（当前已部分实现，验证 nightly 与 semver 两条路径都走同一逻辑）#P1
- [x] [0.11.0-CI-A-004] `release.yml` 注释维持 `unsigned and not notarized`，与本 phase ad-hoc 实际行为一致；v0.12.0 升级 cert 时再更新注释为实际签名 + notarize 步骤（升级版见 [0.12.0-SEC-A-005]）#P1
- [x] [0.11.0-CI-A-002-test] 测试 `build-app.sh` 在 `VERSION=v0.11.0` / `VERSION=` / `VERSION=garbage` 三种情况下 Info.plist 写入行为分别正确 #P1 — 2026-07-05 手动验证：garbage 立即 fail、v0.11.0 写入 0.11.0、空写入 1.0

### update/main: 维持 ad-hoc 签名 + 无 notarize 立场（预开发版）

> 本 phase **不引入任何 cert 改动**；build script 维持 `--sign -` ad-hoc 签名，无 notarize、无 `--options runtime`、无 .p8 API Key。
> 正式升级到 Developer ID 签名 + notarize 在 v0.12.0 完成（phase header 已说明两者关系）。
> 本段落的 ARCH 任务是**为 v0.12.0 提前锁定资产**：bundle id 在 v0.11.0 阶段就锁死，v0.12.0 升级 cert 时直接复用，避免 TCC 权限被清。

- [x] [0.11.0-ARCH-A-000] 保持 bundle identifier `com.taobe.quotabar` 在所有 build 中不变；`build-app.sh` 内已 hardcode，本 phase 任何修改都不允许触碰该值（v0.12.0 升级 cert 时这是 TCC 权限保留的形式化前置条件）#P1
- [x] [0.11.0-ARCH-A-001] 保持 `--identifier com.taobe.quotabar` 重签名参数与 Info.plist 的 `CFBundleIdentifier` 一致；ad-hoc 模式下该参数是 macOS 识别「同一 app」的最重要依据，本 phase 不允许改动 #P1
- [x] [0.11.0-ARCH-A-002] build script 在本 phase 维持 `--sign -` ad-hoc 签名；**不引入** `--options runtime` / `xcrun notarytool` / .p8 API Key 任一项；v0.11.0 范围内任何与签名相关的改动都 defer 到 v0.12.0 #P1
- [x] [0.11.0-ARCH-A-003] helper 脚本 `install-update.sh` 同样 ad-hoc 签名；本机使用可接受，Gatekeeper 首次会拦截，本机授权一次后记住；v0.12.0 同步升级为 Developer ID 签名（见 [0.12.0-SEC-A-006]）#P1
- [ ] [0.11.0-ARCH-A-000-test] 测试每次 `build-app.sh` 跑完后，生成的 .app 的 `Info.plist.CFBundleIdentifier` == `--identifier` 参数值 == `com.taobe.quotabar`（断言三个值一致，防止 v0.12.0 升级 cert 时出现签名 identifier 与 bundle id 漂移）#P1

### update/main: 写轻量 helper 替换脚本

> 选 B 方案：app 后台下载 dmg → 提示用户重启 → helper 挂载 dmg → 替换 `/Applications/Quota Bar.app` → 重启 app。
> 本 phase helper 用 ad-hoc 签名（依赖 [0.11.0-ARCH-A-003]）；v0.12.0 同步升级为 Developer ID（见 [0.12.0-SEC-A-006]）。
> ad-hoc 签名下 `spctl --assess` 会拒绝（因为 macOS 不认 ad-hoc 为有效签名），所以 v0.11.0 阶段只跑 `codesign --verify`，跳过 spctl；v0.12.0 起两者都跑。

- [x] [0.11.0-TOOL-A-000] 新增 `macos/scripts/install-update.sh`：接受 dmg 路径参数 → 挂载 dmg → 复制 .app 到 `/Applications/Quota Bar.app`（覆盖现有）→ 卸载 dmg → 退出码反映成功 / 失败 #P1
- [x] [0.11.0-TOOL-A-001] `install-update.sh` 替换前 verify 签名：`codesign --verify --verbose=2 <.app>`；ad-hoc 签名下**跳过** `spctl --assess`（ad-hoc 永远被拒，跳过不视为不通过）；任一失败立即终止，避免安装未签名包导致 TCC 权限被清。v0.12.0 升级 Developer ID 后强制加 `spctl --assess --type execute --verbose=2` 检查（见 [0.12.0-SEC-A-006]）#P1
- [x] [0.11.0-TOOL-A-002] `install-update.sh` 走 `build-app.sh` 同一签名流程（v0.11.0 是 ad-hoc，v0.12.0 升级为 Developer ID + notarize）；产物 `install-update` 与主 .app 一起打包进 dmg 内的 `tools/` 目录（dmg 用户从 Applications 拖到 Applications 的常规用法不会暴露它，仅 app 启动时通过 `Bundle.main.bundleURL.deletingLastPathComponent()` 等方式定位）#P1 — 实现偏差：helper 打包进 .app 的 `Contents/Resources/install-update.sh`（随主包 ad-hoc 签名整体覆盖），主 app 通过 `Bundle.main.url(forResource:)` 定位；比 dmg tools/ 目录更不易被用户误删
- [x] [0.11.0-TOOL-A-003] `install-update.sh` 在替换前等主 app 进程退出（`pkill -x "QuotaBar"` + 短暂 sleep 等待进程清理），避免 file lock；超时 5s 后强杀 #P1
- [x] [0.11.0-TOOL-A-004] 替换失败时（disk full / 权限不足 / 签名 verify 失败）回滚：保留旧 .app，把失败原因写 `~/Library/Application Support/QuotaBar/update-error.log`；主 app 启动时检测该文件并弹「上次更新失败」通知 #P1
- [x] [0.11.0-TOOL-A-005] `install-update.sh` 支持 `--dry-run` 模式：不实际替换，仅打印将要执行的操作；CI / 开发调试使用 #P1
- [ ] [0.11.0-TOOL-A-000-test] helper 集成测试：mock dmg 挂载 + 写一个 .app stub，验证 dry-run 不写盘、正常模式正确复制、失败模式回滚 + 写 error log #P1
- [ ] [0.11.0-TOOL-A-001-test] helper 拒绝未签名 / 签名错误的 dmg，给出明确错误码 #P1

### update/main: 实现 UpdateChecker（GitHub Releases API）

> 调公开 API，无需鉴权（60 req/IP/h 限流单用户自用足够）。解析 semver + nightly 两种 tag，取「当前 channel 视角下的最新可用版本」。

- [x] [0.11.0-FE-A-000] 新增 `macos/Sources/QuotaBar/UpdateChecker.swift`：使用 `URLSession` 调 `https://api.github.com/repos/DDonlien/quota-bar/releases?per_page=30`，不鉴权 #P1
- [x] [0.11.0-FE-A-001] `UpdateChecker` 解析 release list：semver tag 用 `^v\d+\.\d+\.\d+$` 正则匹配（不匹配 prerelease 如 `v0.11.0-rc1`），nightly tag 用 `^nightly-[0-9a-f]{7,40}$` 匹配 #P1
- [x] [0.11.0-FE-A-002] `UpdateChecker` 状态机：`idle` / `checking` / `updateAvailable(remoteVersion, channel, releaseURL, assetURL, releaseNotes)` / `upToDate(currentVersion)` / `error(message)`；使用 `@MainActor @Published` 暴露给 SwiftUI #P1
- [x] [0.11.0-FE-A-003] 版本比较：semver 段按三段数字比（`v0.10.0` < `v0.11.0` < `v0.2.0` 不成立）；nightly 之间用日期戳 `YYMMDD.HHMMSS.branch` 字符串字典序比（等价于时间序）；semver stable 永远优先于 nightly 推荐 #P1
- [x] [0.11.0-FE-A-004] `UpdateChecker` 暴露 `currentVersion: String`（`Bundle.main.CFBundleShortVersionString`）和 `currentBuild: String`（`Bundle.main.CFBundleVersion`）便于比较 #P1
- [x] [0.11.0-FE-A-005] 检查默认在「关于」页打开时后台触发一次；用户也可手动点「检查更新」按钮触发；触发时 `idle` → `checking` → 终态 #P1
- [x] [0.11.0-FE-A-006] 网络超时 10s；错误状态展示中文友好提示（「无法连接到 GitHub，请检查网络」），不暴露原始 API 错误；限流命中（403 with X-RateLimit-Remaining: 0）时显示「检查过于频繁，请稍后重试」#P1
- [x] [0.11.0-FE-A-007] `UpdateChecker` 缓存上次检查结果到 `PreferencesStore.QuotaPreferences.lastUpdateCheck: Date?`；同一 session 内 `AboutSettingsView` 重新打开时若 5min 内已查过不重复请求 #P1
- [ ] [0.11.0-FE-A-000-test] mock `URLProtocol` 喂各种 release JSON：纯 nightly / 纯 semver / 混合 / prerelease / 空 list / 限流 403 / 网络超时；验证 state machine 正确转移 #P1
- [x] [0.11.0-FE-A-003-test] 版本比较单元测试：`v0.2.0 < v0.10.0`（数字比）、`v0.2.0-rc1 < v0.2.0`（prerelease 不进 stable 比）、`v0.2.0 stable > nightly-<sha>`（stable 优先）、`nightly-260701 < nightly-260702`（日期戳字典序）#P1 — 实现偏差：nightly tag 本身是 `nightly-<sha>` 无日期戳，改用 GitHub release `published_at` 比较新旧，本地构建时间从 `CFBundleVersion`（YYMMDD.HHMMSS）解析；测试见 `UpdateCheckerTests`

### update/main: 后台下载 + 提示重启安装

> 选 B 方案的下半段：检查到更新 → 提示 → 后台下载 → 签名 verify → 调 helper 替换 → 重启 app。
> 状态机在 v0.11.0-FE-A-002 基础上扩展。

- [x] [0.11.0-FE-A-008] 检测到更新后展示 banner：「v0.11.0 已发布」+ 变更摘要（`body` 字段截前 500 字，去掉 markdown 强调符号）+ 三个按钮：稍后提醒 / 查看 GitHub Release / 立即下载并安装 #P1
- [x] [0.11.0-FE-A-009] 选「立即下载并安装」→ 后台下载 dmg 到 `~/Library/Application Support/QuotaBar/updates/QuotaBar-<ver>.dmg`；进度通过 `URLSessionTaskDelegate.urlSession(_:didWriteData:totalBytesWritten:totalBytesExpectedToWrite:)` 反馈百分比 #P1
- [x] [0.11.0-FE-A-010] 下载完成 + 签名 verify 通过 → 弹「更新已下载，立即重启并安装？」对话框；用户确认后调 `Process.run` 启动 dmg 内 `tools/install-update.sh`；helper 退出后用同一 `Process.run` 启动 `/Applications/Quota Bar.app` 重新拉起主程序 #P1
- [x] [0.11.0-FE-A-011] 状态机扩展：`idle` / `checking` / `updateAvailable` / `downloading(progress: Double)` / `verifying` / `downloaded` / `installing` / `upToDate` / `error(message)`；每个状态都有对应 UI 展示 #P1
- [x] [0.11.0-FE-A-012] 同一版本 24h 内「稍后提醒」不重复提示；用户可在「关于」页点「重置忽略」清空 ignoredVersions #P1 — 实现偏差：「稍后提醒」= 永久忽略该版本 tag（自动检查跳过、手动检查仍会提示），配合关于页「重置已忽略的版本」入口；比 24h 计时更可预期
- [ ] [0.11.0-FE-A-008-test] mock 下载失败 / 签名 verify 失败的 dmg，验证状态机正确转 `error` 且不调 helper；mock 重复触发同版本，验证 24h 抑制逻辑 #P1
- [ ] [0.11.0-FE-A-010-test] 启动 helper 失败时回退到「请手动从 GitHub 下载」提示，不卡死 #P1

### update/main: 更新检查 UI 改造

- [x] [0.11.0-UI-A-000] `AboutSettingsView` 的「检查更新」按钮接 `UpdateChecker` state machine：点击 → `checking` 转圈；新版本 → banner 展示 release notes + 下载按钮；最新 → 「已是最新版本 v0.11.0」提示 #P1
- [x] [0.11.0-UI-A-001] 下载中显示百分比进度条（`ProgressView(value:)`）+ 取消按钮；下载完成显示「立即重启并安装」+「稍后」#P1
- [x] [0.11.0-UI-A-002] 「稍后提醒」把版本号写到 `PreferencesStore.QuotaPreferences.ignoredVersions: [String]`（Codable 向后兼容，旧配置自动获得 `[]`）；下次检查该版本不再提示 #P1
- [x] [0.11.0-UI-A-003] 「关于」页加一行小字（ad-hoc 版文案）：「macOS 权限设置（Accessibility 等）更新后通常会保留；正式形式化保障将在 v0.12.0 升级签名后落地」让用户知情当前 TCC 保留是 best-effort，不做过度承诺 #P1
- [x] [0.11.0-UI-A-004] 移除当前「检查更新」按钮的占位行为（旧实现是直接打开 GitHub Releases 页面 URL），改为触发 `UpdateChecker` #P1
- [ ] [0.11.0-UI-A-000-test] UI 状态切换测试：检查 → 找到新版本 → 下载中 → 下载完成 → 安装中 → 完成全流程；error 状态展示中文友好提示 #P1

### update/main: 更新流程文档与验收

- [x] [0.11.0-DOC-A-000] `macos/AGENTS.md` 加一节「发版流程（ad-hoc 预开发版）」：本地 `make app`（ad-hoc 签名）→ 推 main → 自动 nightly（ad-hoc DMG，首次打开需「右键 → 打开」）；需要发版时用 GitHub Actions 手动触发 `workflow_dispatch` 传 `vX.Y.Z`。v0.12.0 升级 cert 后本节再扩展签名 + notarize 步骤（见 [0.12.0-DOC-A-001]）#P1
- [x] [0.11.0-DOC-A-001] `README.md` 加「更新策略（ad-hoc 预开发版）」段：自动更新如何工作 + 哪些 macOS 权限**通常会保留（best-effort）** + 如何手动重置忽略的版本。v0.12.0 升级后正式改写为「Developer ID 签名后形式化保障」（见 [0.12.0-DOC-A-002]）#P1
- [ ] [0.11.0-DOC-A-002] 写 `macos/scripts/cert-bootstrap.md`：用户首次配签名环境的 step-by-step（enroll / 生成 cert / 配 API Key / 验证）#deferred v0.12.0 — 本 phase 不引入 cert，文档先不写；v0.12.0 升级时落地（见 [0.12.0-DOC-A-000]）
- [ ] [0.11.0-QA-A-000] 端到端冒烟（ad-hoc 路径）：从空本地 checkout → `make app` 成功生成 ad-hoc 签名的 dmg → 推 main → 自动生成 nightly release → 在 app 内检查到。Gatekeeper 首次拦截预期内、本机授权一次后记住 #P1
- [ ] [0.11.0-QA-A-001] 手动触发 semver workflow → 生成 `v0.11.0` release → 旧版 app 启动后能正确识别为新版本 → 走完下载 + 替换流程 → 新版 app 启动 → Accessibility 权限**通常仍在**（best-effort，不保证；ad-hoc 签名下 macOS 可能把它当新 app，UI 文案已在 [0.11.0-UI-A-003] 明确告知）#P1
- [ ] [0.11.0-QA-A-002] DMG 首次下载后 Gatekeeper 行为符合 ad-hoc 预期：双击有「无法验证开发者」警告，需「右键 → 打开」或「系统设置 → 仍要打开」；本机授权后不再拦截 #deferred v0.12.0 — v0.11.0 维持 ad-hoc，Gatekeeper 不拦截是 v0.12.0 目标（见 [0.12.0-QA-A-002]）
- [ ] [0.11.0-QA-A-003] 重复运行「检查更新」不会刷屏 / 不会重复下载同版本 / 不会忽略用户主动重置 #P1
- [ ] [0.11.0-QA-A-004] 60 次/小时限流边界：mock API 返回 `403 X-RateLimit-Remaining: 0` 时 app 提示「检查过于频繁，请稍后重试」而非永久拒服务 #P1
- [ ] [0.11.0-QA-A-005] helper 失败路径：mock 替换失败 → 主 app 检测到 `update-error.log` → 启动时弹「上次更新失败」通知，旧版继续运行不崩 #P1

## Phase - v0.12.0 - 升级到 Developer ID 签名 + notarize

> **承接 v0.11.0**：v0.11.0 已完成 update 机制全部建设（UpdateChecker / helper / UI / 状态机 / semver / ad-hoc 签名），bundle identifier 在 v0.11.0 阶段锁死为 `com.taobe.quotabar`。
> v0.12.0 在 v0.11.0 基础上**仅升级签名链 + notarize**，**不重写 update 流程本身**。v0.11.0 的所有 FE / UI / TOOL / CI / 部分 DOC / QA 任务保持不动，本 phase 只追加签名相关任务。
>
> **v0.11.0 → v0.12.0 的具体 delta**（延续性边界，越小越好）：
> - **改的**：`build-app.sh` 签名身份（`--sign -` → `Developer ID Application: <Name> (<TEAMID>)` + `--options runtime`）、新增 `xcrun notarytool submit` + `xcrun stapler staple`、helper 脚本同步升级签名、`release.yml` 注释更新、cert 一致性断言、相关文档。
> - **不改的**：UpdateChecker / 状态机 / 版本比较 / UI / 偏好设置 / semver workflow / GitHub Actions `workflow_dispatch` 触发逻辑。
> - **共享资产**：`com.taobe.quotabar` bundle id（v0.11.0-ARCH-A-000 锁死）+ 状态机 + helper 替换逻辑（v0.11.0-TOOL-A-000/003/004/005）。
>
> **与 v0.11.0 任务的交叉引用**：
> - v0.11.0-ARCH-A-000 锁定的 bundle id → v0.12.0-SEC-A-001 升级签名时直接复用
> - v0.11.0-ARCH-A-002 不引入 cert 改动的承诺 → v0.12.0 解除，签名相关任务落地
> - v0.11.0-ARCH-A-003 helper ad-hoc 签名 → v0.12.0-SEC-A-006 同步升级
> - v0.11.0-TOOL-A-001 跳过 spctl → v0.12.0-SEC-A-006 强制加 spctl
> - v0.11.0-UI-A-003 best-effort 文案 → v0.12.0-UI-A-XXX 改写为「正式形式化保障」
> - v0.11.0-CI-A-004 维持注释 → v0.12.0-SEC-A-005 更新注释
> - v0.11.0-DOC-A-002 cert-bootstrap.md #deferred → v0.12.0-DOC-A-000 落地
> - v0.11.0-QA-A-002 Gatekeeper #deferred → v0.12.0-QA-A-002 实现
>
> **前置依赖（用户侧）**：enroll Apple Developer Program（$99/年）→ 审批通过 → 本地 Keychain 生成 Developer ID Application cert → 在 App Store Connect 创建 API Key（`.p8`）用于 `xcrun notarytool`。enroll + 审批是用户侧操作，agent 仅提供操作指引。
>
> **worktree 拆分**：仍在 `update/main` worktree 推进（与 v0.11.0 同一分支，避免反复创建 worktree）。

### update/main: 升级 build script 签名 + notarize

> v0.12.0 的核心 SEC 任务：从 ad-hoc 升级到 Developer ID 签名 + notarize。
> 共享 v0.11.0 已锁定的 bundle id（`com.taobe.quotabar`），不重复声明。

- [ ] [0.12.0-SEC-A-000] 用户完成 Apple Developer Program enroll 并在本地 Keychain 生成 Developer ID Application cert；enroll + 审批是用户侧操作，agent 仅提供操作指引 #blocked — 用户前置操作，agent 不直接代执行（继承自原 v0.11.0 设计稿，2026-07-02 拆分）
- [ ] [0.12.0-SEC-A-001] `build-app.sh` 将 `--sign -` 改为 `--sign "Developer ID Application: <Name> (<TEAMID>)"`，并加 `--options runtime`（启用 Hardened Runtime，notarize 前置条件）；bundle id 沿用 v0.11.0-ARCH-A-000 锁定的 `com.taobe.quotabar`，不重新声明 #P1
- [ ] [0.12.0-SEC-A-002] `build-app.sh` 加 notarize 步骤：使用 App Store Connect API Key（.p8 文件）调 `xcrun notarytool submit`，等公证通过后 `xcrun stapler staple` 钉到 dmg；公证失败时 build script 立即 fail，产物不发出去 #P1
- [ ] [0.12.0-SEC-A-003] App Store Connect API Key（.p8 + Key ID + Issuer ID）写入本地 `macos/.env`（不进 Git，加入 `.gitignore`），build-app.sh 读 `.env` 注入 notarytool；`macos/.env.example` 提供模板；macos/AGENTS.md 写明 .env 字段含义 #P1
- [ ] [0.12.0-SEC-A-004] 在 v0.11.0-ARCH-A-000 已有 bundle id 稳定性测试基础上，扩展为 cert identifier 双重断言：`codesign -d --identifier` 输出 == `Info.plist.CFBundleIdentifier` == `--identifier` 参数（防止 Developer ID 签名时 identifier 漂移导致 TCC 权限被清）#P1
- [ ] [0.12.0-SEC-A-005] `release.yml` 注释从 `unsigned and not notarized` 更新为实际签名 + notarize 步骤（继承自 v0.11.0-CI-A-004 #deferred）#P1
- [ ] [0.12.0-SEC-A-006] helper 脚本 `install-update.sh` 同步升级为 Developer ID 签名 + notarize：v0.11.0-ARCH-A-003 解除、v0.11.0-TOOL-A-002 ad-hoc 路径替换为 Developer ID 路径、v0.11.0-TOOL-A-001 跳过 spctl 改为强制 verify（`codesign --verify` + `spctl --assess --type execute`）#P1
- [ ] [0.12.0-SEC-A-001-test] 测试 `build-app.sh` 在 cert 缺失时给出清晰错误并退出非零，不静默 fallback 到 ad-hoc #P1
- [ ] [0.12.0-SEC-A-002-test] 测试 notarize 失败的 dmg 不被 release.yml 误发到 GitHub Release（CI 步骤必须等公证通过；mock notarytool 返回非零）#P1
- [ ] [0.12.0-SEC-A-004-test] 测试 cert identifier 一致性：脚本生成的 `.app` 实际签名的 identifier 与 Info.plist `CFBundleIdentifier` 完全匹配 #P1

### update/main: 升级 UI 文案（best-effort → 形式化保障）

- [ ] [0.12.0-UI-A-000] 「关于」页文案从 v0.11.0-UI-A-003 的 best-effort 改写为正式形式化保障：「macOS 权限设置（Accessibility 等）将在更新后自动保留（Developer ID 签名 + bundle id 稳定性已形式化保障）」#P1

### update/main: 升级文档与验收

- [ ] [0.12.0-DOC-A-000] 写 `macos/scripts/cert-bootstrap.md`：用户首次配签名环境的 step-by-step（enroll / 生成 cert / 配 API Key / 验证），agent 后续 onboarding 流程直接引用（继承自 v0.11.0-DOC-A-002 #deferred）#P1
- [ ] [0.12.0-DOC-A-001] `macos/AGENTS.md` 的「发版流程」节从 v0.11.0-DOC-A-000 的 ad-hoc 版升级为 cert 版：本地 `make app`（Developer ID + notarize）→ `spctl --assess` 通过 → 推 main → 自动 nightly；需要发版时用 GitHub Actions 手动触发 `workflow_dispatch` 传 `vX.Y.Z` #P1
- [ ] [0.12.0-DOC-A-002] `README.md` 的「更新策略」节从 v0.11.0-DOC-A-001 的 best-effort 版升级为正式版：Developer ID 签名 + notarize 后 macOS TCC 权限（Accessibility / Screen Recording / Automation 等）更新后**形式化保留** + 如何手动重置忽略的版本 #P1
- [ ] [0.12.0-QA-A-000] 端到端冒烟（Developer ID 路径）：从空本地 checkout → enroll + 生成 cert + 配 API Key → `make app` 成功生成 Developer ID 签名 + notarize 的 dmg → `spctl --assess` 通过 → 推 main → 自动生成 nightly release → 在 app 内检查到 #P1
- [ ] [0.12.0-QA-A-001] 手动触发 semver workflow → 生成 `v0.12.0` release → 旧版 app 启动后能正确识别为新版本 → 走完下载 + 替换流程 → 新版 app 启动 → Accessibility 权限**形式化保留**（系统设置里仍显示已授权，可通过 `tccutil` 或 `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 验证）#P1
- [ ] [0.12.0-QA-A-002] DMG 首次下载后 Gatekeeper 不拦截（双击直接打开，非「右键 → 打开」），继承自 v0.11.0-QA-A-002 #deferred #P1
- [ ] [0.12.0-QA-A-003] 重复运行「检查更新」不会刷屏 / 不会重复下载同版本 / 不会忽略用户主动重置（v0.11.0-QA-A-003 regression check，签名升级不影响此行为）#P1
- [ ] [0.12.0-QA-A-004] 60 次/小时限流边界：mock API 返回 `403 X-RateLimit-Remaining: 0` 时 app 提示「检查过于频繁，请稍后重试」而非永久拒服务（v0.11.0-QA-A-004 regression check）#P1
- [ ] [0.12.0-QA-A-005] helper 失败路径：mock 替换失败 → 主 app 检测到 `update-error.log` → 启动时弹「上次更新失败」通知，旧版继续运行不崩（v0.11.0-QA-A-005 regression check；helper 现在 Developer ID 签名，失败处理路径不变）#P1
- [ ] [0.12.0-QA-A-006] TCC 权限形式化断言（v0.12.0 验收核心）：旧版 app 已授权 Accessibility → 触发更新 → 安装新版 → 通过 `tccutil` / `sqlite3 ~/Library/Application Support/com.apple.TCC/TCC.db` 查新版 app 的授权状态（service = kTCCServiceAccessibility / kTCCServiceScreenCapture / kTCCServicePostEvent，client = `com.taobe.quotabar`），断言 auth_value = 2（allowed）而非 0（denied）#P1

## Phase - v0.13.0 - opencode Provider 支持（探测 + 诚实的"已配置"态）

> **背景**：opencode（`https://opencode.ai`）是一个 BYOK 聚合 CLI，本身没有稳定的额度百分比接口——
> 调研确认 Zen（其自家 pay-as-you-go 网关）的 credits API 返回 `Not Found`（未上线/不稳定），
> Go（其自家订阅）的用量只能靠抓一个未公开的私有 dashboard 网页 + 浏览器 auth cookie，没有官方文档且结构随时可能变。
> 参考了同类项目 `opgginc/opencode-bar`（GitHub 上一个已实现 opencode 用量追踪的 macOS 菜单栏 App）的源码验证了以上结论。
>
> **本 phase 的范围决策**（已与用户确认，2026-07-08）：只做「探测 + 诚实的已配置态」——
> 读 `~/.local/share/opencode/auth.json` 判断已配置了哪些下游 provider，`.available` + 空 quotas，
> 对齐 `ClaudeAuthStatusCLIProvider` 的 tier-only fallback 先例（有真实档位信息但没有额度数值时，
> 不伪造百分比，quotas 留空，UI 自然显示灰色"未知"灯）。不引入浏览器 cookie 抓取 Go 私有 dashboard 的方案，
> 也不用本地 `opencode stats` CLI 伪造一个固定月度上限来充当额度条——两者都超出当前验证过的可靠数据范围。
>
> **VERSION 说明**：本 phase 完成，但暂不 bump 根目录 `VERSION` 文件——v0.11.0 / v0.12.0 phase
> （自动更新 + Developer ID 签名）已在 REQUIREMENTS.md 中规划但尚未全部完成，可能有其他 agent 正在推进，
> 现在 bump VERSION 可能与其并发工作冲突或造成版本语义混乱（VERSION 目前落在 0.10.0，早于已规划但未完成
> 的 0.11.0/0.12.0）。VERSION 的实际 bump 时机留给之后统一处理已完成 phase 时一并决定。

### sub/main: opencode 探测 + 已配置态接入

- [x] [0.13.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.opencode` 枚举值：`displayName = "opencode"`、`brandColor = #03B000`（取自 opencode.ai 官网配色）、`iconSymbol = "chevron.left.forwardslash.chevron.right"`、`cliCommands = ["opencode"]`、`credentialFiles = ["~/.local/share/opencode/auth.json"]`，无 `bundleIdentifier`（纯 CLI 工具）、无 `envVarNames`（BYOK 无单一规范环境变量）、无 `cookieDomains`（不采用浏览器方案）
- [x] [0.13.0-DATA-A-001] `OpenCodeAuthProvider` 实现：解析 `~/.local/share/opencode/auth.json`（支持 `XDG_DATA_HOME` 覆盖路径），按 provider id 罗列已配置的下游 provider；命中 `opencode-go` / `opencode` 时档位标签显示 `Go` / `Zen`，否则显示通用 `BYOK`；找不到凭证时报 `missingCredentials` → pipeline 兜底 `.needsConfiguration`
- [x] [0.13.0-ARCH-A-000] `Strategies.opencodePipeline()` 接入 `supportedProviderKinds` + `makePipelines()`，只有 `OpenCodeAuthProvider` 一层（无 fallback 层，明确不引入浏览器 cookie 方案）
- [x] [0.13.0-FE-A-000] `Preferences → 模型` 页 `ModelsSettingsView.visibleProviders` 同步加入 `.opencode`（避免重演 GLM/`.zcode` 那种"幽灵 kind 对不上真实 pipeline"的开关错位 bug），`providerVendor` / `providerAccessModes` 补齐 opencode 分支
- [x] [0.13.0-QA-A-000] 单元测试 `OpenCodeAuthProviderTests`：多 provider 解析、tier 优先级（Go > Zen > BYOK）、有凭证时返回 available + 空 quotas、无凭证时 missingCredentials
- [x] [0.13.0-QA-A-001] `swift build` + `swift test`（185 个测试全过，含新增 4 个）；并用本机真实 `~/.local/share/opencode/auth.json`（已配置 `opencode-go`）实测 `swift run` 全链路：探测成功 → 档位=Go、价格=未获取 → 诊断日志确认无额度层伪造
- [x] [0.13.0-DOC-A-000] `README.md`「支持的 Provider」加入 opencode，并补充独立说明段落解释为什么它不进四层获取矩阵

## Phase - v0.14.0 - 大陆可达性兜底 + 额度节奏指示 + Kimi 额度修复

> **背景**：用户截图显示应用内「检查更新」报错「无法连接到 GitHub，请检查网络」——`UpdateChecker.swift`
> 直连 `api.github.com` 检查版本、直连 `github.com/.../releases/download/...` 下载 dmg，这两条请求在中国大陆
> 网络环境下都可能不可达。同一问题也存在于官网：`site/src/pages/index.astro` 的 `UPDATE_DOWNLOAD` 脚本
> 同样在**访客浏览器端**直连 `api.github.com` 取最新 dmg 直链，官网下载按钮在大陆同样可能失效。
>
> 用户参考了附带的 ChatGPT 对话（推荐"客户端永远只访问自己的域名，GitHub 只做构建/发布源"的架构），
> 但明确简化为自己的落地方案："两步备份验证：1. 优先访问 GitHub 更新下载；2. 不行则自动访问 Vercel，
> Vercel 上应该总是能获取到最新的包。" 采用**实时服务端代理**而不是 CI 构建时同步镜像文件：
> Vercel Serverless Function 在请求时现查 GitHub Releases API + 现拉 dmg 资产转发，无需改动
> `.github/workflows/release.yml`（发布流水线不变、风险最小），因为 Vercel 项目 Root Directory 是仓库根目录
> （`.vercel/repo.json` 的 `directory: "."` 已确认），新增 `/api/*.js` 在仓库根目录生效。
>
> **成本提示**：QuotaBar.app 当前约 6.5MB，dmg 预计个位数到十几 MB，每次 fallback 触发的流式转发对 Vercel
> 带宽成本可忽略；仅在 GitHub 直连失败时才会触发，日常不产生额外流量。
>
> **执行中发现的意外前提（2026-07-18）**：调研发现 GitHub 仓库 `DDonlien/quota-bar` 当时是 **private**——
> 未认证请求（包括本来要写的 Vercel 代理、以及所有访客浏览器）访问 `api.github.com` 一律 404，这不是"大陆连不上"
> 而是"谁都连不上"（404，不是超时/连接失败）。这也解释了官网下载按钮为什么一直在悄悄 fallback 到构建时
> hardcode 的旧 dmg 直链（`catch` 静默吞掉了失败）。跟用户确认后（见本 phase 顶部决策），已执行
> `gh repo edit --visibility public`（执行前完整扫描过 git 全部历史的文件名 + 内容 pickaxe，确认没有真实
> 泄漏的密钥/私钥/token，只有测试 fixture 里的占位字符串如 `sk-ant-xxx`）。仓库现在是 public，本 phase 的
> 代理函数按"两者都是未认证的正常直连"实现，不需要额外的 `GITHUB_TOKEN`。

### update/main: 更新检查与下载的 GitHub → Vercel 两步兜底

- [x] [0.14.0-BE-A-000] 仓库根目录新增 `api/latest-release.mjs` + `api/_lib/releases.mjs`（Vercel Node Serverless Function，零配置 `/api` 约定，Web-standard `export async function GET()` 签名，经 vercel-functions 官方 skill 确认是当前推荐写法）：服务端请求 `https://api.github.com/repos/DDonlien/quota-bar/releases?per_page=30`，原样转发 GitHub 的 JSON 数组结构（不改形状，客户端复用现有 `UpdateReleaseParser.parse`），带 `Cache-Control: s-maxage=60, stale-while-revalidate=300`
- [x] [0.14.0-BE-A-001] 仓库根目录新增 `api/download-latest.mjs`：服务端解析当前最新可安装 release（tag 能解析出语义化版本号 + 有 `.dmg` 资产），把上游 `fetch()` 拿到的 `ReadableStream` 直接作为 `Response` body 转发（零配置流式，不缓冲整份文件），`Content-Type`/`Content-Disposition`/`Content-Length` 透传；只代理固定的"最新版"目标，不接受任意 URL 参数
- [x] [0.14.0-FE-A-000] `UpdateChecker.performCheck` 重构为 `fetchReleasesData(from:)` 两次调用（GitHub 直连 → 失败后 Vercel `fallbackReleasesURL`）；限流（403 + `X-RateLimit-Remaining: 0`）直接报限流文案、不浪费一次 fallback；两者都失败才进最终错误态，文案改为不点名具体平台的「暂时无法检查更新，请稍后重试」
- [x] [0.14.0-FE-A-001] `UpdateChecker.downloadAndInstall`：拆出 `startDownload(from:)` + `retryDownloadWithFallbackOrFail`，网络层失败**或 `hdiutil verify` 校验失败**（某些网络环境会用 HTTP 200 返回假内容而不是直接连接失败，只有校验能发现）都会触发一次 `fallbackDownloadURL` 重试；`downloadTriedFallback` 标记避免死循环，两次都失败才提示"下载失败，请稍后重试或前往官网手动下载"
- [x] [0.14.0-FE-A-002] `site/src/pages/index.astro` 的 `UPDATE_DOWNLOAD` 脚本重构为 `resolveFromGitHub()` ?? `resolveFromFallback()`：GitHub 失败时改请求同源 `/api/latest-release`，且下载链接本身也改成同源 `/api/download-latest`（不是原始 github.com 直链——GitHub 都连不上，直链大概率也连不上）；sessionStorage 缓存的是最终 href 而不是 release 对象，两条路径共享同一份缓存逻辑
- [x] [0.14.0-QA-A-000] 新增 `UpdateCheckerFallbackTests.swift`（4 个测试：primary 成功不碰 fallback / primary 失败自动 fallback 成功 / 两者都失败报通用错误不点名平台 / 限流直接报错不浪费 fallback）；顺带给 `PreferencesStore` 补一个 `init(fileURL:)` 测试专用入口（原来硬编码单例真实路径，没法在测试里隔离，现在跟其余 store 的临时目录注入模式对齐）。`swift test` 217/217 通过
- [x] [0.14.0-QA-A-001] 真实验证（非 mock）：本地 `node` 直接跑 `api/_lib/releases.mjs` против真实 GitHub API，`pickLatestDmgRelease` 选出 `v0.10.0-cdc842c`；`api/latest-release.mjs`/`api/download-latest.mjs` 的 `GET()` 直接调用，下载流字节数（2,545,835）与 GitHub 资产 `size` 字段完全一致；新增 `.claude/launch.json` 的 `vercel-dev` 配置 + `vercel.json` 的 `devCommand`（原来没有，`vercel dev` 会在仓库根目录找不到 `astro` 命令），通过 Browser 面板跑起 `vercel dev`，确认 `/api/latest-release`、`/api/download-latest` 都是 200、字节数对得上；把官网下载脚本的 `resolveFromGitHub`/`resolveFromFallback` 原样搬到浏览器里跑，用 monkeypatch 的 `fetch` 模拟 GitHub 不可达，确认真的会切到 `/api/download-latest`

### sub/main: 额度条节奏指示（linear pacing marker）

> 需求原文："在 drop down 的进度条上，应该标识出根据当前剩余更新时间推荐的使用量。例如：如果剩余 7 天，
> 今天是第 1 天，则应标识在 1/7 的位置。这个标识本身应该是个非常简洁的指示条或者指示点，不应该特别的张扬。"
>
> **语义确认**（本次实现采用的解释，如与用户预期不符可调整方向）：`ProgressPill` 的填充语义是"剩余比例"
> （`remainingFraction`，从左边缘铺满，值越大填充越宽）。指示点标的是"如果按线性节奏消耗，此刻理论上应该
> 还剩多少"——公式 `idealRemainingFraction = 1 - elapsedFraction = timeUntilReset / periodSeconds`。
> 用户例子（周期 7 天，今天第 1 天，已过 1/7）对应 `idealRemainingFraction = 6/7`，指示点落在**靠右侧**（应该
> 还剩 6/7）；如果实际填充（真实 remainingFraction）比指示点更靠左，说明消耗快于线性节奏。只对有明确
> `periodSeconds` + `resetsAt` 的额度窗口显示，固定额度包（`periodSeconds == nil`）不显示。

- [x] [0.14.0-DATA-B-000] `QuotaWindow` 新增方法 `idealRemainingFraction(relativeTo now: Date = Date()) -> Double?`：`periodSeconds`/`resetsAt` 任一缺失返回 `nil`；否则 `max(0, min(1, resetsAt.timeIntervalSince(now) / periodSeconds))`
- [x] [0.14.0-FE-B-000] `ProgressPill` 新增可选参数 `paceMarkerFraction: Double?`：非 nil 时在该 x 位置画一条 1.5pt 宽、`progressHeight+2` 高的低对比度竖线（`Palette.paceMarker = Color.primary.opacity(0.45)`，不使用状态色，避免和 track/fill 的红橙绿混淆）
- [x] [0.14.0-FE-B-001] `QuotaRow` 传入 `quota.idealRemainingFraction()` 给 `ProgressPill`
- [x] [0.14.0-QA-B-000] 新增 `QuotaWindowTests.swift`：周期起点（1.0）/day-1-of-7（6/7）/终点（0）/resetsAt 陈旧夹到 0/无 periodSeconds 返回 nil/无 resetsAt 返回 nil，共 6 个测试，`swift test` 213/213 通过
- [x] [0.14.0-QA-B-001] `swift run` 目测验证：不同剩余比例 + 不同节奏（超前/落后/持平）下指示点位置和视觉观感符合"简洁不张扬"的要求——用户打包后实机截图确认，Codex/Claude/Kimi/opencode 各条额度上的指示点位置均正确，样式认可（见下面 FE-B-002 的后续调整）

> **后续追加（用户实机截图反馈）**："我觉得你现在整体加宽后的进度条样式是 OK 的。那你不如就全局都用这个宽的，
> 不要在没有提示条的时候，进度条就变成窄的，这样很不统一，不太好。" 根因：指示点的 Capsule 比条本身
> （`progressHeight`）高 2pt，靠"poke 出来"跟条区分，这导致有指示点的条目视觉上比没有指示点的条目
> （固定额度包、loading 骨架屏）粗，两者不统一。

- [x] [0.14.0-FE-B-002] `progressHeight` 从 5 提到 7（原先"5pt 条 + poke 出 2pt 指示点"达到的视觉高度，直接作为新的统一基准），指示点高度从 `progressHeight+2` 改为跟条本身齐平的 `progressHeight`——不再依赖 poke 出来做区分，`Palette.paceMarker` 的低对比度颜色本身已经够跟 track/fill 区分；现在不管有没有指示点，所有额度条粗细一致

### sub/main: Kimi CLI OAuth 5 小时/周额度丢失修复

> 现象：用户反馈 Kimi 现在只能拿到月额度（Work，来自 `KimiDesktopTokenProvider`），拿不到 5 小时/周额度
> （Code，来自 `KimiAuthProvider`）。本机诊断日志（`provider-check.log`）复现同一症状，`kimi-auth` 持续报
> "Kimi refresh_token 已失效，请重新 kimi login"，而 `kimi-desktop-token` 持续成功。
>
> **根因分析**：`KimiAuthProvider` 是当前 Kimi pipeline 里唯一会**写回**凭证文件的 provider——刷新
> access_token 后调用 `persistCredentials` 把新 token 写回 `~/.kimi-code/credentials/kimi-code.json`，
> 而这份文件是 `kimi` CLI 自己的凭证存储，CLI 本身也可能独立管理/轮换这份凭证。`KimiDesktopTokenProvider`
> （一直工作正常）从不写回它读的 token store，是纯只读消费者。Kimi 的 OAuth 服务端大概率对 `refresh_token`
> 做单次轮换（用一次即失效换新），两个独立写者（真实 kimi CLI + Quota Bar 后台每 5 分钟一次的静默刷新）
> 竞争同一份 refresh_token 时，任何一方在另一方之后用"已经被对方用掉"的旧 refresh_token 去刷新，
> 服务端就会拒绝——这与观察到的"曾经能用、现在永久失败"的症状一致。
>
> 本次修复只解决"Quota Bar 主动写回、制造竞争"这一条架构性风险；如果用户本地 refresh_token 在修复前
> 已经被判定失效，仍需手动 `kimi login` 一次让 CLI 重新签发凭证——这一步无法通过代码修复回溯解决。

- [x] [0.14.0-BUG-A-000] `KimiAuthProvider.ensureFreshCredentials`/`forceRefresh` 仍在内存中执行 OAuth refresh（当次请求仍能成功），但去掉 `persistCredentials` 写回调用，不再往 `~/.kimi-code/credentials/kimi-code.json` 写任何内容——与 `KimiDesktopTokenProvider` 对齐为纯只读消费者，避免与真实 `kimi` CLI 竞争 refresh_token 轮换；已删除现在无调用方的 `persistCredentials` 方法本身
- [x] [0.14.0-QA-C-000] 新增 `KimiAuthProviderTests`：过期 access_token 触发 refresh 后凭证文件字节级不变；未过期 access_token 完全跳过 refresh endpoint。`swift test` 207/207 通过（含新增 2 个）
- [x] [0.14.0-DOC-B-000] `README.md` Kimi 一行补充说明：只读消费凭证文件、5 小时/周额度依赖 `kimi` CLI 自己的登录态，长期显示登录过期时需手动 `kimi login`

> **后续追加（同一 phase 内，用户实机截图反馈）**：上面的 `persistCredentials` 修复上线后，用户反馈
> Kimi dropdown 里仍然只看到月额度，且 Work 额度条样式（无节奏指示点）跟其他 provider 不一致——追查后
> 发现是两个独立的遗留问题，跟 `persistCredentials` 无关：
> 1. `KimiSubscriptionParser`（`kimi-desktop-token` 用的解析器）一直不写 `QuotaWindow.resetsAt`，
>    当初是为了避开一个"用 `resetsAt` 推断 `subscriptionExpiresAt`"的 fallback（见 0.6.0-DATA-A-002），
>    但那条 fallback 早在 0.6.0 就整个删掉了，顾虑已经过期——代码没跟着清，导致 v0.14.0 新加的节奏
>    指示点（sub/main 见上）在 Kimi 上永远没有数据可画。
> 2. `kimi-webview` 兜底层请求的端点 `GetSubscriptionStat`，用真实凭证直连验证后确认服务端已经
>    **404**（下线了）——未授权时表现为"未登录"，掩盖了"即使授权了也一样会失败"这个事实。
>
> 排查过程中一度怀疑修复没生效，最后定位到是本机同时跑着两个 QuotaBar 进程（一个是前一天的旧包、
> 一个是当次验证用的 `swift run`），共享同一份 `snapshots.json`/`provider-check.log`，旧进程的过期
> 写入覆盖了新进程的正确结果——不是代码问题，是本地验证环境污染，记录下来避免以后再被同样的假象
> 误导排查方向。

- [x] [0.14.0-BUG-B-000] `KimiSubscriptionParser.parse` 的 Work 窗口把 `resetsAt` 从 `nil` 改成
  `expireTime`（`refreshDescription` 早就在用同一个日期，写进 `resetsAt` 不引入新的不确定性）
- [x] [0.14.0-BUG-B-001] `DashboardEndpoints.endpoint(for: .kimi)`（`kimi-webview` 用的端点）从
  `GetSubscriptionStat` + `KimiSubscriptionStatParser` 改成跟 `KimiDesktopTokenProvider` 一致的
  `GetSubscription` + `KimiSubscriptionParser`
- [x] [0.14.0-QA-C-001] `KimiSubscriptionParserBalancesTests` 更新第一个测试的 `resetsAt` 断言；
  `swift test` 217/217 通过

### sub/main: Preferences「每个渠道获取状态」— 模型页展开三态指示器

> 需求原文（用户反馈上面的 Work/Code 部分成功部分失败排查过程后提出）："我知道问题出在哪了。你可能
> 通过别的方式获取到了 Kimi work（也就是月额度），但是需要通过 web view 或别的方式才能获取到 Kimi 的
> 小时和周额度。但这时候，我们的交互又没有办法提示用户去做那些操作。我觉得这个事情无法预见，应该在
> preference 里面，去调整每个渠道获取的情况：1. 自动化获取的：正常显示。2. 当前 provider 没有获取到的：
> 应该跟获取到的在样式上有所区别。3. Web view：在没有授权的情况下，应该可以点击，展开进行手动授权。"
>
> 放置位置跟用户确认过：「模型」设置页每个 provider 行下方展开（而不是新开独立页面）。完整方案见
> `/Users/taobe/.claude/plans/eventual-sauteeing-leaf.md`。核心结论：`ProviderSourceIndexStore`
> 已经在每轮刷新时持久化了逐渠道的成功/失败记录（`FetchPipeline.recordSuccess`/`recordError`），
> `WebAuthorizationController.openAuthorization(for:)` + `WKWebViewHeadlessLoader.appSessionHasCookies`
> 也已经是 dropdown 现成在用的点击授权实现——这个功能本质是给已有的结构化数据加读取 API + 通知，
> 再加一层纯展示 UI，不需要改动 fetch pipeline 本身的任何行为。

- [x] [0.14.0-DATA-C-000] `ProviderSourceIndexStore` 新增 `records(for:layer:)` 读取 API + `save()` 末尾发 `.providerSourceIndexDidChange` 通知
- [x] [0.14.0-DATA-C-001] `Strategies.swift` 新增 `ProviderChannelDescriptor` + `ProviderPipelines.quotaChannels(for:)`（复用 `makePipelines()`，按 `supportedLayers.contains(.quota)` 过滤掉 keychain 这类不贡献额度数据的 strategy）
- [x] [0.14.0-FE-C-000] 新文件 `Preferences/ProviderChannelStatusView.swift`：`ProviderChannelStatusList`/`ProviderChannelRow`，三态渲染 + webview 未授权时的点击态（复用 `QuotaAuthPromptRow` 的 `.task`+`onTapGesture` 结构）；实现过程中发现并修掉一个真实的状态残留 bug——webview 渠道从"未授权"变成"刚成功"时，`needsWebAuth` 的异步检查不会因为 record 内容变化而重新触发（`.task(id:)` 绑的是不变的 `sourceId`），加了 `&& !isSuccess` 兜底，让"去授权"按钮在刚成功那一刻就消失，不用等下一次巧合触发的重新检查
- [x] [0.14.0-FE-C-001] `ModelsSettingsView` 加展开交互（`expandedProviders` 状态 + chevron 按钮 + 条件渲染 `ProviderChannelStatusList`），不改动现有静态 `providerSubtitle`/`providerAccessModes`
- [x] [0.14.0-QA-D-000] 新增测试：`QuotaPersistenceTests.recordsForKindReturnsAllChannelsIncludingFailures`（追加到已有文件，同一个 store 已经在测）+ 新文件 `ProviderChannelDescriptorTests.swift`。`swift test` 220/220 通过
- [x] [0.14.0-QA-D-001] 实机验证：computer-use 无法识别 `swift run`/本地 ad-hoc 签名的 `.app`（不是 Launch Services 里的正常安装应用，两次 `request_access` 均返回 not-installed），改用直接读取一次真实刷新周期后的 `provider-sources.json` 手工核对三态分类逻辑——真实数据（kimi-desktop-token 成功、kimi-auth 失败带 "refresh_token 已失效"、kimi-webview 未授权且 `failureCount=163`）按 `ProviderChannelRow` 的判定逻辑手工走一遍，三种状态分类结果均正确；像素级视觉效果仍需用户实机确认

## Phase - v0.14.1 - 更新检查的版本比较 bug + 检查过程写日志

> **背景**：用户装的是 07-09 的旧包（`0.10.0-cdc842c`），「关于」页点检查更新显示"已是最新版本"，
> 但仓库当天（07-19）已经因为本 session 的一串修复发了 7 个新 release（全部还是 `0.10.0-*`，只有
> git sha 不同——见 `UpdateChecker.swift` 顶部注释，`VERSION` 文件只在 v0.11.0/v0.12.0 这类完整功能
> 阶段完成时才 bump，日常修复走"每次 push main 都发新 release"，不 bump 版本号）。用户最初要求"把
> 更新检查加入日志方便看问题"，但读代码直接定位到了根因：`UpdateReleaseParser.pickUpdate` 是
> 2026-07-07 那次改版定下的规则——只比较 `X.Y.Z`，完全忽略 git sha 后缀，本意是防"同一个 commit
> 重复打包被误判成有更新"；但实际发布节奏下，绝大多数发布之间 `X.Y.Z` 完全相同、只有 sha 不同，这条
> 规则会让这些发布永远不被判定为"有更新"——不是这次新引入的 bug，是环境（发布节奏）变了之后一条
> 旧决策反而错了，跟本 session 前面 Kimi `resetsAt` 那次是同一类情况。

- [x] [0.14.1-BUG-A-000] `UpdateReleaseParser.pickUpdate`：`X.Y.Z` 相同时新增一层判断——当前版本自己也带 sha 后缀时，改看 sha 是否不同（sha 内容寻址，同一个 commit 恒定，"重复打包同一个 commit"依然正确识别成不算更新，07-07 真正要避免的场景没有被重新引入）；当前版本是没有 sha 后缀的纯 `vX.Y.Z`（早期手动稳定版）时维持原规则不变，避免把"同版本号下的 ad-hoc 过程构建"误判成对一个已完成里程碑的更新
- [x] [0.14.1-DATA-A-000] 新增 `UpdateCheckLog`：直接复用「获取日志」页面的存储（`ProviderCheckLogStore`），不新开日志入口/UI；在 `fetchReleasesData`（GitHub/Vercel 两次尝试）、版本比较结果、下载、dmg 校验几个关键节点各记一行，格式跟现有 provider 日志行一致。`UpdateChecker` 新增 `checkLogStore` 注入点（默认 `.shared`），避免测试往真实日志文件写内容
- [x] [0.14.1-QA-A-000] 更新 `UpdateCheckerTests.swift`：原 `sameVersionDifferentShaIsNotAnUpdate` 断言的正是被本次修正推翻的旧行为，改写成 `sameVersionDifferentShaIsAnUpdate`（相同 X.Y.Z、不同 sha → 应识别成更新）+ 新增 `sameVersionSameShaIsNotAnUpdate`（相同 X.Y.Z、相同 sha → 仍不算更新，覆盖 07-07 真正想防的场景）；`onlyUpgradesToHigherSemver` 原有断言（纯 `vX.Y.Z` 不该被同版本号的 sha 构建判定为更新）保持通过，验证了"仅当前版本自带 sha 才触发新规则"这条边界是对的。`UpdateCheckerFallbackTests.swift` 补 `ephemeralCheckLogStore()` 注入点。`swift test` 221/221 通过；核实测试运行前后真实 `provider-check.log` 的大小/mtime 均未变化，确认注入生效
