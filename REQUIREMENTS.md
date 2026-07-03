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
- [x] [0.2.0-DATA-B-028] Antigravity 额度 fallback 顺序必须是本地 IDE/RPC → `agy` CLI 运行时本地 RPC → 其他低优先级兜底；WebView 不是额度主链路，只能作为最后的账号/订阅页兜底入口 #P1
- [ ] [0.2.0-DATA-B-017] 同一服务多身份合并/拆分（如 Kimi Code / Kimi Work、work + personal 账号）#P2 #deferred — 当前架构每个 ProviderKind 只返一条 snapshot
- [x] [0.2.0-DATA-B-018] 移除 Gemini 主动采集 pipeline，Google 系额度由 Antigravity 接替 #P1
- [x] [0.2.0-DATA-B-019] Provider pipeline 在首个数据源缺凭证时继续尝试后续数据源，避免 MiniMax/Kimi/Codex 因 API key 或 OAuth 缺失而跳过 Cookie/CLI fallback #P1
- [x] [0.2.0-DATA-B-020] Cookie dashboard 响应中的订阅档位/费用信息传递到 UI，MiniMax Web 路径支持 `current_package_name` 和已知 Coding Plan 价格映射 #P1
- [ ] [0.2.0-DATA-B-021] Trae Work 是否独立接入 #P2 #deferred — 官方已有 TRAE Work 与用量/订阅概念，值得作为独立 provider 继续调研；当前缺少已验证本地 CLI、App 或 dashboard endpoint，不并入 P1 核心
- [x] [0.2.0-DATA-B-022] 默认自动刷新不得主动执行浏览器 Cookie 数据源，避免未明确授权前弹出系统密码或 Full Disk Access 相关弹窗；浏览器来源只保留为后续显式启用/调试路径 #P1
- [x] [0.2.0-DATA-B-023] Codex 额度必须优先以真实 `wham/usage` 响应为准；`auth.json` 的 `id_token` 过期日只能作为真实请求失败后的辅助状态，不能在请求前短路；本地日志估算不得冒充真实额度显示为 100% #P1
- [x] [0.2.0-DATA-B-024] Kimi 默认优先使用本地 OAuth 凭证路径，浏览器 Cookie 只能作为显式启用后的补充，避免 Kimi 刷新慢时先触发浏览器权限弹窗 #P1
- [x] [0.2.0-DATA-B-025] Kimi 默认优先读取 Kimi Desktop `bridge-store/token-store.json` 中的 Web access token 调 `GetSubscriptionStat`，在不读取浏览器 Cookie 的前提下获取 Work 月额度、Code 5h/周额度、订阅档位和到期日；CLI OAuth 仅作为 Code-only fallback #P1
- [x] [0.2.0-DATA-B-026] Kimi Desktop 数据源必须同时调用 `GetSubscriptionStat`（Work + Code + 到期日）和 `GetSubscription`（订阅名 + 价格），并在 `subscriptionBalance` 缺少 `amountUsedRatio` 时支持 used/total 或 remaining/total 形式解析 Work 月额度 #P1
- [x] [0.2.0-DATA-B-027] Kimi `GetSubscriptionStat` 在 `ratelimitCode5h/7d` 不返回独立 ratio 时，必须使用 `subscriptionBalance.kimiCodeUsedRatio` 计算 Code 5 小时和周额度，避免误显示 100% #P1

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
- [x] [0.2.0-FE-A-010] 菜单栏多 bar 只表达真实可用额度、刷新占位或明确过期状态；`needsConfiguration` / `notSubscribed` / `notInstalled` / `fetchFailed` 不得绘制 50% 占位 bar，避免下拉显示未配置但菜单栏像有额度 #P1

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

