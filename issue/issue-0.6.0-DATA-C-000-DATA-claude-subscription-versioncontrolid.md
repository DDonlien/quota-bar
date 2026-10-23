# feat/subscription-expiry: 接入 Claude 真实订阅到期日

- ID：`0.6.0-DATA-C-000`。
- 类型：`DATA`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.6.0 - 真实订阅到期日（headless 抓取订阅页） / feat/subscription-expiry: 接入 Claude 真实订阅到期日。
- 原稳定 ID：`0.6.0-DATA-C-000`, `0.6.0-DATA-C-001`, `0.6.0-DATA-C-001-test`；不改写或重编号这些既有 ID。

## 当前需求与范围

> Claude (claude.ai) 的 `/api/organizations/{uuid}/usage` 不返回订阅到期日。需要 headless 抓 `claude.ai/settings/plan` 或 `claude.ai/account/billing`，提取「Next billing」「Renews on」之类。

- [x] [0.6.0-DATA-C-000] `ClaudeHarvester` 实现：加载 `https://claude.ai/new#settings/billing`，DOM 提取续费日期 #P1
- [x] [0.6.0-DATA-C-001] 通过独立 source 管线集成到 Claude snapshot enrichment #P1
- [x] [0.6.0-DATA-C-001-test] 单元测试：mock HTML 验证解析 #P1

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260706-230052-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260706-230052-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 但我看你最新的包claude还是没有额度？我给你的3个reference项目肯定是不需要通过webview之类的途径获取claude额度的，最多就是去系统设置里开，你看看怎么回事

#### 完成工作

- `ClaudeAuthStatusCLIProvider.swift`：子进程环境从 `["HOME": ...]` 改为继承完整环境。
- `MiniMaxCommandProvider.swift`：子进程环境从 `["HOME": ..., "TERM": "dumb"]` 改为继承完整环境 + 覆盖 `TERM`。
- `ClaudeOAuthUsageProvider.swift`：新增 `ClaudeKeychainCredentialsReader`，`loadCredentials()` 改为文件优先、Keychain 兜底（取最近修改条目，允许一次性系统授权提示）。
- 新包：`macos/build/20260706-225934-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- 新增并完成：`0.10.0-DATA-B-016`（子进程环境裁剪修复）、`0.10.0-DATA-B-017`（Claude Keychain 凭证兜底）

#### 验证方式

- `make test`：162 tests in 38 suites 全部通过。新增 `CLISubprocessEnvironmentTests`：生成一个真实可执行的 fake CLI 脚本（打印 `$USER`），用 provider **默认（非 mock）执行器**跑一遍，断言子进程里能看到真实 `USER`——直接对着这次的根因写回归测试，不是泛泛测试。
- `make app`：成功产包。
- 命令行直接复现修复前后的行为差异（`env -i HOME=... ` vs `env -i HOME=... USER=...`）。
- 未能端到端验证 Keychain 授权弹窗的完整流程——需要用户交互点「始终允许」，我这边无法代为点击；已关闭本次会话中为调试打开的旧包实例，避免残留后台进程。

#### 备注

- 未提交 git commit。
- 用户装新包后大概率会看到一次系统 Keychain 授权弹窗（"quota-bar 想使用你钥匙串中的机密信息…Claude Code-credentials"），需要点「始终允许」；这是本机没有 `.credentials.json` 文件、走 Keychain 兜底路径时的正常一次性动作，点过一次后长期生效，不会每次刷新都弹。
- 这次 bug 提醒我一个模式：写"隔离子进程环境"这类代码时，默认应该是"继承 + 覆盖"（`TTYCommandRunner.runRaw` 已有的正确写法），而不是"从零构造一份精简环境"——后者极容易漏掉某个工具意想不到依赖的变量，且很难在开发机上凭空发现（因为开发机的 shell 环境天然是完整的，只有在真正走到"被裁剪的子进程"这条代码路径时才会暴露）。

### 20260808-223737-utcp8-taobe-deepseek-v4-flash.md — 历史证据迁移

来源：`agent-log/20260808-223737-utcp8-taobe-deepseek-v4-flash.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 有问题啊，我发现现在订阅过期了的 claude 是刷不出订阅过期这个信息的，看起来还是全额度重置时间未知

#### 完成工作

- `macos/Sources/QuotaBar/DashboardEndpoints.swift`：
  - `DashboardParser` 协议 + 默认扩展新增 `indicatesNoActivePlan(data:)`（默认 false）；
  - `ClaudeUsageWindowParser.indicatesNoActivePlan(data:)`：已知窗口键（five_hour/seven_day/seven_day_sonnet/seven_day_opus，null 值键不算存在）有窗口但全部 `resets_at` 解析为 nil → 无有效订阅；一个窗口都没有返回 false（schema 变化不误判）；
  - `ClaudeDashboardParser` 实现该协议方法。
