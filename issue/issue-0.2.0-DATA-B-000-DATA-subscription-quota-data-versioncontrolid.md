# sub/main: 获取真实订阅与额度数据

- ID：`0.2.0-DATA-B-000`。
- 类型：`DATA`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.2.0 - Quota Bar 核心功能 / sub/main: 获取真实订阅与额度数据。
- 原稳定 ID：`0.2.0-DATA-B-000`, `0.2.0-DATA-B-001`, `0.2.0-DATA-B-002`, `0.2.0-DATA-B-003`, `0.2.0-DATA-B-004`, `0.2.0-DATA-B-005`, `0.2.0-DATA-B-009`, `0.2.0-DATA-B-010`, `0.2.0-DATA-B-011`, `0.2.0-DATA-B-012`, `0.2.0-DATA-B-013`, `0.2.0-DATA-B-006`, `0.2.0-DATA-B-007`, `0.2.0-DATA-B-008`, `0.2.0-DATA-B-014`, `0.2.0-DATA-B-015`, `0.2.0-DATA-B-016`, `0.2.0-DATA-B-017`, `0.2.0-DATA-B-018`, `0.2.0-DATA-B-019`, `0.2.0-DATA-B-020`, `0.2.0-DATA-B-021`, `0.2.0-DATA-B-028`；不改写或重编号这些既有 ID。

## 当前需求与范围

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

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260620202608-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260620202608-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 根据更新的requirements约束条件[@AGENTS.md (80:108)](file:///Users/taobe/Projects/GitHub/Personal/quota-bar/AGENTS.md#L80:108) 更新文件[@REQUIREMENTS.md](file:///Users/taobe/Projects/GitHub/Personal/quota-bar/REQUIREMENTS.md)

#### 完成工作

- 已更新 `REQUIREMENTS.md`，使其符合 `AGENTS.md` 中新版 requirements 命名约束。
- 保留原有需求语义、完成状态、延后/取消标记与备注；仅调整结构、区块类型和 ID 形态。

#### 更新的需求 ID

- 本次为需求文档规范化，不新增产品需求。
- 原有旧 ID 已按新版格式迁移到版本化 ID。

#### 验证方式

- `python3` 自定义格式检查：通过，确认 `REQUIREMENTS.md` 的一级标题、二级 Phase 标题、三级任务区块和 task ID 均符合新版规则。
- `git --no-pager diff -- REQUIREMENTS.md`：已查看，确认改动集中在需求文档结构与 ID 规范化。

#### 备注

- 未运行 `swift build`，本次仅修改 Markdown 需求文档，不涉及 Swift 代码或构建流程。
