# DATA-A：Kimi 真实订阅到期日（已有数据，5 行代码）

- ID：`0.6.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `b550269a253e390d19ec221949fb30c44adf9e9e`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / DATA-A：Kimi 真实订阅到期日（已有数据，5 行代码）。
- 原稳定 ID：`0.6.0-DATA-A-000`, `0.6.0-DATA-A-001`, `0.6.0-DATA-A-002`, `0.6.0-DATA-A-002-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> Kimi 的 `GetSubscriptionStat` 响应里 `subscriptionBalance.expireTime` **就是真实的订阅到期日**，但当前代码把它错塞到 Work quota 窗口的 `resetsAt`。这是最快、最稳的 1 个 provider，先打通。

- [x] [0.6.0-DATA-A-000] `KimiSubscriptionStatParser` 解析 `subscriptionBalance.expireTime` 后**不再塞给 Work quota 的 `resetsAt`**（Work 的 resetsAt 应该是月度窗口的滚动结束时间，跟 subscription 到期日是不同概念）#P1
- [x] [0.6.0-DATA-A-001] `KimiSubscriptionStatParser.parseSubscriptionExpiresAt(data:)` 返回 `subscriptionBalance.expireTime`；`BrowserCookieProvider` 调 `parseSubscriptionExpiresAt` 拿到值后传给 `ProviderSnapshot.subscriptionExpiresAt` #P1
- [x] [0.6.0-DATA-A-002] Work quota 窗口的 `resetsAt` 改为从 `subscriptionBalance.expireTime` 反推或保留为 nil（让 UI 不显示月度 quota 的"重置时间"——已经隐含在 subscriptionExpiresAt 里，避免双信息）；如需要月度窗口重置，则计算 `now + periodSeconds` 兜底 #P1
- [x] [0.6.0-DATA-A-002-test] 单元测试：mock `GetSubscriptionStat` JSON 验证 `subscriptionExpiresAt == expireTime`，Work quota `resetsAt` 不再等于 expireTime #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
