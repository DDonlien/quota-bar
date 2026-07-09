# 用户原始 prompt

> 输入api密钥后应用会直接crush（只是粘贴甚至没有回车），以及你的输入框还是很不macos26

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（日志页 LazyVStack 卡顿修复）未提交的工作树继续

# 任务开始时间

2026-07-09 00:10 +0800

# 任务结束时间

2026-07-09 00:16 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `~/Library/Logs/DiagnosticReports/QuotaBar-2026-07-09-000952.ips`（真实崩溃报告，用 Python 解析 JSON 结构拿到异常类型/线程堆栈）。
- `WKWebViewHeadlessLoader.swift`（`WebKitSessionWarmup`，昨天新增）。
- `MenuView.swift` 的 `APIKeyTextField`/`FocusTextField`/`Coordinator` 全文。
- `Preferences/ModelsSettingsView.swift` 的 `APIKeyConfigRow`。

# 对话与行动记录

用户说"crush"，这是明确的崩溃报告，不是体感变慢——第一件事是找真实崩溃日志，而不是从代码猜。`~/Library/Logs/DiagnosticReports/` 下确实有一份几分钟前生成的 `QuotaBar-2026-07-09-000952.ips`，PID 对得上刚才启动的那个开发态实例。

解析结果：`EXC_BAD_ACCESS` / `SIGSEGV`，`KERN_INVALID_ADDRESS at 0x0`（空指针解引用），崩溃线程是主线程，完整堆栈从下往上是：`QuotaBar_main` → `NSApplication run` → 标准事件循环 → `RunLoop::performWork` → `IPC::Connection::dispatchIncomingMessages` → `WebKit::WebProcessProxy::didReceiveMessage` → `RemoteLayerTreeDrawingAreaProxy::commitLayerTree` → `RemoteLayerTreeHost::updateLayerTree` → `RemoteLayerTreePropertyApplier::applyHierarchyUpdates` → 一次 Swift concurrency 的 executor 检查 → `objc_msgSend` 撞上空地址。

这条堆栈完全在 WebKit 内部，处理的是从 WebContent 进程异步发来的 IPC 消息（提交 remote layer tree），跟 API Key 输入框的代码（纯 SwiftUI + 一个 AppKit NSTextField 包装）完全不在同一条调用链上——用户"粘贴之后就崩"大概率是巧合的时间重叠（正好在那个 run loop tick 上处理到了这条异步 IPC 消息），不是粘贴动作直接导致的。

那问题出在哪个 WKWebView？回想了一下这两天新增的东西：昨天（`0.10.0-BUG-A-019`）刚加的 `WebKitSessionWarmup` 创建了一个 frame `.zero`、永远不挂任何 `NSWindow`/superview 的 `WKWebView`，长期用一个 static 变量强引用着，从来没有真实的窗口宿主。跟 App 里其余所有 WKWebView 用法对比——`WebAuthorizationController` 的登录窗口、`WKWebViewHeadlessLoader` 的抓取窗口——全部都挂在一个真实的 `NSWindow` 上。一个永远没有真实宿主环境、却长期存活的 `WKWebView` 是个不正常的配置，让 WebKit 内部 remote layer tree 的状态长期处于说不清楚的形态是完全说得通的解释；某次异步 IPC 回调命中了这个不正常状态就崩了。

同时看了一眼 `APIKeyTextField`——这是很早之前专门为 dropdown 里一个已经删掉的内联输入框（`NSMenu` tracking-mode 下 SwiftUI 原生 TextField 拿不到焦点/键盘输入）做的 AppKit 变通，包了两个全局 `NSEvent` 本地监听器拦截 `Cmd+V`/`mouseUp`。搜了一下，`APIKeyTextField` 现在唯一的调用点是 Preferences 里的 `APIKeyConfigRow`——而 Preferences 是普通 `NSWindow`，根本不需要这套 workaround。这也顺带解释了用户说"还是很不 macOS 26"：这是一个手工拼装外观的 AppKit 控件，不是原生 SwiftUI `TextField`。

# 完成工作

- `WKWebViewHeadlessLoader.swift`：`WebKitSessionWarmup.warmUp()` 改成给预热用的 `WKWebView` 一个真实的 `NSWindow`（屏幕外坐标 `-10000,-10000`、`.borderless`、永远不 `orderFront`/不可见），不再是一个裸的、没有任何宿主的 `WKWebView`。
- `MenuView.swift`：删除整个 `APIKeyTextField`/`FocusTextField`/其 `Coordinator`（含两个全局 `NSEvent` 监听器）——死代码，唯一调用点已经改用原生控件。
- `Preferences/ModelsSettingsView.swift`：`APIKeyConfigRow` 的输入框从 `APIKeyTextField` 改成原生 SwiftUI `TextField`（`.textFieldStyle(.roundedBorder)` + 等宽字体 + `.onSubmit(save)`）。

新包：`macos/build/20260709-001608-main/Quota Bar.app`（`build/latest` 已指向），已重启本机的开发态实例。

# 更新的需求 ID

- `[0.10.0-BUG-A-023]` `[0.10.0-CLEAN-A-003]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误（确认删除 `APIKeyTextField`/`FocusTextField` 后没有遗留引用）。
- `swift test`：190 tests in 43 suites 全部通过（没有测试引用这两个类型）。
- `./scripts/build-app.sh`：产包成功，重启本机开发态实例指向新包。
- **未做**：没能真正复现这次崩溃（WebKit 内部状态问题本来就难以稳定复现），这次修复是基于崩溃日志的堆栈分析 + 对比"哪个 WKWebView 用法跟其余稳定用法不一样"得出的最可能根因，不是靠复现验证的确定性修复。请用户重新粘贴 API Key 测试，如果崩溃再次出现，请求再给一次新的崩溃日志路径（`~/Library/Logs/DiagnosticReports/QuotaBar-*.ips`），可以进一步缩小范围。

# 备注

- 未提交 git commit。
- 这是本次会话第一次真正基于系统级崩溃报告（`.ips` 文件）而不是代码走读/日志文本做诊断——比之前几轮的"读诊断日志文本猜测"更接近确定性证据，但 WebKit 内部崩溃本身样本量只有一次，不能 100% 排除是其他原因（比如系统本身的 WebKit 版本 bug），如果修复后仍然复现，需要进一步收窄范围（比如临时完全禁用 `WebKitSessionWarmup` 做 A/B 对照）。
