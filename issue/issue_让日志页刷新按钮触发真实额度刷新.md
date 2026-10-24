# 让日志页刷新按钮触发真实额度刷新

- ID：`0.10.0-BUG-A-018`。
- 类型：`TOOL`。
- 状态：已完成（沿用原需求记录；本轮未重新执行产品验收）。
- 版本管理：Git。
- 实施提交：未核实（当前仅核对迁移文档；来源快照、当前HEAD和文档迁移提交均不替代业务实施提交）。
- 来源：`REQUIREMENTS.md` @ `211555173930360a07f45b8f9662463ed7519dba`；标题路径：任务清单 / Phase - v0.10.0 - 订阅过期识别与免费额度误判修正 / sub/main: 日志页刷新按钮 + 灰字精简 + 并发架构核实。
- 原稳定 ID：`0.10.0-BUG-A-018`, `0.10.0-CLEAN-A-002`, `0.10.0-INVESTIGATE-A-001`, `0.10.0-INVESTIGATE-A-002`；不改写或重编号这些既有 ID。
- 拆分前ID：`0.10.0-BUG-A-018`（沿用旧ID，不新增编号）。
- 本任务原稳定ID：`0.10.0-BUG-A-018`。
- 状态范围：上方状态保留迁移前汇总；本任务逐项勾选、撤销标记和阻塞说明以本文件原文为准，未重新验收。
- 迁移前文件：`issue/issue-0.10.0-BUG-A-018-TOOL-refresh-versioncontrolid.md`（历史来源路径；原始来源版本见既有来源property）。
- 迁移前标题：sub/main: 日志页刷新按钮 + 灰字精简 + 并发架构核实。
- 同源任务：[精简刷新间隔与超时设置的说明灰字](issue_%E7%B2%BE%E7%AE%80%E5%88%B7%E6%96%B0%E9%97%B4%E9%9A%94%E4%B8%8E%E8%B6%85%E6%97%B6%E8%AE%BE%E7%BD%AE%E7%9A%84%E8%AF%B4%E6%98%8E%E7%81%B0%E5%AD%97.md)、[核对Provider并发刷新与诊断日志时序](issue_%E6%A0%B8%E5%AF%B9Provider%E5%B9%B6%E5%8F%91%E5%88%B7%E6%96%B0%E4%B8%8E%E8%AF%8A%E6%96%AD%E6%97%A5%E5%BF%97%E6%97%B6%E5%BA%8F.md)、[排查Claude限流与仅有档位时的额度失败](issue_%E6%8E%92%E6%9F%A5Claude%E9%99%90%E6%B5%81%E4%B8%8E%E4%BB%85%E6%9C%89%E6%A1%A3%E4%BD%8D%E6%97%B6%E7%9A%84%E9%A2%9D%E5%BA%A6%E5%A4%B1%E8%B4%A5.md)。

## 当前需求与范围

> 用户反馈三点：「日志里的刷新按钮没用」；「Provider 刷新超时」/「刷新间隔」下方的灰色说明文字不需要；诊断日志"现在是全刷新完了才会出来，其实应该逐条输出的"。同时贴了一段真实日志追问"claude又获取不到额度了"——Antigravity 单独耗时 31 秒（`antigravity-cli-session`），其余 6 个 provider 的日志行全部标着同一秒的时间戳，看起来像是被 Antigravity 卡住、全部堆到一起才出来。

- [x] [0.10.0-BUG-A-018] 「偏好设置 → 日志」页的「刷新」按钮此前只是重新读一遍已经落盘的日志文件——如果后台没有恰好在点击前跑完一轮真实刷新，点了跟没点一样。改名「立即刷新」，新增 `.manualRefreshRequested` 通知，`RefreshCoordinator` 订阅并调用 `refreshNow()`；日志页本身已经在监听 `.providerCheckLogDidChange`，新日志写入时会自动展示，不需要按钮自己重读 #P0

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

### 2026-10-24 07:04:08 UTC — Agent（任务命名与语义整理）

按具体原语言任务命名；类型与原ID保留在properties。将独立目标分开，实施与验收子步骤保持同组；历史Comments保留一次并链接共享。实施版本未核实，省略文件名版本后缀；本次未执行产品或代码验收。
