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
