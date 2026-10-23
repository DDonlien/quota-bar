# UI-A：过期状态 UI 表现

- ID：`0.8.0-UI-A-000`。
- 类型：`UI`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `2932f1485264a24846b13695f1406ae5ca837cd9`；标题路径：任务清单 / Phase - v0.8.0 - 订阅过期识别（"权威 > API 反推"模型） / UI-A：过期状态 UI 表现。
- 原稳定 ID：`0.8.0-UI-A-000`, `0.8.0-UI-A-001`, `0.8.0-UI-A-002`, `0.8.0-UI-A-003`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.8.0-UI-A-000] `MenuView.PlanSection` 处理 `.subscriptionExpired(plan, expiredAt)`：不渲染任何 quota window（避免被 free 月度窗口误导），只展示一行灰标 hint `订阅已过期 · Plus · 到期 2026/6/25`（无 plan 时省略，无到期日时省略）#P1
- [x] [0.8.0-UI-A-001] `StatusBarController.drawableSnapshots` 把 `.subscriptionExpired` 当 drawable（区别于 `.notInstalled` / `.fetchFailed`），让菜单栏仍画 bar（0% 高度 + 最小占位 bar）以表达"我知道这个订阅存在但已过期" #P1
- [x] [0.8.0-UI-A-002] `StatusBarController.remainingFraction` 对 `.subscriptionExpired` 返回 0（与其他"用完"视觉一致，区别于 `.loading` / `.needsConfiguration` 的 50%）#P1
- [x] [0.8.0-UI-A-003] `StatusBarController.refreshStatusItemAppearance` tooltip 对 `.subscriptionExpired` 显示 `"Codex 已过期"`，区别于正常 `Codex 5%` / `Codex 刷新中` #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
