# 任务清单

> **子功能索引**
> - [`web/REQUIREMENTS.md`](./web/REQUIREMENTS.md) — 营销主页（Astro 静态站，部署到 `quotabar.ddonlien.com`）。v0.1.0 主页首版已落地：纯 CSS/HTML mockup 还原菜单栏 + dropdown，6 家 provider 卡片，4 个卖点，下载按钮动态取最新 nightly DMG。

## Phase - v0.0.0 - 项目初始化

### DOC-A：Agent 协作基础

- [x] [0.0.0-DOC-A-000] 建立项目协作基础 #docs #P0
- [x] [0.0.0-DOC-A-001] 基于 `agent-template` 创建根目录 `AGENTS.md`
- [x] [0.0.0-DOC-A-002] 基于 `agent-template` 创建根目录 `README.md`
- [x] [0.0.0-DOC-A-003] 基于 `agent-template` 创建根目录 `REQUIREMENTS.md`
- [x] [0.0.0-DOC-A-004] 基于 `agent-template` 创建根目录 `DESIGN.md`
- [x] [0.0.0-DOC-A-005] 创建根目录 `agent-log/`

## Phase - v0.1.0 - Dropdown 视觉原型

### UI-A：macOS 26 风格下拉面板

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

### UI-B：传统 macOS 原生菜单实现

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

### QA-A：阶段 1 完成定义

- [x] [0.1.0-QA-A-001] 相关文档已更新
- [x] [0.1.0-QA-A-002] 相关构建命令已执行或记录无法执行原因

## Phase - v0.2.0 - Quota Bar 核心功能

本阶段参考 CodexBar 实现思路，将现有静态 UI 升级为自动探测、获取并展示真实 AI 订阅额度的功能核心。优先聚焦数据获取与刷新机制，偏好设置页面延后至 P2。

> **2026-06-18 更新**：本次 `feat/real-data-and-public` 分支落地的范围如下。括号内是落地位置。
> - **真实数据接入（P0）**：SweetCookieKit 集成 / TCC 引导 / Keychain 真读 / Codex dashboard endpoint + parser
> - **可扩展性（P1）**：`ProviderFetchStrategy` + `FetchPipeline` + `TTYCommandRunner` + `LoginRunner` + AgentDetector 类型合一

### DATA-A：Agent 自动探测

- [x] [0.2.0-DATA-A-000] 探测本地已安装的 AI 编程工具 CLI（如 Codex CLI、Claude CLI、Gemini CLI 等）#P1 — `AgentDetector.detectCLIProviders()`
- [x] [0.2.0-DATA-A-001] 探测浏览器中已登录的 AI 服务（通过 Safari / Chrome / Firefox 的 Cookie 或 LocalStorage）#P1 — `AgentDetector.detectBrowserProviders()`
- [x] [0.2.0-DATA-A-002] 探测本地安装的 AI IDE 或应用（如 Cursor、Warp 等）#P1 — `AgentDetector.detectAppProviders()`
- [x] [0.2.0-DATA-A-003] 探测环境变量或配置文件中的 API key（如 OpenAI、Anthropic、DeepSeek 等）#P1 — `AgentDetector.detectAPIKeyProviders()`
- [x] [0.2.0-DATA-A-004] 汇总探测结果，将每个 Agent 标记为「可用（已认证）」「待配置（需登录）」或「未安装」状态 #P1 — `DetectionResult.availableAgents` 等
- [x] [0.2.0-DATA-A-005] 探测结果决定菜单栏中展示哪些服务，不展示未安装或无需关注的服务 #P1 — `RefreshCoordinator` 过滤 `.notInstalled` snapshot

### DATA-B：订阅数据获取

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

### FE-A：刷新机制

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

### UI-A：动态数据展示

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

### QA-A：P1 完成定义

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

### DATA-A：订阅组（subscription group）语义

