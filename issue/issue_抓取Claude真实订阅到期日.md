# 抓取Claude真实订阅到期日

- ID：`0.6.0-DATA-C-000`。
- 类型：`DATA`。
- 状态：待处理（原文未完成项保持未勾选）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `38afced2fbd2a58209bf2abb51ca57fb81aa7946`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 接入 Claude 真实订阅到期日。
- 原稳定 ID：`0.6.0-DATA-C-000`, `0.6.0-DATA-C-001`, `0.6.0-DATA-C-001-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> Claude (claude.ai) 的 `/api/organizations/{uuid}/usage` 不返回订阅到期日。需要 headless 抓 `claude.ai/settings/plan` 或 `claude.ai/account/billing`，提取「Next billing」「Renews on」之类。

- [ ] [0.6.0-DATA-C-000] `ClaudeHarvester` 实现：加载 `https://claude.ai/settings/plan`，DOM 提取续费日期 #P1
- [ ] [0.6.0-DATA-C-001] 集成到 `BrowserCookieProvider` Claude 路径 #P1
- [ ] [0.6.0-DATA-C-001-test] 单元测试：mock HTML 验证解析 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
