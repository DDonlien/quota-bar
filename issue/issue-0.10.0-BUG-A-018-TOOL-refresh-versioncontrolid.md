# sub/main: 日志页刷新按钮 + 灰字精简 + 并发架构核实

- ID：`0.10.0-BUG-A-018`。
- 类型：`TOOL`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理标识：`versioncontrolid`（含义待定义，不推断为 commit、branch 或 change）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 日志页刷新按钮 + 灰字精简 + 并发架构核实。
- 原稳定 ID：`0.10.0-BUG-A-018`, `0.10.0-CLEAN-A-002`, `0.10.0-INVESTIGATE-A-001`, `0.10.0-INVESTIGATE-A-002`；不改写或重编号这些既有 ID。

## 当前需求与范围

> 用户反馈三点：「日志里的刷新按钮没用」；「Provider 刷新超时」/「刷新间隔」下方的灰色说明文字不需要；诊断日志"现在是全刷新完了才会出来，其实应该逐条输出的"。同时贴了一段真实日志追问"claude又获取不到额度了"——Antigravity 单独耗时 31 秒（`antigravity-cli-session`），其余 6 个 provider 的日志行全部标着同一秒的时间戳，看起来像是被 Antigravity 卡住、全部堆到一起才出来。

- [x] [0.10.0-BUG-A-018] 「偏好设置 → 日志」页的「刷新」按钮此前只是重新读一遍已经落盘的日志文件——如果后台没有恰好在点击前跑完一轮真实刷新，点了跟没点一样。改名「立即刷新」，新增 `.manualRefreshRequested` 通知，`RefreshCoordinator` 订阅并调用 `refreshNow()`；日志页本身已经在监听 `.providerCheckLogDidChange`，新日志写入时会自动展示，不需要按钮自己重读 #P0
- [x] [0.10.0-CLEAN-A-002] 删除「通用」页「刷新间隔」/「Provider 刷新超时」两行下方的说明性灰字（用户反馈不需要，设置项名称本身已经足够清晰）#P2
- [x] [0.10.0-INVESTIGATE-A-001] 排查"诊断日志全刷新完才出来、其余 provider 都卡到 Antigravity 完成才显示"的疑似并发 bug：用 `log stream` 抓取真实 unified log，在本机对同一批 provider 单独触发一轮刷新做对照实验，实测 `withTaskGroup` 里全部 7 个 provider 的 "▶️ start pipeline" 确实在同一毫秒内并发发起，opencode/zcode/kimi/minimax/claude/codex 各自独立在 0.05–2.6 秒内完成并各自 flush 落盘——`RefreshCoordinator`/`FetchPipeline` 的并发设计和逐 provider 落盘逻辑本身没有 bug，只有 Antigravity 因为要拉起临时 `agy` 会话轮询确实需要约 30 秒。用户贴的那段日志之所以"全部堆在同一秒"，最可能的原因是当时同一台机器上同时跑着 2-3 个 Quota Bar 实例（本轮会话过程中多次直接观测到），各自的自动刷新周期互相竞争 CPU/子进程/共享磁盘文件，造成偶发的多秒延迟，不是代码层面的序列化 bug；已在过程中发现并核实一处真实但影响很小的代码坏味道（`AntigravityCLISessionProvider.agyPIDs()` 用同步阻塞的 `Process.waitUntilExit()`，没有像 `CLICommandLocator.locate` 那样包一层后台 continuation），评估后判断修复它需要把 `ManagedSession`/`SessionLauncher` 整条接口改成 async（牵动测试注入点），而这两次 `pgrep` 调用本身只有几十毫秒、不足以解释观测到的数十秒延迟，收益不确定、风险不小，本轮不做，记录为已知的小项债务 #P2 — 结论：不需要代码修复，建议用户平时只保留一个 Quota Bar 实例运行
- [x] [0.10.0-INVESTIGATE-A-002] 排查"claude 又获取不到额度"：贴的日志显示 `claude-oauth` 因为 Anthropic 服务端限流失败（"Claude usage 端点限流，稍后重试"，瞬时状况非 bug），`claude-webview` 因为 App 内 WebView 会话没有登录态失败（"未登录"），`claude-auth-status-cli` 只贡献档位（Pro/¥136）没有额度；顺手核实了日志里完全没出现 `claude-keychain` 这一行的原因——`QuotaProviderStrategy.supportedLayers` 对含 "keychain" 的 id 只声明 `[.provider]`（`Strategies.swift:42-44`），FetchPipeline 判断"额度层缺失时是否值得重试这个来源"时因为 `.quota` 跟 `[.provider]` 不相交直接 `continue` 跳过，不会调用 `fetch()`，自然也不会有日志——这是刻意设计（Keychain 只能证明凭证存在，从来生成不了额度数字），不是遗漏的 bug，不需要改 #P2 — **注：本条"claude-webview：未登录 = 状态事实非 bug"的结论已被下一条 `0.10.0-BUG-A-019` 推翻，是真 bug，见下条**