- [x] [0.3.0-DATA-A-000] `QuotaWindow` 增加 `subscriptionGroup` 字段，语义为「独立计费的订阅组」；fallback 到 `providerKind.rawValue`（未显式设的 parser 视为整个 provider = 1 个订阅组）#P1 — `QuotaModels.swift:subscriptionGroup`
- [x] [0.3.0-DATA-A-001] 所有 parser 显式设 subscriptionGroup：Codex=`"codex"`、Kimi=`"kimi"`（含 web + CLI 两条路径）、MiniMax CLI 按 `modelName.lowercased()`、Antigravity 主路径按 `group.displayName` / fallback 路径固定 `"Gemini"` + `"Other"` #P1
- [x] [0.3.0-DATA-A-002] `PreferencesStore.QuotaPreferences` 新增 `subscriptionGroupOrder: [String: [String]]` 字段（key = `providerKind.rawValue`），Codable 向后兼容（旧配置自动获得 `[:]`）#P1
- [x] [0.3.0-DATA-A-003] `ProviderSnapshot` 新增 `subscriptionGroups(customOrder:)` 与 `primarySubscriptionGroupWorstQuota(itemOrder:)` 两个方法：前者按订阅组分组（组顺序继承用户排序），后者取排序后第一个订阅组的 worst quota #P1
- [x] [0.3.0-DATA-A-004] 修正 `subscriptionGroups(customOrder:)` 的排序语义：`customOrder` 必须按订阅组 key 排序而不是 quota stableKey；Kimi Work / Code 无论来源如何都强制归为 `kimi` 单订阅组 #P1
- [x] [0.3.0-DATA-A-005] 恢复 Kimi Work 已验证数据路径：Work/Code 三条额度只由浏览器 `kimi-auth` cookie 调 `GetSubscriptionStat` 产生；`KimiAuthProvider` 保持 CLI Code-only fallback；`GetSubscription` tier/price 请求失败或超时不得阻塞 Work 额度显示 #P1

### UI-A：拖拽排序与状态联动（语义升级）

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

### FE-A：Streaming 刷新（per-provider 增量发布）

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

### PM-A：偏好设置与后续能力

- [ ] [0.3.0-PM-A-000] 偏好设置页面 / 窗口：Provider 开关、刷新间隔自定义、高级选项 #P2 #deferred
- [ ] [0.3.0-PM-A-001] 支持手动添加/移除 Provider，覆盖自动探测结果 #P2 #deferred
- [ ] [0.3.0-PM-A-002] 支持选择不同的浏览器作为 Cookie 来源（Safari / Chrome / Firefox）#P2 #deferred
- [ ] [0.3.0-PM-A-003] 支持菜单栏图标合并模式（单图标汇总 vs 多图标分 Provider）#P2 #deferred
- [ ] [0.3.0-PM-A-004] 支持 Provider 服务状态监控（incident 检测与展示）#P2 #deferred
- [ ] [0.3.0-PM-A-005] 支持 WidgetKit 桌面小组件 #P2 #deferred
- [ ] [0.3.0-PM-A-006] 支持 CLI 命令行工具（`quotabar status`）#P2 #deferred

## Phase - v0.4.0 - 新 Provider 接入（zcode / 千问 / 其他）

> 用户电脑实测已装：
> - `/Applications/ZCode.app`（bundle id `dev.zcode.app`、version 3.1.2，智谱 BigModel Z Code 桌面 IDE），运行时主进程 + `zcode-cli` 进程在跑；
> - 千问桌面 App 未在 `/Applications`、`~/Applications`、`~/Library/Application Support` 找到，等用户确认实际安装位置。
>
> zcode 是 opencode 的 fork/skin（用 `https://opencode.ai/config.json` schema），走 anthropic 兼容 API；
> 凭证、配置、套餐额度本地缓存统一在 `~/.zcode/v2/` 目录下。

### DATA-A：智谱 BigModel Z Code (zcode)

