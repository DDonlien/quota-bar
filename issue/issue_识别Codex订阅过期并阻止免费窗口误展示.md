# 识别Codex订阅过期并阻止免费窗口误展示

- ID：`0.10.0-ARCH-A-000`。
- 类型：`ARCH`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: Codex 订阅过期识别。
- 原稳定 ID：`0.10.0-ARCH-A-000`, `0.10.0-ARCH-A-001`, `0.10.0-ARCH-A-002`, `0.10.0-ARCH-A-003`, `0.10.0-DATA-A-000`, `0.10.0-DATA-A-001`, `0.10.0-DATA-A-002`, `0.10.0-DATA-A-003`, `0.10.0-DATA-A-004`, `0.10.0-DATA-A-005`, `0.10.0-QA-A-000`；不改写或重编号这些既有 ID。

## 当前需求与范围

- [x] [0.10.0-ARCH-A-000] `JWTPayloadDecoder` 工具：解 JWT payload 部分（不验签，只读 base64url+JSON），失败返回 nil #P1
- [x] [0.10.0-ARCH-A-001] `OpenAIAuthPayload`：读取 `https://api.openai.com/auth` namespace 下的 planType、subscriptionActiveUntil、lastChecked、accountId、userId 等字段 #P1
- [x] [0.10.0-ARCH-A-002] `SubscriptionStatus`：区分 `.active(expiresAt)` / `.expired(lastPlan, expiredAt)` / `.free` / `.unknown` #P1
- [x] [0.10.0-ARCH-A-003] `CodexSubscriptionInspector`：从 `~/.codex/auth.json` 解 id_token → 映射成 `SubscriptionStatus`；失败一律返回 `.unknown`，不反推 #P1
- [x] [0.10.0-DATA-A-000] `CodexAuthProvider.fetchSnapshot` 在发 wham/usage 前先调 `CodexSubscriptionInspector.inspect()`；过期 / free 时返回 `availability: .subscriptionExpired(plan, expiredAt)` 的 marker snapshot #P1
- [x] [0.10.0-DATA-A-001] `CodexDashboardParser.parse` 对 `plan_type == "free"` 返回 nil，防止 free 月额度被解析成付费额度窗口 #P1
- [x] [0.10.0-DATA-A-002] `BrowserCookieProvider.fetchSnapshotImpl` Codex 路径在发请求前先调 `CodexSubscriptionInspector`，过期 / free 时返回 marker snapshot #P1
- [x] [0.10.0-DATA-A-003] `ProviderAvailability` / `QuotaFetchError` 新增 `.subscriptionExpired(plan, expiredAt)`，并在 UI / 状态栏 / fetch priority 中处理 #P1
- [x] [0.10.0-DATA-A-004] `MenuView.PlanSection` 对 `.subscriptionExpired` 只显示灰标提示，不渲染 quota rows #P1
- [x] [0.10.0-DATA-A-005] `StatusBarController` 对 `.subscriptionExpired` 显示 “已过期” tooltip，并以 0% bar 占位 #P1
- [x] [0.10.0-QA-A-000] 单元测试覆盖 JWT decode、auth payload、active/expired/free/unknown 状态、Codex parser free 防御与 expired marker 行为 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260702013307-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260702013307-utcp8-mavis.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 把 main 的内容 merge 到这个分支；Merge 之前或者之后，帮我检查两个问题：
>
> 1. 为什么 Antigravity 现在获取不到订阅额度了？
> 2. 为什么 Codex 现在获取不到有效的订阅了？
> 这两个对象我不确定在这个分支的某个版本是否曾有可用代码，即能正确获取到额度和订阅信息的代码。但现在 main 分支上的版本是不行的。
>
> 请先确认情况并告诉我你的解决思路，之后我们再决定是否要合并。

后续对话展开：用户提供截图（macOS 菜单栏下拉面板），发现 Codex 显示「订阅已过期 · plus · 到期 2026/6/25」、Antigravity 显示「待配置 · App 已装 (/Applications/Antigravity.app)」。然后补充：

> 我的 Codex 25 号是过期了，但我又续费了，就在昨天。既然 Antigravity Apps 的获取权限已经失败了，你就应该接着按顺序尝试 CLI 和 Web 吧

