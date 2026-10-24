# 统一Provider订阅状态识别与免费额度边界

- ID：`0.10.0-DATA-B-000`。
- 类型：`DATA`。
- 状态：进行中（原文同时包含已完成与未完成项）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 所有 AI Provider 统一订阅过期识别。
- 原稳定 ID：`0.10.0-DATA-B-000`, `0.10.0-DATA-B-001`, `0.10.0-DATA-B-002`, `0.10.0-DATA-B-003`, `0.10.0-DATA-B-004`, `0.10.0-DATA-B-005`, `0.10.0-DATA-B-006`, `0.10.0-QA-B-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [ ] [0.10.0-DATA-B-000] 梳理所有已接入 provider 的权威订阅状态来源优先级：本地 auth / app cache / CLI / browser API / headless DOM；不要只依赖 quota 数值反推订阅是否有效 #P1
- [ ] [0.10.0-DATA-B-001] 为 Claude、Cursor、Kimi、MiniMax、Antigravity、GLM 等 provider 设计与 `CodexSubscriptionInspector` 等价的 inspector 或 source 规则；明确 free / expired / unknown / active 的判定边界 #P1
- [ ] [0.10.0-DATA-B-002] 统一处理“免费额度仍可用但付费订阅已过期”的 UI 语义：区分免费额度展示、付费订阅过期提示、以及真正的抓取失败 #P1
- [ ] [0.10.0-DATA-B-003] 为所有 provider 增加防御性 parser：当 dashboard 明确返回 free / expired / unpaid / trial-ended 等状态时，不把免费或降级额度误标成付费订阅额度 #P1
- [x] [0.10.0-DATA-B-004] MiniMax `coding_plan/remains` / `mmx quota` 返回 `no active token plan subscription`（HTTP 200 + 非 0 status_code）时映射为 `notSubscribed`（订阅已到期/未订阅），不再显示「待配置」或抓取失败 #P1 — `MiniMaxCLIProvider.indicatesNoActiveSubscription`
- [x] [0.10.0-DATA-B-005] Claude 订阅过期识别：usage 响应能解析出窗口、但所有窗口 `resets_at` 全为 null/缺失时（订阅过期/免费降级的服务端权威信号，本机真实样本 2026-08-08 验证：过期账号 five_hour/seven_day 只剩 utilization，dropdown 因此一直显示「重置时间未知」）三个额度路径统一返回 `.notSubscribed` marker snapshot，串行管线直接短路，dropdown 显示「未订阅或订阅已过期」，不再把无重置时间的窗口当有效额度展示 #P1 — `ClaudeUsageWindowParser.indicatesNoActivePlan`（webview `ClaudeDashboardParser` + OAuth `ClaudeOAuthUsageProvider`）；statusLine 缓存路径只认**显式 null**（键缺失是历史容忍形态，不推断），`ClaudeStatusLineUsageProvider.indicatesNoActivePlan`；测试 37 条全过（parser 四分支 + OAuth/statusLine marker + 键缺失不误判）
- [x] [0.10.0-DATA-B-006] 其余 provider 同类问题审计 + 系统性修复：① `FetchPipeline.mergeLayers` 此前静默丢弃后续来源返回的 `.notSubscribed`/`.subscriptionExpired` marker（先成功的 tier-only「已配置」来源会占住基底，marker 被 `guard addition.availability == .available` 吞掉，UI 退回 tier-only「授权获取额度」而不是「未订阅或订阅已过期」）——改为 marker 优先：采用 marker 的 availability、丢弃 base 可能误导的额度窗口、保留 base 已知档位/价格/到期日供 header 展示；② opencode：`OpenCodeWorkspaceProvider` Go 推广页从 throw `notSubscribed` 改为返回 marker snapshot（抛错会被基底吞掉，marker 才能经 mergeLayers 生效）；③ Kimi：`KimiSubscriptionParser.indicatesNoActivePlan`——响应顶层显式 `subscribed: false`（真实响应样本确认该字段存在）→ 无有效订阅；`subscribed` 缺失时退而求其次，`nextBillingTime` 已过 → 订阅周期结束未续费；`KimiDesktopTokenProvider` 与 `BrowserCookieProvider` Kimi 路径返回 marker。审计结论：Codex（id_token inspector）/ MiniMax（`indicatesNoActiveSubscription`）已覆盖；Cursor 无额度管线、Z Code/GLM/Trae 无订阅概念，不适用；Antigravity 无真实过期响应样本（`planStatus` 字段含义待验证），维持现状并登记后续 #P1
- [ ] [0.10.0-QA-B-000] 为统一订阅过期识别补测试矩阵：active、expired、free、unknown、免费额度存在、dashboard 字段缺失、字段 schema 变化 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