- `macos/Sources/QuotaBar/BrowserCookieProvider.swift`：`fetchSnapshotImpl` 解析出窗口后检查 `parser.indicatesNoActivePlan`，命中返回 `.notSubscribed` marker snapshot。
- `macos/Sources/QuotaBar/ClaudeOAuthUsageProvider.swift`：OAuth usage 响应命中同一信号时返回 `.notSubscribed` marker。
- `macos/Sources/QuotaBar/ClaudeStatusLineUsageProvider.swift`：`indicatesNoActivePlan(_:)`（仅显式 `NSNull` 判定）+ `fetchSnapshot` 命中时返回 marker。
- 测试：`ClaudeDashboardParserTests`（expired 全缺失 → true 且窗口仍可解析、任一窗口带 resets_at → false、无窗口 → false、全 null 键 → false）、`ClaudeOAuthUsageProviderTests`（expired 响应 → notSubscribed marker）、`ClaudeStatusLineUsageProviderTests`（显式 null → marker、键缺失 → 仍 available、indicatesNoActivePlan 判定边界）。
- `REQUIREMENTS.md`：`0.10.0-DATA-B-005` 登记完成（挂在既有 `sub/main: 所有 AI Provider 统一订阅过期识别` feature 下）。

#### 更新的需求 ID

- [x] `0.10.0-DATA-B-005`（新增，Claude 订阅过期识别）

#### 验证方式

- `cd macos && swift test`：265 条全过（含新增 8 条）。
- 行为推演（未实机跑 App）：用户机器上 Claude 管线顺序 statusline（无缓存失败）→ oauth（无凭证失败）→ auth-status-cli（未登录失败）→ webview（命中 no active plan → marker）→ 串行短路 → dropdown 显示「未订阅或订阅已过期」灰条，状态灯灰色，菜单栏不画 bar；过期日 headless 抓取不再每轮白跑（enrichment 对非 available 跳过）。

#### 备注

- 状态语义选择 `.notSubscribed`（灰色「未订阅或订阅已过期」）而非 `.subscriptionExpired`（红标）：usage 信号只能证明「无有效订阅」，拿不到到期日/上次套餐名，而 `.subscriptionExpired` 按需求文档语义只用于「最近一个自然周内的明确到期记录」；跟 MiniMax `no active token plan subscription` 的既有映射一致。
- 未来若 Claude billing 页 DOM 出现可靠的「Resume/已过期」文案或 OAuth 凭证携带到期字段，可在此信号之前插入更高优先级 source（对应 `0.10.0-DATA-B-000/001` 的剩余部分）。
- 未提交、未 bump VERSION（不涉及打包发布；用户如要发版需按 AGENTS.md 规则 bump PATCH 并在 changelog 追加记录）。

### 20260707-113316-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260707-113316-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

> 我发你的4个开源项目是怎么获得claude额度的

#### 完成工作

- `ClaudeOAuthUsageProvider.swift`：`ClaudeKeychainCredentialsReader.readCredentialsJSON()` 重写为 `Process` 调 `/usr/bin/security find-generic-password -w`；抽出 `readViaSecurityCLI(service:)` 便于测试注入不存在的占位 service 名；`ClaudeOAuthUsageProvider` 新增 `keychainReader` 构造参数（默认走真实实现）；`loadCredentials()` 改为 `async`。
- `Tests/QuotaBarTests/ClaudeOAuthUsageProviderTests.swift`：两个原本会意外读到真实 Keychain 数据的测试改为注入 `keychainReader: { nil }`；新增 `ClaudeKeychainCredentialsReaderTests` 验证不存在的 service 返回 nil。
- 新包：`macos/build/20260707-113301-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- `0.10.0-INVESTIGATE-A-000`：去掉 `#blocked` 标记（问题排查本身已完成，具体修复见下面新条目）。
- 新增并完成：`0.10.0-BUG-A-007`（Keychain 读取改走 security CLI）、`0.10.0-ARCH-H-000`（keychainReader 注入点 + 测试隔离修复）、`0.10.0-ARCH-H-000-test`（新增测试）。

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：179 tests in 42 suites 全部通过（含新增的 `ClaudeKeychainCredentialsReaderTests`，以及修复隔离问题后重新通过的两个 `missingCredentials` 测试）。
- `./scripts/build-app.sh`：产包成功。
- 未做真实 GUI 交互验证——这次的修复本身有没有彻底解决"Claude 额度获取"这个最终诉求，仍然需要用户在真实打包的 app 里实际观察是否还会弹出/正确处理系统 Keychain 授权对话框，这点在当前工具条件下做不到，如实告知。

#### 备注

- 未提交 git commit。
- 这一轮是"用户直接要求对照参考实现"带来突破的典型例子：上一轮凭代码走读 + 猜测（ad-hoc 签名 CDHash 不稳定）已经把方向猜对了大半，但没有具体到"该怎么改"；读了 CodexBar 的内部文档和 ClaudeBar 的真实源码后，不仅证实了这个猜测，还直接给出了一个已经被验证过、更简单的具体解法（shell 出系统 `security` CLI），而不需要自己重新发明一套 CodexBar 那种复杂的两段式查询 + prompt 状态机。
- 顺手改动暴露并修复了一个真实的测试隔离缺口（测试意外依赖开发机真实 Keychain 状态、意外发起真实网络请求）——这类问题往往要等实现从"读不到东西"变成"真的能读到东西"才会暴露，这次算是提前在自己机器上发现并堵上了。