最后一句 `do it`，表示授权执行 v0.8.1 修订方案。

#### 完成工作

- 4 个源文件改动：`CodexAuthProvider.swift`、`BrowserCookieProvider.swift`、`RefreshCoordinator.swift`、`REQUIREMENTS.md`
- 1 个新测试文件：`Tests/QuotaBarTests/CodexAuthProviderInspectorThrowTests.swift`（351+ 行，4 个 test suite，8 个测试）
- 编译：`swift build` 完整通过
- 测试：`swift test` 47/47 通过（v0.8.0 39 个 + v0.8.1 新增 8 个）

#### 更新的需求 ID

新增 v0.8.0 phase 子 block：

- `[0.8.0-DATA-C-000]` `CodexAuthProvider` inspector 过期 throw
- `[0.8.0-DATA-C-001]` `BrowserCookieProvider` Codex 路径移除 inspector
- `[0.8.0-DATA-C-002]` `RefreshCoordinator` subscriptionExpired 优先 installDetail
- `[0.8.0-DATA-C-003]` `RefreshCoordinator` 其他 error 仍走 installDetail
- `[0.8.0-DATA-C-000-test]` CodexAuthProvider throw 测试
- `[0.8.0-DATA-C-001-test]` BrowserCookieProvider 不再短路测试
- `[0.8.0-DATA-C-002-test]` Codex pipeline strategy 顺序测试
- `[0.8.0-DATA-C-004-test]` availabilityFallback 契约测试

#### 验证方式

- `cd quota-bar && swift build` — 完整 build 通过
- `cd quota-bar && swift test` — 47 tests in 12 suites passed
- 手动集成验证（user 跑 build）：user 需要重新 build macOS app 并打开 dropdown 看 Codex 行的状态：
  - 如果 OAuth wham/usage 拿到真实 plus quota → 显示真实 quota
  - 如果 BrowserCookie 拿到真实 plus quota → 显示真实 quota
  - 如果 CLI 日志有 → 显示粗略估算
  - 如果全失败 + inspector 真过期 → 显示「订阅已过期 · plus · 到期 2026/6/25」（不再被 installDetail 覆盖成"待配置"）

#### 备注

- Antigravity 任务**未启动**：pipeline 架构上不存在 CLI / Web quota 路径，必须等 user 提供 Console 日志才能定位 DashboardProvider 失败原因（最可能是 Antigravity IDE 本地 protocol 变更 / 进程名 / 端口 / csrf 来源变化）。建议另开 task 处理。
- merge main → sub/main 的决定暂未执行：v0.8.1 修订与 main 上的代码行为已经一致（main 上 md5 一致 / 逻辑等价），merge 的增量价值主要是 v0.9.0 REQUIREMENTS + `CodexSubscriptionInspectorTests.swift` 测试。等 v0.8.1 验证通过后再决定 merge 节奏。
- 不 commit：等 user review + 在 Antigravity 任务开新工作分支前不污染 sub/main commit history。

### 20260629014432-utcp8-mavis.md — 历史证据迁移

来源：`agent-log/20260629014432-utcp8-mavis.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 开一个新的branch: sub/main，并创建对应的worktree，处理现在订阅过期的情况：我的codex已经过期了但却刷出了"月额度"我估计其他的过期也没处理

#### 验证

- `cd .worktrees/sub-main/quota-bar && swift build` → Build complete! (2.38s), 0 warning
- `cd .worktrees/sub-main/quota-bar && swift test` → 39 tests in 8 suites passed

#### 更新的需求 ID

- 新增 `v0.8.0` 完整 phase：
  - `### ARCH-A`：4 个 task（基础架构，全部完成）
  - `### DATA-A`：7 个 task + 2 个测试任务（Codex 订阅过期识别，全部完成）
  - `### UI-A`：4 个 task（UI 表现，全部完成）
  - `### DATA-B`：5 个 task（其他 provider inspector 模式，全部 deferred / cut，登记）

#### 验证方式

