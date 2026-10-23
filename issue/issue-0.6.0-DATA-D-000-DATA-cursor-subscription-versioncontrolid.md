# feat/subscription-expiry: 接入 Cursor 真实订阅到期日

- ID：`0.6.0-DATA-D-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 接入 Cursor 真实订阅到期日。
- 原稳定 ID：`0.6.0-DATA-D-000`, `0.6.0-DATA-D-001`, `0.6.0-DATA-D-001-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> Cursor (cursor.com) 的 dashboard 走 `cursor.com/api/...`，但续费日通常在 `cursor.com/dashboard` 顶部"Plan"卡片里。需要 headless 抓页面。

- [x] [0.6.0-DATA-D-000] `CursorHarvester` 实现：加载 `https://cursor.com/dashboard`，提取"Pro plan renews on..."或类似 #P1
- [x] [0.6.0-DATA-D-001] 通过独立 source 管线集成到 Cursor snapshot enrichment #P1
- [x] [0.6.0-DATA-D-001-test] 单元测试：mock HTML 验证解析 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
