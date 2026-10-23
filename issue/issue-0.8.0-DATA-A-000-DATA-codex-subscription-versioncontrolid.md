# DATA-A：Codex 订阅过期识别

- ID：`0.8.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型） / DATA-A：Codex 订阅过期识别。
- 原稳定 ID：`0.8.0-DATA-A-000`, `0.8.0-DATA-A-001`, `0.8.0-DATA-A-002`, `0.8.0-DATA-A-003`, `0.8.0-DATA-A-004`, `0.8.0-DATA-A-005`, `0.8.0-DATA-A-006`, `0.8.0-DATA-A-007`, `0.8.0-DATA-A-001-test`, `0.8.0-DATA-A-000-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

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

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
