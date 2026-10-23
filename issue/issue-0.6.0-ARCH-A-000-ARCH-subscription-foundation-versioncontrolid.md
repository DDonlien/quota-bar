# ARCH-A：订阅日期抓取基础架构

- ID：`0.6.0-ARCH-A-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / ARCH-A：订阅日期抓取基础架构。
- 原稳定 ID：`0.6.0-ARCH-A-000`, `0.6.0-ARCH-A-001`, `0.6.0-ARCH-A-002`, `0.6.0-ARCH-A-003`, `0.6.0-ARCH-A-003-test`, `0.6.0-ARCH-A-001-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 提供给各 provider 复用的 headless 抓取 + DOM 提取框架。Kimi 这种直接 API 返回 expireTime 的不走这个架构，但协议入口统一。

- [x] [0.6.0-ARCH-A-000] 设计 `SubscriptionDateHarvester` 协议：每个 provider 实现 `harvest(from data: Data) async throws -> Date?`，输入是抓到的页面 Data（或 WKWebView handle），输出是订阅到期日；找不到返回 nil #P1
- [x] [0.6.0-ARCH-A-001] `WKWebViewHeadlessLoader` 实现：注入 `WKHTTPCookieStore` cookie → 加载 URL → 等 `network idle` / 特定 DOM 节点出现 → 回调 `Data` 或 `String`；可在 `FetchPipeline` strategy 中复用，超时与现有 strategy 一致 #P1
- [x] [0.6.0-ARCH-A-002] 删 `ProviderSnapshot.init` 里 `quotas.compactMap(\.resetsAt).max()` fallback：找不到真实到期日时 `subscriptionExpiresAt = nil`（UI 自动不显示）；同时把 `subscriptionExpiresAt` 文档从"默认从 max(resetsAt) 推断"改成"nil = 不展示" #P1
- [x] [0.6.0-ARCH-A-003] `DashboardParser` 协议加 `parseSubscriptionExpiresAt(data: Date = Date()) -> Date?`，默认实现返回 nil；Kimi 的 `subscriptionBalance.expireTime` 不进入 Work quota reset，作为原始续费日使用时需按 source 语义转成最后有效日 #P1
- [x] [0.6.0-ARCH-A-003-test] 给 harvester 协议 + fallback 改 hide 写单元测试：mock HTML feed 解析，验证 `subscriptionExpiresAt` 正确 / 不正确两种路径 #P1
- [x] [0.6.0-ARCH-A-001-test] `WKWebViewHeadlessLoader` 集成测试：mock URLProtocol 喂 HTML，验证 cookie 注入 + DOM ready 等待 + 超时降级 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
