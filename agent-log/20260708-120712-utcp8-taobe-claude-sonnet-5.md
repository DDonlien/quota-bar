# 用户原始 prompt

> 没道理呀，我什么都没改，但你之前的某个版本（我没记错的话，今天凌晨之前的版本。）Claude 能完全正常地获取到额度，即使不依赖 WebView。像我们之前参考的那些 Bar 类的应用，它们也完全不依赖 WebView 就能实现额度获取。
>
> 另外要注意的是，WebView 里面我也已经登录了，只是你没有获取到 WebView 的授权，这是我之前就在跟你说的bug。
>
> 然后重开应用之后，等了一会儿，Claude 就又有额度了。我期间打开过一次 WebView 的那个页面，我不知道是不是有这个的影响。
>
>（贴了一段完整真实诊断日志，2026-07-08 11:06:10 至 11:58:33，覆盖约 50+ 轮刷新周期）

# 启动运行时的分支和版本

- 分支：`main`
- 版本：本轮基于上一轮（日志刷新按钮 + 灰字精简 + 并发架构核实）未提交的工作树继续

# 任务开始时间

2026-07-08 12:00 +0800

# 任务结束时间

2026-07-08 12:07 +0800

# 任务结束时是否执行了提交

否——按惯例留给用户确认后再决定是否提交/推送。

# 已阅读上下文

- `BrowserCookieReader.swift`（`AppWebViewSessionCookieReader`）、`WKWebViewHeadlessLoader.swift`、`WebAuthorizationController.swift` 全文。
- `AppDelegate.swift`、`StatusBarController.swift`、`RefreshCoordinator.swift` 的启动/生命周期部分（`start()`/`runAutoRefreshLoop()`）。
- `Strategies.swift` 里 `-webview` 策略的注册位置。

# 对话与行动记录

上一轮（`0.10.0-INVESTIGATE-A-002`）把 `claude-webview："未登录"` 解释为"没有 Cookie，是状态事实不是 bug"。用户用一段完整、覆盖 52 分钟、50+ 轮刷新的真实日志直接反驳：全程 `claude-webview` 每轮都报"未登录"，但用户确认自己全程已经在 App 内 WebView 登录过；直到用户手动重新打开一次登录窗口之后，下一轮才第一次成功。这次没有回到"没登录"的旧结论，而是重新从代码路径确认到底哪里会创建 `WKWebView` 实例。

结果：全 App 范围内，**只有** `WebAuthorizationController.openAuthorization`（用户手动点开登录窗口）这一处会真正创建 `WKWebView`。而 `AppDelegate.applicationDidFinishLaunching` → `StatusBarController()` → `coordinator.start()` 会在冷启动的瞬间就立即触发第一轮刷新（`RefreshCoordinator.runAutoRefreshLoop()` 第一步就是 `await runRefreshCycle()`，没有任何延迟）。也就是说：如果用户这次启动没有主动去点开任何 provider 的登录窗口，整个进程生命周期里可能一次 `WKWebView` 都没创建过——`WKWebsiteDataStore.default()` 背后的 WebKit 网络进程/持久化 Cookie 存储很可能从未被真正初始化过，`httpCookieStore.allCookies()`（`AppWebViewSessionCookieReader` 用到的那个调用）因此长期停留在"进程未就绪"的空结果，即使磁盘上早就持久化了真实登录 Cookie。这个解释跟用户描述的现象——已登录但读不到、手动重开登录窗口后才恢复——完全吻合，不是巧合。

同时核对了用户提出的"回归"疑虑（"之前的版本不依赖 WebView 也能正常拿到额度，我什么都没改"）：贴的日志里 `claude-oauth` 的失败原因在 11:56:27 从"限流，稍后重试"变成了"Claude OAuth token 已过期，请重新 claude login"——这是本地 OAuth token 真实过期，需要用户重新 `claude login`，是账号状态的自然变化，不是本项目代码引入的回归。完整解释：用户的 OAuth token 之前一直有效，`claude-oauth` 一直单独就能覆盖额度，`claude-webview` 这个冷启动 bug 其实一直存在、只是从未被真正依赖过（`claude-oauth` 先一步成功，`FetchPipeline` 根本不会走到 webview 那层）；今天 token 过期后，`claude-oauth` 第一次真正失效，`claude-webview` 变成唯一还有希望的层，这个潜伏已久的 bug 才第一次变得"要命"。不是回归，是同一个 bug 第一次有了暴露的条件。

# 完成工作

- `WKWebViewHeadlessLoader.swift`：新增 `WebKitSessionWarmup`（`@MainActor enum`），创建一个不可见（frame `.zero`、不挂窗口）的 `WKWebView` 并 `await` 一次 `httpCookieStore.allCookies()`，强制 `.default()` data store 提前完成初始化。
- `AppDelegate.swift`：`applicationDidFinishLaunching` 改为在 `Task { @MainActor in ... }` 里先 `await WebKitSessionWarmup.warmUp()`，再构造 `StatusBarController()`（进而触发 `coordinator.start()` 和第一轮刷新）——保证读 Cookie 之前 data store 已经预热过。
- `REQUIREMENTS.md`：新增 `[0.10.0-BUG-A-019]`（根因定位 + 修复）、`[0.10.0-INVESTIGATE-A-003]`（回归疑虑排查结论：不是回归，是同一个潜伏 bug 第一次被暴露），并在 `0.10.0-INVESTIGATE-A-002` 词条后追加一行注明其结论已被推翻。
- 未做：给用户建议重新执行一次 `claude login` 刷新真实 OAuth token（这是账号侧动作，只能建议，不能代劳）。

新包：`macos/build/20260708-120611-main/Quota Bar.app`（`build/latest` 已指向）。

# 更新的需求 ID

- `[0.10.0-BUG-A-019]` `[0.10.0-INVESTIGATE-A-003]`

# 更新的 README 或 DESIGN 章节

- 无。

# 验证方式

- `swift build`：无警告无错误。
- `swift test`：186 tests in 42 suites 全部通过（本轮未新增/删除测试——`WebKitSessionWarmup` 直接创建真实 `WKWebView`/`WKWebsiteDataStore`，不适合在单元测试里跑，行为需要用户在真实环境里重新验证）。
- `./scripts/build-app.sh`：产包成功。
- 未做额外的本机独立进程实证测试——检查发现用户当前只有一个 Quota Bar 实例在跑（PID 66993，11:56 启动，大概率就是用户重开后仍在用的那个实例），为了不重复上一轮"多开实例互相干扰"的问题，这次没有再启动一个独立验证进程，改为请用户直接退出现有实例、换成新包重新测试。

# 备注

- 未提交 git commit。
- 建议用户：(1) 退出当前运行的 Quota Bar 实例，改用新包 `build/latest` 重新启动，验证 Claude 额度是否从第一轮刷新就能通过 WebView 拿到（不需要再手动重开登录窗口）；(2) 顺手执行一次 `claude login` 刷新已过期的 OAuth token，`claude-oauth` 仍然是最快最直接的额度层。
- 这个修复对 `claude-webview`/`minimax-webview`/`kimi-webview`/`codex-webview` 四个 provider 应该都有效——它们共用同一个 `AppWebViewSessionCookieReader`，根因和修复都在读取层，不是某个 provider 专属的问题。
