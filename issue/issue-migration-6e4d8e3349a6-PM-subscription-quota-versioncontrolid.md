# Phase - v0.10.0 - 订阅过期识别与免费额度误判修正

- ID：`migration-6e4d8e3349a6`。
- 类型：`PM`。
- 状态：已确认约束 / 状态待核对（原文未单列完成状态）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正。

## 当前需求与范围

> `sub/main` 原本使用 v0.8.0 记录 Codex 订阅过期识别；当前 `main` 已经用 v0.8.0 记录仓库结构迁移，因此合并到 main 时改登记为 v0.10.0，避免稳定 ID 冲突。
>
> **触发 bug**：用户实测发现 `~/.codex/auth.json` 的 id_token 里 `chatgpt_subscription_active_until = 2026-06-25`，但 Codex.app 在订阅过期后调 `wham/usage` 仍能拿到 200 OK，响应里的 `plan_type` 跌成 `"free"`，`rate_limit.primary_window.limit_window_seconds` 跳到 30 天，被旧 parser 错误显示成“月额度”。这说明“用 quota 数值反推订阅状态”不可靠。
>
> **本次 merge 边界**：先并入 Codex 已落地实现，修复已知 bug；所有 AI provider 的统一订阅过期识别作为后续需求登记，不在本次 merge 中扩展实现。

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。