## 检查与验收边界

以上勾选与结果沿用迁移前的当前需求文档；历史记录中的实现、测试、编译、视觉与用户验收彼此独立。本次只迁移文档并检查结构 / 引用，没有重新执行产品构建或用户验收，也没有凭历史日志新增完成勾选。

## Comments

### 2026-10-23 17:44:33 UTC — Agent（文档迁移）

按原有功能 / 工作目标标题拆分需求，保留原 ID、勾选、依赖、最新补充及来源。没有稳定根 ID或旧 ID 在不同上下文重用时，采用由来源路径和标题确定的迁移 Issue ID，原 ID 仍在正文保留。完整旧内容可从来源版本读取；独有未提交内容的版本化副本见迁移映射。

### 20260708-113200-utcp8-taobe-claude-sonnet-5.md — 历史证据迁移

来源：`agent-log/20260708-113200-utcp8-taobe-claude-sonnet-5.md` @ `211555173930360a07f45b8f9662463ed7519dba`。日期 / 时区沿用原记录；以下摘录不自动改变当前完成状态。

#### 用户原始 prompt

>（截图：Preferences「通用」页「刷新」区块，"刷新间隔"和"Provider 刷新超时"两行下方各有一段灰色说明文字）
>
> 日志里的刷新按钮没用；附件里的灰色字不需要；刷新日志现在是全刷新完了才会出来，其实应该逐条输出的（虽然需要org顺序，但至少比如我第一个provider出来了，那就显示，第二个provider的信息如果比第一个provider的其他信息更快可以等）
>
> claude又获取不到额度了什么鬼……
>
>（贴了一段完整真实诊断日志，Antigravity/opencode/MiniMax/Z Code/Kimi/Claude/Codex 全部 provider 的两轮刷新记录）

#### 完成工作

- `Preferences/GeneralSettingsView.swift`：删除「刷新间隔」/「Provider 刷新超时」两行的说明性灰字。
- `Preferences/DiagnosticsSettingsView.swift`：「刷新」按钮改名「立即刷新」，行为从 `reload()` 改为 post `.manualRefreshRequested`。
- `PreferencesStore.swift`：新增 `.manualRefreshRequested` 通知。
- `RefreshCoordinator.swift`：订阅新通知触发 `refreshNow()`。
- 未改动任何并发/流式输出相关代码——实测确认现有设计本身正确，不需要修。
- 未改动 `AntigravityCLISessionProvider.agyPIDs()`——记录为已知代码坏味道，评估后判断本轮不值得改。

新包：`macos/build/20260708-112816-main/Quota Bar.app`（`build/latest` 已指向）。

#### 更新的需求 ID

- `[0.10.0-BUG-A-018]` `[0.10.0-CLEAN-A-002]` `[0.10.0-INVESTIGATE-A-001]` `[0.10.0-INVESTIGATE-A-002]`

#### 验证方式

- `swift build`：无警告无错误。
- `swift test`：186 tests in 42 suites 全部通过（本轮未新增/删除测试，纯 UI/通知改动）。
- `./scripts/build-app.sh`：产包成功。
- **真实对照实验**：`log stream` 抓取 unified log + 直接运行打包好的二进制触发一轮真实刷新（详见上文对话记录），是本轮排查并发问题的主要证据来源，不是纸面推理。

#### 备注

- 未提交 git commit。
- 本次为了验证并发行为，直接运行了一个独立于用户现有实例之外的新进程（用打包产物的二进制路径直接执行，不是 `open`），运行约 45 秒后手动结束——这个实例会读写跟用户真实实例相同的 `~/Library/Application Support/QuotaBar/` 共享文件（`preferences.json`/`provider-sources.json`/`provider-check.log`/快照缓存），效果等价于用户自己多開一次 app 触发一轮真实刷新，不是破坏性操作，但如实记录一下这个事实。
- 给用户的建议：日常只保留一个 Quota Bar 实例运行——本轮结束时检测到机器上还有一个从 10:50 就在跑的开发版实例（PID 23746），建议用户自己确认是否还需要，若不需要可以自行退出（没有替用户操作，避免误伤正在进行的测试）。
- `AntigravityCLISessionProvider.agyPIDs()` 的同步阻塞调用（`Process.waitUntilExit()`/`readDataToEndOfFile()` 没包后台 continuation）记录为已知技术债，不在本轮修复范围，如果之后有专门时间做 Antigravity 相关的并发/性能优化可以一并处理。
