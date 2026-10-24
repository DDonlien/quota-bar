# 区分Kimi订阅续费日与额度窗口重置时间

- ID：`0.6.0-DATA-A-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 接入 Kimi 真实订阅到期日。
- 原稳定 ID：`0.6.0-DATA-A-000`, `0.6.0-DATA-A-001`, `0.6.0-DATA-A-002`, `0.6.0-DATA-A-002-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> Kimi 的 `GetSubscriptionStat` 响应里 `subscriptionBalance.expireTime` 可作为订阅续费日原始值，但页面语义是「下一次续费日」，UI 需要转换成「最后有效日」。历史上这个值曾被错塞到 Work quota 窗口的 `resetsAt`，需要保持额度周期和订阅日期两条语义分离。

- [x] [0.6.0-DATA-A-000] `KimiSubscriptionStatParser` 解析 `subscriptionBalance.expireTime` 后**不再塞给 Work quota 的 `resetsAt`**（Work 的 resetsAt 应该是月度窗口的滚动结束时间，跟 subscription 到期日是不同概念）#P1
- [x] [0.6.0-DATA-A-001] `KimiSubscriptionStatParser.parseSubscriptionExpiresAt(data:)` 返回 `subscriptionBalance.expireTime` 原始续费日；`BrowserCookieProvider` 按 `.nextRenewalDate` 转换成最后有效日后传给 `ProviderSnapshot.subscriptionExpiresAt` #P1
- [x] [0.6.0-DATA-A-002] Work quota 窗口的 `resetsAt` 保持 nil；`subscriptionBalance.expireTime` 仅用于 Work 行 refreshDescription，不进入额度窗口重置时间 #P1
- [x] [0.6.0-DATA-A-002-test] 单元测试：mock `GetSubscriptionStat` JSON 验证原始续费日可解析、Work quota `resetsAt` 不再等于 expireTime、最后有效日换算由 source 层负责 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260630235158-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260630235158-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 20260702223030-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702223030-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> kimi额度对了，订阅名称有了，日期不对，之前出现过这个错误，应该是7/8最后有效，你获取到的7/9是续费日期，然后你现在显示的是7/10
> minimax没有到期日，codex也没有，这俩之前（可能是在sub-expiry）是好的
> agy又没有额度了，zcode也还没有额度

#### 完成工作

- `KimiSubscriptionStatParser.parseSubscriptionExpiresAt` 改为返回 nil，避免把无法确认语义的 `expireTime/currentEndTime` 直接展示。
- `KimiSubscriptionParser.parseSubscriptionExpiresAt` 新增 `nextBillingTime` 解析与最后有效日转换。
- `KimiDesktopTokenProvider` 和 `BrowserCookieProvider` 使用 `GetSubscription` 返回的日期。
- 新增/更新测试覆盖：
  - stat parser 不再输出展示日期。
  - `nextBillingTime = 2026-07-09...` 会显示为 `2026/7/8`。
  - Desktop provider 订阅日期来自 `GetSubscription.nextBillingTime`。
- 打包新版本：`quota-bar/build/20260702-223006/QuotaBar.app`，快捷入口 `quota-bar/build/latest/QuotaBar.app`。

#### 更新的需求 ID

- `0.6.0-ARCH-A-003`
- `0.6.0-DATA-A-001`
- `0.6.0-DATA-A-002-test`
- `0.6.0-DATA-B-002`
- `0.6.0-UI-A-002`

#### 验证方式

- `cd quota-bar && env CLANG_MODULE_CACHE_PATH=.build/clang-module-cache SWIFT_MODULE_CACHE_PATH=.build/swift-module-cache swift test --disable-sandbox`
  - 结果：通过，63 个 Swift Testing 测试通过。
- `cd quota-bar && ./scripts/build-app.sh`
  - 结果：通过，生成 `/Users/taobe/Projects/GitHub/Personal/quota-bar/worktree/sub-main/quota-bar/build/20260702-223006/QuotaBar.app`。

