# 通过独立来源管线补齐订阅过期日

- ID：`0.6.0-ARCH-B-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / ARCH-B：订阅过期日独立数据源管线。
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

来源：`agent-log/20260630130317-utcp8-gpt5.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
