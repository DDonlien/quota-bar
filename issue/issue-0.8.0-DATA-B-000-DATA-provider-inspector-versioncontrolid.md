# DATA-B：其他 provider 沿用 Inspector 模式（v0.8.0 不落地，只登记）

- ID：`0.8.0-DATA-B-000`。
- 类型：`DATA`。
- 状态：待定 / 延后（沿用原需求记录）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型） / DATA-B：其他 provider 沿用 Inspector 模式（v0.8.0 不落地，只登记）。
- 原稳定 ID：`0.8.0-DATA-B-000`, `0.8.0-DATA-B-001`, `0.8.0-DATA-B-002`, `0.8.0-DATA-B-003`, `0.8.0-DATA-B-004`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 每个 provider 的订阅状态来源不同，工作量是 Codex 的 3-5x。先登记，等 Codex 这条线稳定后再排期。

- [ ] [0.8.0-DATA-B-000] Claude 订阅到期日：claude.ai 的 session cookie 里解析 `membership_type` / `subscription_end_date` 字段；或抓 `claude.ai/settings/plan` DOM 提取"Next billing" #deferred — 等 v0.6.0-DATA-C（Claude 真实订阅到期日 headless 抓取）落地后顺手做
- [ ] [0.8.0-DATA-B-001] Cursor 订阅到期日：Cursor 没有原生 token 元信息，需要抓 `cursor.com/dashboard` DOM 提取"Plan renews on..." #deferred
- [ ] [0.8.0-DATA-B-002] MiniMax 订阅到期日：MiniMax Web dashboard `coding_plan/remains` 不返回订阅到期日；需要抓 `minimaxi.com/user-center/payment/balance` DOM #deferred
- [ ] [0.8.0-DATA-B-003] Antigravity 订阅到期日：走本地 language_server probe 不容易拿到订阅元信息，可能要抓 antigravity.google/settings 页面 #deferred
- [ ] [0.8.0-DATA-B-004] Kimi 订阅到期日：已通过 `KimiSubscriptionStatParser.parseSubscriptionExpiresAt` 从 `subscriptionBalance.expireTime` 提取（v0.6.0 已落地）；但**没有过期判定**——只填 `subscriptionExpiresAt`，UI 仅在 `.available` 时显示日期，过期后会显示一个"很久以前"的到期日但不报红 #cut — 实际 Kimi 不会让订阅过期数据继续返回，过期后会跌到 free 不返 quota，行为自然

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