- [x] [0.4.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.zcode` 枚举值，`displayName = "Z Code"`、`brandColor`、`iconSymbol`、`bundleIdentifier = "dev.zcode.app"`、`credentialFiles = ["~/.zcode/v2/credentials.json"]`、`envVarNames = []` 等元数据补齐 #P1
- [x] [0.4.0-DATA-A-001] `ZCodeAuthProvider` 实现：从 `~/.zcode/v2/config.json` 读启用 plan 的 API key + baseURL，对 plan endpoint 发 anthropic 兼容 API 拉 usage；解析剩余额度到 `[QuotaWindow]` #P1
- [ ] [0.4.0-DATA-A-002] 套餐映射：识别 `builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan` 4 种 plan，subscriptionGroup 按 plan 区分（每个 plan = 1 个订阅组）；价格映射到 `ProviderPricing` #P1
- [ ] [0.4.0-DATA-A-003] `ZcodeLoginRunner` + `InstallDetectorProvider`：探测 `dev.zcode.app` bundle 安装和 `~/.zcode/v2/config.json` 存在性，驱动 pipeline 串接 #P1
- [x] [0.4.0-DATA-A-004] `Strategies.zcodePipeline()` 接入 `RefreshCoordinator`，凭证缺失时 fallback 到 Keychain / `needsConfiguration` 状态 #P1
- [x] [0.4.0-DATA-A-005] Z Code 刷新失败时 UI 必须保留真实失败原因（如 API key 无效、plan 未开通、quota endpoint 不可用），不能被安装探测文案覆盖成只有“App 已装” #P1
- [x] [0.4.0-DATA-A-006] Z Code quota API 未返回可渲染额度时读取 `~/.zcode/v2/coding-plan-cache.json`，展示可用 plan 与 `coding_plan_not_entitled` 等本地真实状态；该缓存不包含额度数值时不得伪造 quota bar #P1
- [x] [0.4.0-DATA-A-007] Z Code `builtin:bigmodel-start-plan` 优先从 `https://zcode.z.ai/api/v1/zcode-plan/billing/balance?app_version=...` 读取 `balances[]`，按 GLM-5.2 / GLM-5-Turbo 解析每日 token 额度、重置时间和 plan 名；旧 `api/monitor/usage/quota/limit` 仅作兼容 fallback #P1
- [x] [0.4.0-DATA-A-008] 当 Z Code `billing/balance` 或 `billing/current` 返回 `plans: []` / `balances: []` 时，UI 必须如实显示“服务端未返回可渲染额度”，不得把本地 plan-cache 的“available”误当作额度成功 #P1

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
- [x] [0.4.0-QA-A-003] 文档已更新（README 列出已支持 Provider 清单 + 各 Provider 接入说明）
- [ ] [0.4.0-QA-A-004] `cd quota-bar && swift build` / `swift run` 通过

### UI-B：可用订阅计数反映实际可用性

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

### CI-A：发布自动化 + PR 验证（围绕 3 件事）

> 1. **修改后在本地自动打包** —— `AGENTS.md` 已要求（`./scripts/build-app.sh`），不需要 GitHub
>    代码自动化，agent 遵守 AGENTS 即可，无需本 phase 任务。
> 2. **提交后自动打包到 Release** —— 需要 GitHub Actions 自动化。
> 3. **PR 合并前自动验证** —— 工程卫生类，需要 GitHub Actions。

- [x] [0.5.0-CI-A-000] 已存在 `.github/workflows/release.yml` 在 main push 触发里加 `./quota-bar/scripts/build-app.sh` 步骤（确保 main push 后自动产 .app 并发到 pre-release）；用户可感知：每个 commit 都自动有可下载的 .app #P1
- [x] [0.5.0-CI-A-001] `release.yml` 加 `cd web && npm ci && npm run build` 步骤，让营销主页（quotabar.ddonlien.com）跟着主仓一起更新 #P2
- [x] [0.5.0-CI-A-002] 新增 `.github/workflows/pr-check.yml`：PR 触发时跑 `swift build`（PR 合并前自动验证，避免坏改动进 main）#P1

### ENG-A：工程卫生基础设施（用户间接感知：可信任的代码质量、dev 入口友好）

- [x] [0.5.0-ENG-A-000] 清掉 pre-existing Swift warning（`MiniMaxConfigProvider.swift:346` 的未使用 `prefix`、`EdgeCookieReader.swift` 的未使用 `placeholders`）；用户间接感知：build 输出干净，CI 日志少噪音 #P1
- [x] [0.5.0-ENG-A-001] `Makefile` 或 `scripts/dev.sh` 入口封装 `swift build` / `swift run` / `swift test` / `./scripts/build-app.sh` / `cd web && npm ci && npm run build`，README / AGENTS 里只引用这一个入口；用户/贡献者间接感知：上手命令更一致 #P2
- [x] [0.5.0-ENG-A-002] 根 `.gitignore` 加 `web/node_modules/` / `web/dist/` / `web/.astro/` 双保险（当前靠 `web/.gitignore` 排除，但根 ignore 双保险更稳；上次 rsync 误把这些拷到了 worktree）#P1
- [x] [0.5.0-ENG-A-003] `Package.swift` 加 `Tests/QuotaBarTests/` test target（测试用例本身作为各功能任务的 `<parent>-test` 子任务登记，不在 phase 顶层列具体测试）#P2

### DOC-A：可被用户感知的文档

- [x] [0.5.0-DOC-A-000] `README.md` 的「快速开始」增补 web 子项目（`cd web && npm install && npm run dev`）的独立段落；当前 README 只在「目录结构」里提到 web/；用户可感知：能直接看到怎么本地跑 web 主页 #P2

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

### ARCH-A：订阅日期抓取基础架构

> 提供给各 provider 复用的 headless 抓取 + DOM 提取框架。Kimi 这种直接 API 返回 expireTime 的不走这个架构，但协议入口统一。

- [x] [0.6.0-ARCH-A-000] 设计 `SubscriptionDateHarvester` 协议：每个 provider 实现 `harvest(from data: Data) async throws -> Date?`，输入是抓到的页面 Data（或 WKWebView handle），输出是订阅到期日；找不到返回 nil #P1
- [x] [0.6.0-ARCH-A-001] `WKWebViewHeadlessLoader` 实现：注入 `WKHTTPCookieStore` cookie → 加载 URL → 等 `network idle` / 特定 DOM 节点出现 → 回调 `Data` 或 `String`；可在 `FetchPipeline` strategy 中复用，超时与现有 strategy 一致 #P1
- [x] [0.6.0-ARCH-A-002] 删 `ProviderSnapshot.init` 里 `quotas.compactMap(\.resetsAt).max()` fallback：找不到真实到期日时 `subscriptionExpiresAt = nil`（UI 自动不显示）；同时把 `subscriptionExpiresAt` 文档从"默认从 max(resetsAt) 推断"改成"nil = 不展示" #P1
- [x] [0.6.0-ARCH-A-003] `DashboardParser` 协议加 `parseSubscriptionExpiresAt(data: Date = Date()) -> Date?`，默认实现返回 nil；Kimi 展示日期必须来自明确的订阅/续费来源，不能把 quota reset 或无法确认语义的字段当作到期日 #P1
- [x] [0.6.0-ARCH-A-003-test] 给 harvester 协议 + fallback 改 hide 写单元测试：mock HTML feed 解析，验证 `subscriptionExpiresAt` 正确 / 不正确两种路径 #P1
- [x] [0.6.0-ARCH-A-001-test] `WKWebViewHeadlessLoader` 集成测试：mock URLProtocol 喂 HTML，验证 cookie 注入 + DOM ready 等待 + 超时降级 #P1

### DATA-A：Kimi 真实订阅到期日（已有数据，5 行代码）

> Kimi 的 `GetSubscriptionStat` 响应里 `subscriptionBalance.expireTime` **就是真实的订阅到期日**，但当前代码把它错塞到 Work quota 窗口的 `resetsAt`。这是最快、最稳的 1 个 provider，先打通。

- [x] [0.6.0-DATA-A-000] `KimiSubscriptionStatParser` 解析 `subscriptionBalance.expireTime` 后**不再塞给 Work quota 的 `resetsAt`**（Work 的 resetsAt 应该是月度窗口的滚动结束时间，跟 subscription 到期日是不同概念）#P1
- [x] [0.6.0-DATA-A-001] Kimi `ProviderSnapshot.subscriptionExpiresAt` 使用 `GetSubscription.nextBillingTime` 作为“下一次续费日”来源，转换为本地自然日的前一天作为“最后有效日”；不再使用 `subscriptionBalance.expireTime` / `currentEndTime` 直接展示，避免把续费日或服务端结束时间错显示为 7/10 #P1
- [x] [0.6.0-DATA-A-002] Work quota 窗口的 `resetsAt` 改为从 `subscriptionBalance.expireTime` 反推或保留为 nil（让 UI 不显示月度 quota 的"重置时间"——已经隐含在 subscriptionExpiresAt 里，避免双信息）；如需要月度窗口重置，则计算 `now + periodSeconds` 兜底 #P1
- [x] [0.6.0-DATA-A-002-test] 单元测试：mock `GetSubscriptionStat` JSON 验证 stat parser 不再输出展示到期日，mock `GetSubscription.nextBillingTime` 验证续费日前一天会显示为最后有效日；Work quota `resetsAt` 不再等于 expireTime #P1

### DATA-B：Codex 真实订阅到期日（headless 抓订阅页）

> Codex (chatgpt.com) 的 `/backend-api/wham/usage` 只返回 quota 窗口，**不返回订阅到期日**。需要 headless 抓 `chatgpt.com/account/manage` 或 `chatgpt.com/settings/billing` 页面，提取「Next billing date」「Renewal date」之类 DOM 文本。

- [ ] [0.6.0-DATA-B-000] `CodexHarvester` 实现：用 `WKWebViewHeadlessLoader` 加载 `https://chatgpt.com/account/manage`，DOM 提取续费日期；找不到返回 nil；超时/Cloudflare challenge 失败抛 `QuotaFetchError.transient` 让 pipeline 降级 #P1
- [ ] [0.6.0-DATA-B-001] `CodexAuthProvider` / `BrowserCookieProvider` Codex 路径新增 strategy：headless 抓订阅页 → 拿 `subscriptionExpiresAt`；和现有 quota 抓取并行，结果合并到 `ProviderSnapshot` #P1
- [ ] [0.6.0-DATA-B-002] Codex 到期日不能使用过期 `id_token` 的 `chatgpt_subscription_active_until` 继续展示；本地 auth 元数据 stale 但 quota 仍成功时，应隐藏日期或通过后续 WebView/DOM 授权源拿真实日期 #P1
- [ ] [0.6.0-DATA-B-001-test] 单元测试：mock HTML（含"Next billing on July 25, 2026"等常见模式）验证 `CodexHarvester` 解析出正确 `Date` #P1

### DATA-C：Claude 真实订阅到期日（headless 抓订阅页）

> Claude (claude.ai) 的 `/api/organizations/{uuid}/usage` 不返回订阅到期日。需要 headless 抓 `claude.ai/settings/plan` 或 `claude.ai/account/billing`，提取「Next billing」「Renews on」之类。

- [ ] [0.6.0-DATA-C-000] `ClaudeHarvester` 实现：加载 `https://claude.ai/settings/plan`，DOM 提取续费日期 #P1
- [ ] [0.6.0-DATA-C-001] 集成到 `BrowserCookieProvider` Claude 路径 #P1
- [ ] [0.6.0-DATA-C-001-test] 单元测试：mock HTML 验证解析 #P1

### DATA-D：Cursor 真实订阅到期日（headless 抓订阅页）

> Cursor (cursor.com) 的 dashboard 走 `cursor.com/api/...`，但续费日通常在 `cursor.com/dashboard` 顶部"Plan"卡片里。需要 headless 抓页面。

- [ ] [0.6.0-DATA-D-000] `CursorHarvester` 实现：加载 `https://cursor.com/dashboard`，提取"Pro plan renews on..."或类似 #P1
- [ ] [0.6.0-DATA-D-001] 集成到 `BrowserCookieProvider` Cursor 路径 #P1
- [ ] [0.6.0-DATA-D-001-test] 单元测试：mock HTML 验证解析 #P1

### DATA-E：MiniMax 真实订阅到期日（headless 抓订阅页）

> MiniMax Web (minimaxi.com / api.minimaxi.com) 的 `coding_plan/remains` 不返回订阅到期日。需要 headless 抓 `minimaxi.com/user-center/payment/balance` 或类似。

- [ ] [0.6.0-DATA-E-000] `MiniMaxHarvester` 实现：定位 MiniMax 订阅管理页 URL，提取续费日期 #P1
- [ ] [0.6.0-DATA-E-001] 集成到 `BrowserCookieProvider` MiniMax 路径 #P1
- [ ] [0.6.0-DATA-E-001-test] 单元测试 #P1

### DATA-F：Antigravity 真实订阅到期日（headless 抓订阅页）

> Antigravity 是 Google 系的 IDE，订阅状态在 Google Cloud 控制台或 antigravity.google 域内。可能需要登录 Google account 后访问 antigravity.google/settings。

- [ ] [0.6.0-DATA-F-000] `AntigravityHarvester` 实现：定位 Antigravity 订阅管理页 URL，提取续费日期；可能需要跟随重定向到 accounts.google.com 完成登录 #P1
- [ ] [0.6.0-DATA-F-001] 集成到 `BrowserCookieProvider` / `AntigravityDashboardProvider` 路径 #P1
- [ ] [0.6.0-DATA-F-001-test] 单元测试 #P1

### UI-A：UI 调整（找不到时 hide，不显示"刷新时间未知"）

> `subscriptionExpiresAt = nil` 时 `MenuView.PlanHeader.expiresAtText` 已经返回 nil，UI 不显示。**但**需要确认：
> 1. dropdown 价格行 layout 不要因为 hide 产生跳动；
> 2. 把目前灰色的 "刷新时间未知" 文案在 quota row 里保留（那不是 subscriptionExpiresAt，是 quota resetsAt，是另一个字段）；
> 3. tooltip 提示用户"日期未配置"（可选，nice-to-have）

- [x] [0.6.0-UI-A-000] 验证 `MenuView.PlanHeader.expiresAtText == nil` 时 HStack 收缩正常（价格仍居右、不留空隙）#P1
- [x] [0.6.0-UI-A-001] 给 `expiresAtText` 加 `.help("...")` tooltip：显示「订阅续费日期」+ 完整 ISO 日期（让用户 hover 能看到精确时间）#P2
- [x] [0.6.0-UI-A-002] `expiresAtText` tooltip 文案统一为「最后有效日期」，和 UI 日期语义一致；续费日只作为 provider 原始来源，不直接对用户展示 #P2

## Phase - v0.7.0 - 智谱 GLM Provider 接入（feat/glm-provider）

> **承接关系**：v0.4.0 phase 在用户电脑上已完成 zcode App 安装调研（`/Applications/ZCode.app`、bundle id `dev.zcode.app`、`~/.zcode/v2/` 目录布局、4 种 plan 标识），但 Provider 接入代码本身未落地。v0.7.0 把调研成果转为正式版任务，在 `feat/glm-provider` branch 上推进。
>
> **zcode 是什么**：智谱 BigModel Z Code（`https://zcode.z.ai`）桌面 IDE，是 opencode 的 fork/skin，走 anthropic 兼容 API；4 种 plan（`builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan`）覆盖智谱开放平台 + Z.ai 海外版两套站点。
>
> **为什么叫 GLM 而不是 zcode**：用户对外沟通时用「GLM」（智谱模型族名）覆盖度更广；内部 provider 名沿用 `zcode`（与 bundle id / config 路径一致），UI 显示名用 `Z Code`。
>
> **与 v0.6.0 第二批的关系**：v0.7.0 不属于 v0.6.0 第二批（第二批是 headless 抓订阅页拿订阅到期日）。GLM 接入是独立工作线（要做完整 provider + 套餐映射），所以单独立 phase。

### DATA-A：智谱 BigModel Z Code (zcode) Provider 接入

> 任务继承自 v0.4.0 phase 的 `### DATA-A：智谱 BigModel Z Code (zcode)`（4 项），但每项提升到 v0.7.0 phase 顶层，确保 `feat/glm-provider` branch 推进时有稳定的 v0.7.0 编号。

- [x] [0.7.0-DATA-A-000] 在 `ProviderKind` enum 新增 `.zcode` 枚举值，`displayName = "Z Code"`、`brandColor`、`iconSymbol`、`bundleIdentifier = "dev.zcode.app"`、`credentialFiles = ["~/.zcode/v2/credentials.json"]`、`envVarNames = []` 等元数据补齐 #P1
- [x] [0.7.0-DATA-A-001] `ZCodeAuthProvider` 实现：从 `~/.zcode/v2/config.json` 读启用 plan 的 API key + baseURL，对 plan endpoint 发 anthropic 兼容 API 拉 usage；解析剩余额度到 `[QuotaWindow]` #P1
- [ ] [0.7.0-DATA-A-002] 套餐映射：识别 `builtin:bigmodel-start-plan` / `builtin:bigmodel-coding-plan` / `builtin:zai-start-plan` / `builtin:zai-coding-plan` 4 种 plan，subscriptionGroup 按 plan 区分（每个 plan = 1 个订阅组）；价格映射到 `ProviderPricing` #P1
- [ ] [0.7.0-DATA-A-003] `ZcodeLoginRunner` + `InstallDetectorProvider`：探测 `dev.zcode.app` bundle 安装和 `~/.zcode/v2/config.json` 存在性，驱动 pipeline 串接 #P1
- [x] [0.7.0-DATA-A-004] `Strategies.zcodePipeline()` 接入 `RefreshCoordinator`，凭证缺失时 fallback 到 Keychain / `needsConfiguration` 状态 #P1
- [x] [0.7.0-DATA-A-005] web/DESIGN.md 中 `--provider-zcode` 的 brandColor 在 app DESIGN.md / QuotaModels 中同步落地（当前 web 占位 `#3866ff`，app 端选色待定）#P1

### FE-A：菜单栏 bar 集成

> Z Code 接入后菜单栏多 bar 视图自动包含这个新 provider（无需单独代码改动，靠 `ProviderKind.allCases` 驱动）。但需要确认 menu bar 配色不冲突、bar 高度映射正确。

- [ ] [0.7.0-FE-A-000] Z Code 接入后菜单栏 status item 多 bar 自动包含；确认 5+ bar 时视觉清晰、无重叠 #P1
- [ ] [0.7.0-FE-A-001] Z Code 状态灯（brandColor）与其他 provider 在 dropdown / status bar 都正确渲染 #P1

### DOC-A：用户可见文档

- [x] [0.7.0-DOC-A-000] README.md 的「已支持 Provider」列表追加 Z Code（含 4 种 plan 简要说明 + 安装路径）#P1

## Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型）

> **触发 bug**：user 实测发现 `~/.codex/auth.json` 的 id_token 里 `chatgpt_subscription_active_until = 2026-06-25`，但 Codex.app 在订阅过期后调 `wham/usage` 仍能拿到 200 OK，**响应里** `plan_type` 跌成 `"free"`，`rate_limit.primary_window.limit_window_seconds` 跳到 `2592000`（30 天），被现有 parser 错误地按"5h 窗口"处理 → UI 推断成"月额度" → 显示"5% 月额度"——**完全是误导**。从原理上"用 quota 数值反推过期"就不靠谱（quota 数值会因用量变化、API 改动、free 用户本来就有月度窗口而误判）。
>
> **解决思路**：订阅状态最权威的来源 = 服务商在用户登录时写下来的本地授权元信息（OpenAI 把订阅到期日塞进 id_token 的 payload；其他 provider 类似），**不依赖网络、不需要解析 quota window**。按 user 提的优先级："app 授权信息 > CLI 指令 > Web 抓取"。
>
> **本 phase 第一批只覆盖 Codex**（user 当前 case），其他 provider 沿用同一 inspector 模式扩展：
> 1. 从 `~/.codex/auth.json` 的 `id_token` 解码出 `chatgpt_plan_type` + `chatgpt_subscription_active_until`
> 2. 过期时直接返回 `.subscriptionExpired` snapshot，不让 free 用户的"月额度"窗口被任何 strategy 渲染
> 3. UI 状态灯红色 + 灰标"订阅已过期 · Plus · 到期 2026/6/25"
> 4. CodexDashboardParser 加 `plan_type == "free"` 防御，避免 BrowserCookie 路径绕过
>
> **不做什么**（YAGNI）：
> - 不重写整个订阅状态机——本 phase 只识别"过期 / free"两种清楚状态，"明天即将到期提醒"留 P2
> - 不在 v0.8.0 接 Claude/Cursor/Antigravity 的同类检测——每个 provider 的 token 字段不一样（Claude 的 entitlement 路径不同，Cursor 走 dashboard 抓取，Antigravity 走本地 language_server），工作量是 Codex 的 3-5x
> - 不做"明天续费提醒"等可观察性优化

### ARCH-A：订阅状态基础架构

> Codex 一次落地，其他 provider 复用同模式。

- [x] [0.8.0-ARCH-A-000] `JWTPayloadDecoder` 工具：解 JWT payload 部分（不验签，只读 base64url+JSON），失败返回 nil #P1 — `SubscriptionInspector.swift:JWTPayloadDecoder`
- [x] [0.8.0-ARCH-A-001] `OpenAIAuthPayload` struct：把 `https://api.openai.com/auth` 命名空间下的字段组装成 Swift 类型（plan_type / active_start / active_until / last_checked）#P1
- [x] [0.8.0-ARCH-A-002] `SubscriptionStatus` 枚举：`.active(expiresAt)` / `.expired(lastPlan, expiredAt)` / `.free` / `.unknown`；`isEffectivelyExpired` 计算属性 #P1
- [x] [0.8.0-ARCH-A-003] `CodexSubscriptionInspector`：从 `~/.codex/auth.json` 解 id_token → 映射成 `SubscriptionStatus`；失败（文件缺失 / 字段缺失 / JWT 坏）一律返回 `.unknown`，**不要**瞎猜 #P1 — `SubscriptionInspector.swift:CodexSubscriptionInspector`
- [x] [0.8.0-ARCH-A-003-test] 单元测试：JWT 解析 4 种边界（合法 / 三段缺失 / base64 坏 / 非 JSON payload） + inspector 6 种路径（expired / active / free / 文件缺失 / 字段缺失） + `.isEffectivelyExpired` 语义 #P1

### DATA-A：Codex 订阅过期识别

- [x] [0.8.0-DATA-A-000] `CodexAuthProvider.fetchSnapshot` 在发 wham/usage 前先调 `CodexSubscriptionInspector.inspect()`，过期 / free 时**直接返回** `availability: .subscriptionExpired(plan, expiredAt)` 的 marker snapshot（**不** throw，让 pipeline 立即返回，不让后续 BrowserCookie / CLILog strategy 用 free 用户的"月额度"primary_window 覆盖掉正确状态）#P1
- [x] [0.8.0-DATA-A-001] `CodexDashboardParser.parse(data:)` 在响应 `plan_type == "free"` 时返回 nil（防御 BrowserCookie 路径：parser 直接拒绝 free 用户的"月额度"窗口，让 pipeline 走 fallback 而不是显示误导数据）#P1
- [x] [0.8.0-DATA-A-002] `BrowserCookieProvider.fetchSnapshotImpl`（Codex 路径）在发请求前先调 `CodexSubscriptionInspector`，过期 / free 时返回 marker snapshot（与 `CodexAuthProvider` 行为一致——保证两条路径都尊重订阅状态）#P1
- [x] [0.8.0-DATA-A-003] `ProviderAvailability` 加新 case `.subscriptionExpired(plan: String?, expiredAt: Date?)`；`statusColor` 给红色（`#FF453A`），区别于 `.needsConfiguration` 灰 / `.fetchFailed` 橙 #P1 — `QuotaModels.swift:ProviderAvailability`
- [x] [0.8.0-DATA-A-004] `QuotaFetchError` 加新 case `.subscriptionExpired(plan, expiredAt)`；`availabilityFallback` 返回 `.subscriptionExpired(plan, expiredAt)`；`fallbackPriority` = 2（与 missingCredentials 同级，"配置相关"问题）#P1
- [x] [0.8.0-DATA-A-005] `RefreshCoordinator.applyProviderResult.keepAfterApply` 把 `.subscriptionExpired` 当 keep=true（跟 `.needsConfiguration` 一样保留，让 UI 展示过期 hint）#P1
- [x] [0.8.0-DATA-A-006] `RefreshCoordinator.pickBestSnapshot.priority` 给 `.subscriptionExpired` 优先级 3（与 `.needsConfiguration` 同级）；`needsFullDiskAccess` switch 显式排除（不混淆 Full Disk Access 检测）#P1
- [x] [0.8.0-DATA-A-007] `ProviderFetchPipeline.merge.priority` 同样把 `.subscriptionExpired` 放 3（与 RefreshCoordinator 一致；目前 CodexPipeline 用 sequential 模式，parallel 模式留给将来 multi-source 的 provider）#P1
- [x] [0.8.0-DATA-A-001-test] 单元测试：CodexDashboardParser `plan_type=free` → nil；`planType` 大小写不敏感；`plan_type=plus` 仍正常解析 5h+weekly #P1
- [x] [0.8.0-DATA-A-000-test] 单元测试：ProviderSnapshot `.subscriptionExpired` 的 statusColor 安全（不读 quotas，quotas 为空时不崩）#P1

### UI-A：过期状态 UI 表现

- [x] [0.8.0-UI-A-000] `MenuView.PlanSection` 处理 `.subscriptionExpired(plan, expiredAt)`：不渲染任何 quota window（避免被 free 月度窗口误导），只展示一行灰标 hint `订阅已过期 · Plus · 到期 2026/6/25`（无 plan 时省略，无到期日时省略）#P1
- [x] [0.8.0-UI-A-001] `StatusBarController.drawableSnapshots` 把 `.subscriptionExpired` 当 drawable（区别于 `.notInstalled` / `.fetchFailed`），让菜单栏仍画 bar（0% 高度 + 最小占位 bar）以表达"我知道这个订阅存在但已过期" #P1
- [x] [0.8.0-UI-A-002] `StatusBarController.remainingFraction` 对 `.subscriptionExpired` 返回 0（与其他"用完"视觉一致，区别于 `.loading` / `.needsConfiguration` 的 50%）#P1
- [x] [0.8.0-UI-A-003] `StatusBarController.refreshStatusItemAppearance` tooltip 对 `.subscriptionExpired` 显示 `"Codex 已过期"`，区别于正常 `Codex 5%` / `Codex 刷新中` #P1

### DATA-B：其他 provider 沿用 Inspector 模式（v0.8.0 不落地，只登记）

> 每个 provider 的订阅状态来源不同，工作量是 Codex 的 3-5x。先登记，等 Codex 这条线稳定后再排期。

- [ ] [0.8.0-DATA-B-000] Claude 订阅到期日：claude.ai 的 session cookie 里解析 `membership_type` / `subscription_end_date` 字段；或抓 `claude.ai/settings/plan` DOM 提取"Next billing" #deferred — 等 v0.6.0-DATA-C（Claude 真实订阅到期日 headless 抓取）落地后顺手做
- [ ] [0.8.0-DATA-B-001] Cursor 订阅到期日：Cursor 没有原生 token 元信息，需要抓 `cursor.com/dashboard` DOM 提取"Plan renews on..." #deferred
- [ ] [0.8.0-DATA-B-002] MiniMax 订阅到期日：MiniMax Web dashboard `coding_plan/remains` 不返回订阅到期日；需要抓 `minimaxi.com/user-center/payment/balance` DOM #deferred
- [ ] [0.8.0-DATA-B-003] Antigravity 订阅到期日：走本地 language_server probe 不容易拿到订阅元信息，可能要抓 antigravity.google/settings 页面 #deferred
- [ ] [0.8.0-DATA-B-004] Kimi 订阅到期日：已通过 `KimiSubscriptionStatParser.parseSubscriptionExpiresAt` 从 `subscriptionBalance.expireTime` 提取（v0.6.0 已落地）；但**没有过期判定**——只填 `subscriptionExpiresAt`，UI 仅在 `.available` 时显示日期，过期后会显示一个"很久以前"的到期日但不报红 #cut — 实际 Kimi 不会让订阅过期数据继续返回，过期后会跌到 free 不返 quota，行为自然

### DATA-C：Codex pipeline 不短路 inspector（v0.8.1 修订）

> **修订原因**：v0.8.0 把 inspector 短路写在 `CodexAuthProvider` + `BrowserCookieProvider` Codex 路径两处，
> user 实测反馈：昨天 web 续费后 `~/.codex/auth.json` 没刷新（Codex.app 自己写本地缓存，web 续费不触发 OAuth flow），
> inspector 看到陈旧 `chatgpt_subscription_active_until` → 误判过期 → 但 BrowserCookie 路径用浏览器已登录会话
> 能拿到真实 plus quota。v0.8.0 行为把 inspector 当"绝对权威"短路所有 strategy，结果活跃订阅被错标过期。
>
> v0.8.1 调整：inspector 仍然是「权威」（不是完全抛弃），但**只在 CodexAuthProvider 一处检测**，
> 检测到过期时**throw** 让 pipeline 继续走 BrowserCookie / CLILog / Keychain。BrowserCookie 路径信任
> `CodexDashboardParser.plan_type=free → nil` 的 parser 层防御，不在入口再次拦截。
> 续费后 Codex.app 重新 OAuth refresh → auth.json 写入新 id_token → inspector 看到新到期日 → 回到正常路径。
>
> 这与 user 的优先级「app 授权信息 > CLI 指令 > Web 抓取」一致：app 授权信息（OAuth → wham/usage）
> 是主路径，Web（BrowserCookie）只是兜底；inspector 检测应该让 OAuth + Web 都有机会尝试，而不是
> 在第一道就堵死。

- [x] [0.8.0-DATA-C-000] `CodexAuthProvider.fetchSnapshot`：inspector 报 `.expired` / `.free` 时**throw** `QuotaFetchError.subscriptionExpired(plan, expiredAt)`（替换 v0.8.0-DATA-A-000 的"直接 return marker"行为），让 pipeline 继续走 BrowserCookie / CLILog / Keychain fallback #P1
- [x] [0.8.0-DATA-C-001] `BrowserCookieProvider.fetchSnapshotImpl` Codex 路径：移除 v0.8.0-DATA-A-002 加的 inspector 调用；信任 `CodexDashboardParser.plan_type=free → nil` 的 parser 层防御（parser 拒绝 free 用户的"月额度"窗口，让 BrowserCookie 也能 fallback 到 inspector 没看到的活跃订阅）#P1
- [x] [0.8.0-DATA-C-002] `RefreshCoordinator.applyProviderResult`：当 `error as? QuotaFetchError` 是 `.subscriptionExpired` 时，优先用 `qe.availabilityFallback`（=`.subscriptionExpired(plan, expiredAt)`），不被 `installDetail` 覆盖成 `.needsConfiguration`（防止 Codex.app 已装时把"订阅已过期"误显示为"待配置"）#P1
- [x] [0.8.0-DATA-C-003] `RefreshCoordinator.applyProviderResult`：其他 error type（`.missingCredentials` / `.permissionRequired` / `.transient` / `.sourceUnavailable`）仍走 installDetail fallback（保留 install 检测信号）#P1
- [x] [0.8.0-DATA-C-000-test] 单元测试：`CodexAuthProvider.fetchSnapshot` 在 inspector 报 `.expired(plus, ...)` 时 throw `.subscriptionExpired(plan: "plus", expiredAt)`；在 inspector 报 `.free` 时 throw `.subscriptionExpired(plan: nil, expiredAt: nil)`；不会向 endpoint 发请求（endpoint 用 `https://example.invalid/never-called`）#P1
- [x] [0.8.0-DATA-C-001-test] 单元测试：`BrowserCookieProvider` Codex 路径在 inspector expired 的 auth.json 存在 + cookie reader 为空时，**不再** throw `.subscriptionExpired`，而是走 `missingCredentials` / `sourceUnavailable` 路径（验证 v0.8.0 的 inspector 二次短路被移除）#P1
- [x] [0.8.0-DATA-C-002-test] 单元测试：`ProviderPipelines.makePipelines` 的 Codex pipeline 顺序仍是 `[codex-auth, codex-cookie, codex-cli, codex-keychain]`，`runMode == .sequential`（确保 inspector throw 后真能走到 BrowserCookie / CLILog / Keychain）#P1
- [x] [0.8.0-DATA-C-004-test] 单元测试：`QuotaFetchError.subscriptionExpired(plan, expiredAt).availabilityFallback` 返回 `.subscriptionExpired(plan, expiredAt)`（契约）；`.subscriptionExpired(plan: nil, expiredAt: nil)` 也正常 fallback（用于 .free 状态）#P1

## Phase - v0.9.0 - 持久化、来源索引与启动兜底

> **目标**：Quota Bar 在重开、更新、重装或刷新期间不应出现“已知订阅突然消失 / 凭证来源丢失 / 数值短暂空白”的体验；同时刷新失败时也不能继续显示旧缓存假装可用。
>
> **持久化边界**：
> - 额度、订阅状态、过期时间的最新实时值和用于渲染视觉的值，以内存中的 `DashboardState` 为准。
> - 偏好继续保存到 `~/Library/Application Support/QuotaBar/preferences.json`。
> - 凭证、浏览器 Cookie、CLI 配置仍然只读取原始来源，不复制、不缓存敏感内容。
> - Quota Bar 只保存“来源索引 / 上次成功来源元信息”，用于下一次优先尝试；失败后回到完整规则重新抓取，并更新索引。
> - 额度、订阅状态、过期时间允许保存 last-known-good 快照到 `~/Library/Application Support/QuotaBar/`，仅用于启动、更新、重装或刷新中的兜底展示；一旦刷新拿到新值，UI 立即以内存新值为准并覆盖快照。
> - 刷新后某些服务不可用时，必须如实显示不可用 / 待配置 / 已过期 / 失败状态，不能把旧快照包装成 `.available`。

### ARCH-A：持久化模型与目录约束

- [x] [0.9.0-ARCH-A-000] 定义 Quota Bar 自有持久化目录：`~/Library/Application Support/QuotaBar/`；偏好、来源索引、last-known-good 快照都放在该目录下，不新增 `~/.quota-bar` 作为主路径 #P1
- [x] [0.9.0-ARCH-A-001] 设计持久化 schema version 与向后兼容策略；所有持久化文件必须带 `schemaVersion`，读取失败时安全丢弃并回到实时抓取，不阻塞 app 启动 #P1
- [x] [0.9.0-ARCH-A-002] 明确安全边界：持久化文件不得保存 token、cookie、API key、refresh token 或浏览器 Cookie 明文；敏感凭证仍只读取原始服务配置、浏览器 Cookie 或 macOS Keychain #P1

### ARCH-B：四层获取链路与 Provider 能力矩阵

- [x] [0.9.0-ARCH-B-000] 将获取体系拆为四层独立链路：Provider 获取、额度获取、过期日获取、档位/费用获取；四层分别维护来源索引、跳过规则、失败语义和 last-known-good 写入资格 #P1
- [ ] [0.9.0-ARCH-B-001] Provider 获取层支持 App Bundle、配置/凭证文件、CLI 命令、API Key/环境变量、浏览器登录痕迹等发现手段；刷新时先用上次成功手段复查已知 provider，成功则跳过其余发现手段，再跑完整发现链查找新增或丢失的 provider #P1
- [ ] [0.9.0-ARCH-B-002] 额度获取层支持配置文件读 token/API key 后调用 usage API、CLI 指令、HTTP API 指令、本地 RPC、浏览器 dashboard、手动 token/header、App 内 WebView 登录 session、最后可选自然语言问询；刷新时先用上次成功额度手段，失败后再按能力矩阵全量 fallback #P1
- [ ] [0.9.0-ARCH-B-003] 过期日获取层复用额度层的来源索引机制，但允许使用不同 endpoint、CLI 指令、DOM 抽取或账号页 API；过期日结果不得阻塞额度刷新，且必须标记来源可靠性 #P1
- [x] [0.9.0-ARCH-B-004] 为每个 Provider 定义四张能力矩阵，分别记录 Provider 获取、额度获取、过期日获取、档位/费用获取的可用节点、优先级、跳过条件、权限风险、交互成本、失败后 fallback 规则和是否允许写入快照 #P1
- [x] [0.9.0-ARCH-B-005] Provider 能力矩阵必须覆盖明确接入范围：Codex、Claude、Kimi、MiniMax、Antigravity、GLM/Z Code；不再登记“其他 provider”占位，新增 provider 必须先明确具体名称、安装/凭证/额度/过期日来源后再进入矩阵 #P1
- [ ] [0.9.0-ARCH-B-006] CLI/RPC 节点必须显式登记每个 provider 的命令、交互输入、输出格式和 parser；已验证命令与未验证猜测必须分开记录，未知命令不得执行 #P1
- [ ] [0.9.0-ARCH-B-007] Browser 节点必须显式登记每个 provider 的登录域名、cookie 名称、dashboard URL、HTTP 方法、必要 header、follow-up 请求、parser 和是否可能触发 Keychain/Full Disk Access；默认不扫描所有浏览器，优先使用来源索引或用户选择的浏览器/profile #P1
- [ ] [0.9.0-ARCH-B-008] 订阅状态归一化必须区分「可用」「已过期」「未订阅」「待配置」「抓取失败」「未安装」；只有可靠过期日距离当前时间在一个自然周内时显示已过期，超过一周或从未订阅显示未订阅 #P1

### DATA-A：来源索引缓存

- [x] [0.9.0-DATA-A-000] 新增 provider 来源索引缓存，记录每个 Provider 上次成功的数据来源优先值（如 auth file / browser profile / CLI config / local RPC / Keychain 探测），用于下一次启动、更新、重装或刷新时优先尝试 #P1
- [x] [0.9.0-DATA-A-001] 来源索引只保存非敏感元信息：providerKind、sourceKind、sourceId、成功时间、失败次数、最后错误摘要、相关本地路径或浏览器 profile 标识；不保存凭证内容 #P1
- [x] [0.9.0-DATA-A-002] 当优先来源失败时，Provider pipeline 必须回到完整 fallback 规则继续抓取；若其他来源成功，更新来源索引；若全部失败，如实返回失败 / 待配置状态 #P1
- [x] [0.9.0-DATA-A-003] 浏览器 Cookie 和 CLI 配置与凭证使用同一来源索引机制：保存“上次哪个浏览器 / profile / CLI 配置路径有效”，不复制 Cookie 或配置文件内容 #P1
- [x] [0.9.0-DATA-A-004] 来源索引优先级必须尊重层覆盖范围：在一次刷新同时需要额度/档位/过期日时，完整来源优先于只覆盖单层的来源；例如 Kimi Desktop 不应被 Kimi CLI 的 Code-only 成功缓存遮蔽，Z Code auth 不应被 plan-cache 遮蔽 #P1
- [ ] [0.9.0-DATA-A-005] App 内 WebView 授权容器：用户显式点击登录/修复后打开 provider 专属 WebView，复用 WKWebsiteDataStore 持久 session；后续刷新可隐式读取该 WebView session 发 dashboard 请求，避免反复触发系统 Cookie/Keychain 弹窗 #P1
- [ ] [0.9.0-DATA-A-006] 下拉里支持 WebView 授权的 provider 在未获取到数据 / 待配置时，按 provider 链路顺序显示最后优先级的可点击文本「打开 WebView 授权」或「备用：打开 WebView 授权」；点击后打开 provider 专属登录页并持久化 WebView session，后续 Web dashboard strategy 可复用该 session #P1

### DATA-B：额度与订阅快照

- [x] [0.9.0-DATA-B-000] 新增 last-known-good 快照文件，保存每个 provider 最近一次真实刷新成功的额度、订阅状态、订阅过期时间、价格、档位、fetchedAt、sourceKind 与是否 stale 等信息 #P1
- [x] [0.9.0-DATA-B-001] App 启动、更新、重装后，在首次实时刷新完成前可用 last-known-good 快照填充 UI，避免已知数值短暂消失；展示时必须标记为上次可用数据 / stale，而不是实时成功 #P1
- [x] [0.9.0-DATA-B-002] 手动或自动刷新期间，如果 provider 尚未返回新值，可继续展示旧快照作为过渡；一旦该 provider 返回成功结果，立即用内存新值替换显示并覆盖快照 #P1
- [x] [0.9.0-DATA-B-003] 如果刷新后 provider 明确不可用、待配置、已过期或抓取失败，UI 必须切到对应真实状态；旧快照只能作为“上次成功值”辅助信息，不得让服务继续显示为可用 #P1
- [x] [0.9.0-DATA-B-004] 快照写入只发生在真实刷新成功或明确订阅过期状态确认后；占位 loading、未安装、纯抓取失败不得覆盖 last-known-good 快照 #P1
- [x] [0.9.0-DATA-B-005] 为快照读写补测试：schema 兼容、坏文件丢弃、成功刷新覆盖、失败刷新不覆盖、stale 标记与 UI 状态分离 #P1

### UI-A：缓存兜底的显示语义

- [x] [0.9.0-UI-A-000] 使用 last-known-good 快照渲染时，菜单栏和 dropdown 必须有明确 stale/上次更新语义，避免用户把缓存值误认为刚刚刷新成功 #P1
- [x] [0.9.0-UI-A-001] 刷新失败但存在旧快照时，服务区块优先表达当前失败原因，同时可展示上次成功额度作为参考；状态灯、可用订阅计数和菜单栏 bar 不得按旧快照算“可用” #P1
- [x] [0.9.0-UI-A-002] 移除主路径中的样例数据 provider；抓取失败、没有抓取到任何对象、无权限、未登录、无订阅、已过期等状态后续由标准状态 UI 承接，不再用 Codex/MiniMax/Kimi 假数据兜底 #P1
