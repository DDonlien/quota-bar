# sub/main: Codex 日期改为当前订阅周期续费日

- ID：`0.11.2-BUG-A-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.11.2 - 菜单栏次级额度可辨识度 + Codex 当前续费日 / sub/main: Codex 日期改为当前订阅周期续费日。
- 原稳定 ID：`0.11.2-BUG-A-000`, `0.11.2-UI-A-001`, `0.11.2-QA-A-001`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户当前 Codex Pro 额度实时可用，但 header 仍显示 `2026/7/29`。运行日志确认 `CodexAuthProvider` 把已经过去的 JWT `chatgpt_subscription_active_until` 填入 snapshot，`SubscriptionExpiryResolver` 因 snapshot 已有日期而直接短路，导致 `accounts/check` 永远不执行。这是旧订阅周期日期被复用，不是时区或格式问题。

- [x] [0.11.2-BUG-A-000] Codex usage 成功时只允许尚未过去的 JWT 订阅日期进入 snapshot；过期 JWT 视为陈旧元数据并继续执行 `accounts/check`，成功则展示当前付费周期的下一次续费边界，失败则隐藏日期/保留授权补救入口，不按月推算、不复用历史日期 #P0
- [x] [0.11.2-UI-A-001] Codex 当前付费周期日期的 hover 语义改为「下次续费时间」；其他仍只提供最后有效日的 provider 保持原有语义，避免把不同来源一概误标为扣费日 #P1
- [x] [0.11.2-QA-A-001] 覆盖「live Pro + past JWT + accounts/check 成功」「live Pro + past JWT + resolver 失败」「future JWT 仍可直接采用」三类回归；失败路径必须留空，不得制造未来日期 #P0

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