- `swift build` 通过 0 warning
- `swift test` 39 tests passed
- ground truth 验证：用真实 `~/.codex/auth.json` 跑 inspector + 用 refresh_token 跑 wham/usage 验证 parser 在 plan_type=free 时返回 nil
- 测试覆盖：JWT 4 路径 / inspector 6 路径 / parser free 路径 / statusColor 安全 / SubscriptionStatus 语义

#### 备注

- **v0.8.0 只覆盖 Codex**：user 触发 case 是 Codex，且 Codex 的 id_token 字段是已知。Claude/Cursor/Antigravity/MiniMax 的同类检测都登记为 deferred（v0.8.0-DATA-B-000/001/002/003），等 v0.6.0 第二批 headless 抓订阅页落地后沿用同模式做。
- **"返回 snapshot 而不是 throw"是关键设计**：throw 会让 pipeline 走到 BrowserCookie / CLILog 仍然显示 5h+weekly 误数据。返回 marker snapshot 让 pipeline 立即返回，UI 切到 "订阅已过期" 灰标。
- **不验证 JWT 签名**：安全模型是"已经持有 token → 验签无意义"，攻击者有 root 就能改本机 UI。
- **可能需要后续**：
  1. 选 v0.8.0-DATA-B-001 (Cursor) 推进一步：Cursor dashboard 页面抓"Plan renews on..." 文本
  2. 选 v0.8.0-DATA-B-000 (Claude)：解析 claude.ai session token 的 membership 字段
  3. 合并到 main 后开 `feat/codex-subscription-expiry` branch 进一步打磨（暂时不必要）
- user 的实际过期日 `2026-06-25`，本次 commit 后可在自己的 Mac 上 `swift run` 直接看到修复效果。

### 20260702141144-utcp8-gpt5.md — 历史证据迁移

来源：`agent-log/20260702141144-utcp8-gpt5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 我可以让用户去开启 Full Disk Access、辅助功能以及录制权限，因为这些都包含在设置选单里，操作非常常规。
>
> 但是，如果让用户在弹窗里面进行操作，这就太不常规了。你要想一想有没有什么 workaround
>
> 已过期的逻辑很简单：
>
> 1. 首先你要确保现在“我的”获取是正确的
> 2. 其次在正确的前提下，根据过期日显示状态：
>    (a) 如果最近的过期日是在一个自然周内，就显示为“已过期”
>    (b) 如果超过一个自然周，不管你是新的还是没有订，直接显示“未订阅”就行但是 auth.json 的 id_token 有问题这件事也很奇怪。
>
> 因为实际上我 Codex 的应用读的就是 .codex-auth.json 里面的东西，而我 Codex 应用本身（也就是你自己）是可以正常 running 的，那这里面的信息怎么可能错呢？你实际上读一下不就知道了？

#### 完成工作

- 确认 `id_token` 订阅元信息确实陈旧，不能单独作为当前订阅状态真相。
- 确认 Codex 能运行与 `id_token` 订阅字段正确不是同一件事：本机 `access_token` 仍有效到 2026-07-06，运行态可能依赖 access token / refresh token，而不是依赖已过期的 id_token payload。
- 初步方案：
  - 订阅真相优先使用当前可验证的服务端 usage / dashboard / 刷新后的 token 信息。
  - `id_token` 只作为本地线索，不能短路真实抓取。
  - `.free` / 从未订阅 与 `.expired` 分离；超过一个自然周的过期也归为“未订阅”。
  - 浏览器权限不要走连续弹窗；改为设置页/系统设置入口 + 用户主动授权/选择浏览器来源。

#### 更新的需求 ID

无。

#### 验证方式

- `git pull`
- `ls -la ~/.codex ~/.codex/auth.json ~/.codex-auth.json`
- `stat -f ... ~/.codex/auth.json ~/.codex-auth.json`
- Node.js 只读解析 `~/.codex/auth.json` 的非敏感 JWT payload 字段。
- Node.js HTTPS 调用 wham/usage 尝试失败，记录 TLS 证书不匹配原因。

#### 备注

- 中途一次文本搜索意外匹配到 auth.json 中的 refresh_token 行；未在答复中复述 token。后续调查应避免直接 `rg` auth 文件内容，改用结构化脚本只输出非敏感字段。

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。原目标、实施与验收步骤及完整历史保持在同一文件。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