- [ ] [0.4.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.zcode` 枚举值，`displayName = "Z Code"`、`brandColor`、`iconSymbol`、`bundleIdentifier = "dev.zcode.app"`、`credentialFiles = ["~/.zcode/v2/credentials.json"]`、`envVarNames = []` 等元数据补齐 #P1
- [ ] [0.4.0-DATA-A-001] `ZCodeAuthProvider` 实现：从 `~/.zcode/v2/config.json` 读启用 plan 的 API key + baseURL，对 plan endpoint 发 anthropic 兼容 API 拉 usage；解析剩余额度到 `[QuotaWindow]` #P1
- [ ] [0.4.0-DATA-A-002] 套餐映射：识别 `builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan` 4 种 plan，subscriptionGroup 按 plan 区分（每个 plan = 1 个订阅组）；价格映射到 `ProviderPricing` #P1
- [ ] [0.4.0-DATA-A-003] `ZcodeLoginRunner` + `InstallDetectorProvider`：探测 `dev.zcode.app` bundle 安装和 `~/.zcode/v2/config.json` 存在性，驱动 pipeline 串接 #P1
- [ ] [0.4.0-DATA-A-004] `Strategies.zcodePipeline()` 接入 `RefreshCoordinator`，凭证缺失时 fallback 到 Keychain / `needsConfiguration` 状态 #P1

### DATA-B：阿里通义千问桌面 App

- [ ] [0.4.0-DATA-B-000] 用户确认千问桌面 App 实际安装路径（`/Applications` / `~/Applications` / DMG 挂载点 / 第三方目录） #blocked — 用户已声明"已装"但实际未在常见位置发现，需要确认
- [ ] [0.4.0-DATA-B-001] 在 `ProviderKind` enum 新增 `.qwen` 枚举值，元数据补齐（`bundleIdentifier` 等安装探测需要用户提供）#blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-DATA-B-002] `QwenAppProvider` 实现：dashboard endpoint 走浏览器 Cookie 路径（参考 Kimi `BrowserCookieProvider` + `KimiSubscriptionStatParser`），凭证从浏览器 Cookie 读取 #blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-DATA-B-003] `Strategies.qwenPipeline()` 接入 `RefreshCoordinator`，bundle 安装但 Cookie 未登录时降级到 `needsConfiguration` #blocked — 依赖 [0.4.0-DATA-B-002]

### DATA-C：新 Provider 接入通用流程

- [ ] [0.4.0-DATA-C-000] 文档化新 Provider 接入流程（`AGENTS.md` 或 `quota-bar/AGENTS.md`）：从「确认安装位置 → 找 dashboard API → 写 parser → 接入 pipeline → UI 验证」5 步模板，供后续 Provider 接入参考 #P2

### QA-A：v0.4.0 完成定义

- [ ] [0.4.0-QA-A-001] Z Code Provider：登录态正常时能在 dropdown 展示至少 1 个订阅组，下拉面板数字 / 状态灯 / bar 与其他 Provider 一致；未登录时降级到 `needsConfiguration` 不卡死
- [ ] [0.4.0-QA-A-002] 千问 Provider（实现后）：同上 #blocked — 依赖 [0.4.0-DATA-B-000]
- [ ] [0.4.0-QA-A-003] 文档已更新（README 列出已支持 Provider 清单 + 各 Provider 接入说明）
- [ ] [0.4.0-QA-A-004] `cd quota-bar && swift build` / `swift run` 通过

### UI-B：可用订阅计数反映实际可用性

> Bug 修复：顶部「可用订阅 N/M」之前只看 `availability == .available`，导致 Kimi 红灯（worst quota 已耗尽）时 N/M 仍显示 4/4，与状态灯颜色不一致。
> 修复后 N/M 与状态灯走同一逻辑：top group worst quota `remainingFraction > 0` 才计为可用，红灯不计。

- [x] [0.4.0-UI-B-000] `DashboardState.availableCount` 改为只统计 `.available` 且 top subscription group worst quota `remainingFraction > 0` 的 snapshot；与 `ProviderSnapshot.statusColor(itemOrder:)` 的红灯判定走完全相同的逻辑（避免出现"灯红但 N/M 不动"的割裂）#bugfix — `QuotaModels.swift:availableCount`
- [x] [0.4.0-UI-B-001] `DashboardState.availabilityText` 同步标记 `@MainActor`（因 `availableCount` 需要读 `PreferencesStore.shared`，后者是 MainActor 隔离）#bugfix — `QuotaModels.swift:availabilityText`
