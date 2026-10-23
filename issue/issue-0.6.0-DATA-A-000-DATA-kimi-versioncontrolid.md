# DATA-A：Kimi 过期日误判修正

- ID：`0.6.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / DATA-A：Kimi 过期日误判修正。
- 原稳定 ID：`0.6.0-DATA-A-000`, `0.6.0-DATA-A-001`, `0.6.0-DATA-A-002`, `0.6.0-DATA-A-002-test`, `0.6.0-DATA-A-003`, `0.6.0-DATA-A-004`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 2026-07-01 实测修正：Kimi membership 页显示的是「下一次续费日」，而 UI 价格旁日期语义是「最后有效日」。`subscriptionBalance.expireTime` 不应进入 Work quota 的 `resetsAt`，但可作为 Cookie API 原始续费日；写入 `ProviderSnapshot.subscriptionExpiresAt` 前必须按本地自然日减 1 天。

- [x] [0.6.0-DATA-A-000] `KimiSubscriptionStatParser` 解析 `subscriptionBalance.expireTime` 后**不再塞给 Work quota 的 `resetsAt`**；该值只用于 Work 行倒计时文案 #P1
- [x] [0.6.0-DATA-A-001] `KimiSubscriptionStatParser.parseSubscriptionExpiresAt(data:)` 返回 `subscriptionBalance.expireTime` 原始续费日；`BrowserCookieProvider` 按 `.nextRenewalDate` 转成最后有效日后传给 `ProviderSnapshot.subscriptionExpiresAt` #P1
- [x] [0.6.0-DATA-A-002] Work quota 窗口的 `resetsAt` 保持 nil；`subscriptionBalance.expireTime` 仅用于 Work 行 refreshDescription，不进入价格旁订阅日 #P1
- [x] [0.6.0-DATA-A-002-test] 单元测试：mock `GetSubscriptionStat` JSON 验证 `parseSubscriptionExpiresAt == expireTime`，Work quota `resetsAt` 不等于 expireTime #P1
- [x] [0.6.0-DATA-A-003] Kimi Cookie API 路径优先设置 `ProviderSnapshot.subscriptionExpiresAt`；membership 页 headless source 仅作为后备 #P1
- [x] [0.6.0-DATA-A-004] Kimi membership 页显示的是「下一次续费日」，价格旁 UI 展示「最后有效日」时需要按本地自然日减 1 天 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260630235158-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630235158-utcp8-gpt5.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 结果是这样，相当于Kimi还是错的，然后其他的都没获取到，为什么？能看到报错吗？

截图显示：
- Codex / MiniMax / Antigravity 未显示订阅日期；
- Kimi 显示 `2026/7/10`，但 Work 月额度剩余 `9d8h`，高度怀疑该日期是额度周期截止而不是订阅续费日。

#### 完成工作

- [x] 修正 Kimi 过期日误判。
- [x] 订阅过期日 source 失败写入 `~/Library/Logs/QuotaBar.log`。
- [x] `swift test` 通过。
- [x] 重新打包。

#### 更新的需求 ID

- [0.6.0-DATA-A-001] 标记 `#cut`
- [0.6.0-DATA-A-002]
- [0.6.0-DATA-A-002-test]
- [0.6.0-DATA-A-003]

#### 验证方式

- `git diff --check`：通过。
- `swift test`：63 tests in 11 suites passed。
- `./scripts/build-app.sh`：Build complete。
- 最新包：`quota-bar/build/20260630-235147/QuotaBar.app`

#### 备注

- 截图中其他 provider 没有日期，当前系统日志显示 WebKit/WebContent 层有 sandbox / bootstrap lookup 报错；下一次运行新包后，应直接查看 `~/Library/Logs/QuotaBar.log` 来确认每个 source 是 cookie 缺失、加载失败、超时，还是 DOM extract nil。

### 20260701001745-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260701001745-utcp8-gpt5.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

codex和agy还是没有，minimax对的（到期日/最后有效日），kimi应该是逻辑错了：kimi网站显示的是下一次续费日，意味着最后有效期是n-1，现在显示的是n+1

#### 完成工作

- Kimi membership 页日期现在会从「下一次续费日」转换为「最后有效日」。
- MiniMax 保持不变，仍直接把页面到期日作为最后有效日。
- Codex / Antigravity 未能从现有日志确认真实 App 失败原因；已补充文件日志，下一次刷新会在 `~/Library/Logs/QuotaBar.log` 中留下 provider 和 source 粒度诊断。
- 重新打包：`quota-bar/build/20260701-001725/QuotaBar.app`，`quota-bar/build/latest/QuotaBar.app` 已指向最新包。

#### 更新的需求 ID

- `[0.6.0-DATA-A-004]`

#### 验证方式

- `swift test`：通过，64 tests in 11 suites passed。
- `git diff --check`：通过。
- `./scripts/build-app.sh`：通过，生成 `build/20260701-001725/QuotaBar.app`。

#### 备注

- Codex / Antigravity 仍需要用户运行新包并点击「立即刷新」后的真实 `QuotaBar.log` 来判断下一步原因。当前唯一可见日志是测试进程写入的 Codex `missingCredentials`，不足以代表 App 实际刷新。

### 20260701150930-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260701150930-utcp8-gpt5.md` @ `9ecb46e90cc74ea0e4dc899cc913e3a44e37b1c3`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

你的新版本直接刷新不出kimi的过期信息了？

#### 完成工作

- 修复 Kimi 新版本刷新不出过期信息的问题。
- Kimi 日期链路现在为：`GetSubscriptionStat.subscriptionBalance.expireTime` 原始续费日 → 本地自然日减 1 → UI 展示最后有效日。
- Work quota 仍不使用 `expireTime` 作为 `resetsAt`，避免额度 reset 和订阅日混淆。
- 重新打包：`quota-bar/build/20260701-150910/QuotaBar.app`，`quota-bar/build/latest/QuotaBar.app` 已指向最新包。

#### 更新的需求 ID

- `[0.6.0-ARCH-A-003]`
- `[0.6.0-DATA-A-001]`
- `[0.6.0-DATA-A-002-test]`
- `[0.6.0-DATA-A-003]`

#### 验证方式

- `swift test`：通过，64 tests in 11 suites passed。
- `git diff --check`：通过。
- `./scripts/build-app.sh`：通过，生成 `build/20260701-150910/QuotaBar.app`。

#### 备注

- Codex / Antigravity 日志仍显示 headless DOM 页面能加载但提取不到日期；本次只修复用户指出的 Kimi 新版回退问题。
