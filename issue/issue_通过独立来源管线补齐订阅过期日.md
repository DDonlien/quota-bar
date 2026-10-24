# 通过独立来源管线补齐订阅过期日

- ID：`0.6.0-ARCH-B-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / sub/expiry: 建立订阅过期日独立 source 管线。
- 原稳定 ID：`0.6.0-ARCH-B-000`, `0.6.0-ARCH-B-001`, `0.6.0-ARCH-B-002`, `0.6.0-ARCH-B-003-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户补充：过期日和额度信息不冲突；本地安装但无付费订阅时仍可能有免费额度，应如实展示额度，同时过期日找不到就隐藏。订阅过期日不应只是额度 pipeline 的附属逻辑，而应有独立 source 层级和可追踪来源。

- [x] [0.6.0-ARCH-B-000] 抽象 `SubscriptionExpirySource` / resolver：按 provider 定义过期日 source 顺序、来源类型（API / app cache / CLI / browser API / headless DOM）、confidence 与目标 URL #P1
- [x] [0.6.0-ARCH-B-001] `RefreshCoordinator` 使用独立过期日 source resolver 补 `subscriptionExpiresAt`；即使额度 snapshot 来源是免费额度或本地安装路径，也不把“没有订阅过期日”视为额度失败 #P1
- [x] [0.6.0-ARCH-B-002] headless DOM source 使用用户确认的订阅页入口：Claude `https://claude.ai/new#settings/billing`、Codex `https://chatgpt.com/#settings/Billing`、MiniMax `https://platform.minimaxi.com/console/plan`、Kimi `https://www.kimi.com/membership/subscription?tab=quota`；GLM 暂无订阅，不接入过期日 source #P1
- [x] [0.6.0-ARCH-B-003-test] 单元测试覆盖 source registry 顺序、Kimi API 优先不走 headless、免费额度 snapshot 无过期日时仍保持 `.available` #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260630130317-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630130317-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 可以的，按你说的实现，然后我帮你补上浏览器信息：
> 为你补充第三层的信息：
> - claude：https://claude.ai/new#settings/billing
> - codex：https://chatgpt.com/#settings/Billing
> - minimax：https://platform.minimaxi.com/console/plan
> - kimi：https://www.kimi.com/membership/subscription?tab=quota
> - glm：还没订阅，不确定
>
> 另外，过期日和额度信息不冲突。因为有些服务在我本地可以安装，安装完以后即使我没有任何订阅，也有可能会有一些免费的额度，就如实显示就好。

#### 完成工作

- [x] 订阅过期日 source pipeline 抽象落地。
- [x] 过期日和额度状态解耦。
- [x] 用户提供的浏览器订阅页 URL 已接入。
- [x] Kimi API 优先 + headless membership 页兜底。
- [x] 测试文件已更新 / 新增。

#### 更新的需求 ID

- [0.6.0-ARCH-B-000]
- [0.6.0-ARCH-B-001]
- [0.6.0-ARCH-B-002]
- [0.6.0-ARCH-B-003-test]

#### 验证方式

- `git diff --check`：通过。
- `swift test`：
  - 第一次在沙箱内失败，原因是 SwiftPM / Clang 需要写 `~/.cache/clang/ModuleCache`。
  - 授权重跑后进入编译，发现新测试里 `refreshDescription: nil` 类型错误和 `.available` 推断问题；已修复。
  - 再次授权重跑被审批层拒绝（提示 usage limit / 需稍后再试），因此本轮未能完成完整测试验证。
  - 2026-06-30 23:37 继续重跑：`swift test` 通过，63 tests in 11 suites passed。

#### 备注

- 当前代码静态检查干净，完整 `swift test` 已于后续重跑通过。
- GLM 因用户未订阅且入口不确定，未接入过期日 source。

### 20260701-205947-utcp8-taobe-gpt-5.md — 历史证据迁移

来源：`agent-log/20260701-205947-utcp8-taobe-gpt-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 把sub/expiry也纳入检查，两个一起往main合并，他们可能有一些重叠功能
>
> 3. codex不是特例，所有ai可能都有这个问题，但merge时不处理，并入后在main的requirements里记录相关调整需求
> 其他都ok，合并

#### 完成工作

- 将 `sub/expiry` 的订阅过期日 source 管线移植到当前 `main` 的 `macos/` 目录结构：
  - 新增 Codex / Claude / Cursor / MiniMax / Antigravity / Kimi harvester。
  - 新增 `SubscriptionExpirySource`、`SubscriptionExpiryResolver` 和 `QuotaBarDiagnostics`。
  - `RefreshCoordinator` 在额度 snapshot 成功后独立补充 `subscriptionExpiresAt`，日期失败不影响额度展示。
  - Kimi API 返回的 `subscriptionBalance.expireTime` 作为原始续费日，按下一次续费日减一天转换为最后有效日。
- 将 `sub/main` 的 Codex 订阅过期识别移植到当前 `main`：
  - 新增 `SubscriptionInspector.swift`。
  - `CodexAuthProvider` 和 `BrowserCookieProvider` Codex 路径在请求前检查本地 auth token 订阅状态。
  - `CodexDashboardParser` 对 `plan_type == free` 返回 nil，避免 free 月额度误显示为付费额度。
  - UI、状态栏和 fetch strategy 支持 `.subscriptionExpired`。
- 按用户要求，不把 Codex 作为长期特例扩展处理；已在 `REQUIREMENTS.md` 的 v0.10 记录所有 AI provider 统一订阅过期识别的后续调整需求。
- 复制 `sub/main` 和 `sub/expiry` 的相关执行日志与 branch marker 到根 `agent-log/`。
- 未恢复旧 `quota-bar/` / `web/` 目录，未并入旧构建产物。

#### 更新的需求 ID

- 已完成 / 合并：
  - `[0.6.0-DATA-A-001]`
  - `[0.6.0-DATA-A-002]`
  - `[0.6.0-DATA-A-002-test]`
  - `[0.6.0-DATA-B-000]`
  - `[0.6.0-DATA-B-001]`
  - `[0.6.0-DATA-B-001-test]`
  - `[0.6.0-DATA-C-000]`
  - `[0.6.0-DATA-C-001]`
  - `[0.6.0-DATA-C-001-test]`
  - `[0.6.0-DATA-D-000]`
  - `[0.6.0-DATA-D-001]`
  - `[0.6.0-DATA-D-001-test]`
  - `[0.6.0-DATA-E-000]`
  - `[0.6.0-DATA-E-001]`
  - `[0.6.0-DATA-E-001-test]`
  - `[0.6.0-DATA-F-000]`
  - `[0.6.0-DATA-F-001]`
  - `[0.6.0-DATA-F-001-test]`
  - `[0.6.0-ARCH-B-000]`
  - `[0.6.0-ARCH-B-001]`
  - `[0.6.0-ARCH-B-002]`
  - `[0.6.0-ARCH-B-003-test]`
  - `[0.10.0-ARCH-A-000]` 至 `[0.10.0-QA-A-000]`
- 新增未完成：
  - `[0.9.0-ARCH-A-000]` 至 `[0.9.0-DATA-B-004]`
  - `[0.10.0-DATA-B-000]` 至 `[0.10.0-QA-B-000]`

#### 验证方式

- `cd macos && swift build`：通过。
- `cd macos && swift test`：通过，83 tests in 15 suites。
- `git diff --check`：通过。

#### 备注

- 本次只修改 `main` 工作区，不修改 `sub/main` 或 `sub/expiry`。
- 不恢复旧 `quota-bar/` / `web/` 目录，不并入旧构建产物。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