#### 备注

- Codex/MiniMax 当前无到期日不是本次代码修复范围内可直接恢复的问题：`sub/expiry` 没有可合并的真实实现，当前应继续隐藏，避免展示 stale 或伪造日期。
- Antigravity 当前只看到 `agy` 进程，未看到 `language_server`，因此现有本地 RPC 路径会如实显示不可用。
- Z Code 服务端仍可能返回 plan available 但无可渲染 quota，当前逻辑应如实展示“没有额度数值”，不得从 plan-cache 伪造。

### 20260619160000-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260619160000-utcp8-mavis.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 原始 prompt（用户给 kimi CLI 的）

1. 把本地 worktree 里的菜单栏图标 bar 功能改动合并到 main
2. 检查并清空所有 worktree
3. 列出当前的 requirements

> 下一步最重要的工作是确保真的能获取到本地的订阅。现在只有 Codex 能正确获取到。我的电脑上至少有 Trae Work、Kimi、MiniMax 和 Google 的 Antigravity。其中除了 Trae Work 以外，所有的都有 CLI，Quota Bar 应该尝试从 app 和 cli 获取订阅，确保即使只安装其中一个也能正确识别到订阅信息；并且能识别两个工具用的是否是一个订阅权限/用户，确保如果用的是两个权限，能正确地拆分成两个权限的信息；如果两个用的是同一个权限，能正确合并成一个权限的信息。

#### 本机实际探测结果（先验证再设计）

- `~/.kimi-code/credentials/kimi-code.json` 里有 OAuth access_token（JWT，scope=kimi-code），但 `POST /apiv2/.../GetUsages` 401 `REASON_INVALID_AUTH_TOKEN` —— CLI token 不能直接调 web endpoint
- `~/.mavis/config.yaml` 里的 `apiKey: sk-xxx` 是脱敏过的（用户隐藏真 key），不是真 key
- MiniMax web endpoint `api.minimax.chat/v1/api/openplatform/coding_plan/remains` 在浏览器签名检查下被 Cloudflare 1010 拦截；带 cookie 走能命中但要 web cookie
- **结论**：CLI OAuth token 路径在本机不可直接用于拿 dashboard 数据，Kimi/MiniMax 真实可行的数据源只有浏览器 Cookie（用户在浏览器登录 kimi.com / minimax.chat）

#### 运行验证日志（FileHandle 输出后已删）

```
QB: codex ok av=available q=2 tier=Plus
QB: kimi ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: minimax ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: trae ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: antigravity ok av=needsConfiguration(reason: "App 已安装，dashboard 暂未接入") q=0 tier=-
QB: gemini ok av=notInstalled q=0 tier=-
QB: claude ok av=notInstalled q=0 tier=-
```

7 个 provider 全部被识别。dashboard 里展示 Codex（真实 Plus 额度）+ Kimi/MiniMax/Trae/Antigravity（已安装但需在浏览器登录），过滤 Gemini/Claude（未登录且无 App）。

#### 已知遗留问题

1. **Edge Safe Storage 弹窗**：Kimi/MiniMax/Claude/Gemini pipeline 走 BrowserCookieProvider 时会触发（SweetCookieKit 行为，跟 CodexBar 一样）。需要 CodexBar 的 `BrowserCookieAccessGate` 类似机制在 `coordinator.refreshCycle` 一次性提示用户。
2. **截图验证没成功**：AppleScript 没点中 status bar item 的菜单，但日志已证 dashboard 数据正确。
3. **Kimi CLI token 不直接可用**：401 时 KimiAuthProvider 转 missingCredentials 让 pipeline fallback 到 Cookie/Keychain/App 兜底，是合理的。

### 20260701001745-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260701001745-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

来源：`agent-log/20260701150930-utcp8-gpt5.md` @ `955f9982d294cd8ad413127f111afc0de132eb39`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

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

### 2026-10-24 07:03:43 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
