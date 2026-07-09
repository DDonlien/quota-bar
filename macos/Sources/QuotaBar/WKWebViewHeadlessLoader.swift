import Foundation
import WebKit

// MARK: - WebKitSessionWarmup

/// App 冷启动后、第一轮刷新读 `WKWebsiteDataStore.default()` 之前，主动"预热"一次
/// 默认 data store 的 Cookie 存储。
///
/// 背景（2026-07-08 用户实测反馈，日志覆盖 11:06–11:58 约 52 分钟）：用户全程已经
/// 在 App 内 WebView 登录过 Claude，但 `claude-webview`/`AppWebViewSessionCookieReader`
/// 连续约 50 轮刷新都报「未登录」（读到空 Cookie 列表）；直到用户手动重新打开一次
/// `WebAuthorizationController` 的登录窗口（这一步会真正创建一个 `WKWebView`）之后，
/// 同一进程内后续的 Cookie 读取才突然恢复正常。
///
/// 根因：整个 App 里，除了 `WebAuthorizationController.openAuthorization` 这一次
/// 性登录窗口之外，没有任何代码会创建 `WKWebView` 实例——而 `RefreshCoordinator.
/// start()` 在 `StatusBarController` 初始化时就立即触发第一轮刷新（见该文件），
/// 也就是说全程可能一次 `WKWebView` 都没创建过，`.default()` data store 背后的
/// WebKit 网络进程/Cookie 存储从未被真正启动过——`httpCookieStore.allCookies()`
/// 因此长期停留在"进程未就绪"的空态，即使磁盘上早已持久化了真实登录 Cookie。
///
/// 修复：在触发第一轮刷新之前，主动创建一个 `WKWebView` 并读一次 Cookie，强制该
/// data store 提前完成初始化——效果等价于用户手动打开一次登录窗口，但不需要用户
/// 参与。见 `AppDelegate.applicationDidFinishLaunching` 里的调用顺序：必须在
/// `StatusBarController()` 构造（进而 `coordinator.start()`）之前完成。
///
/// **2026-07-09 修订**：最初的实现只创建了一个 frame `.zero`、不挂任何窗口的裸
/// `WKWebView`，长期持有却从来没有真正的 `NSWindow`/superview 宿主。这跟 App 里
/// 其余所有 `WKWebView` 用法（`WebAuthorizationController` 的登录窗口、
/// `WKWebViewHeadlessLoader` 的抓取窗口）都不一样——那些都挂在一个真实的
/// `NSWindow` 上。真实崩溃日志（`QuotaBar-2026-07-09-000952.ips`）显示一次
/// `EXC_BAD_ACCESS`/`SIGSEGV`，出现在 WebKit 处理来自 WebContent 进程的异步 IPC
/// 消息、提交 remote layer tree 时（`RemoteLayerTreePropertyApplier::
/// applyHierarchyUpdates` 空指针解引用）——最可能的解释是一个永远没有真实窗口宿主
/// 的 `WKWebView` 让 WebKit 内部的 layer tree 状态长期处于不正常的形态，某次异步
/// IPC 回调命中了失效状态。修复：给这个预热用的 `WKWebView` 一个真实的
/// `NSWindow`（永远不 `orderFront`/不可见，只是给 WebKit 一个正常的宿主环境），
/// 跟已知稳定运行多轮的登录窗口用法保持一致，而不是用一个游离状态的裸 WKWebView。
@MainActor
enum WebKitSessionWarmup {
    /// 强引用，避免创建后立即被释放导致 data store 关联失效。
    private static var webView: WKWebView?
    /// 同样强引用——`WKWebView` 需要一个真实的宿主窗口，见上方 2026-07-09 修订说明。
    private static var window: NSWindow?

    static func warmUp() async {
        guard webView == nil else { return }
        let configuration = WKWebViewConfiguration()
        configuration.websiteDataStore = .default()
        let webView = WKWebView(frame: NSRect(x: 0, y: 0, width: 1, height: 1), configuration: configuration)

        let window = NSWindow(
            contentRect: NSRect(x: -10000, y: -10000, width: 1, height: 1),
            styleMask: [.borderless],
            backing: .buffered,
            defer: true
        )
        window.isReleasedWhenClosed = false
        window.contentView = webView
        // 故意不调用 makeKeyAndOrderFront/orderFront——窗口在屏幕外、永远不可见，
        // 只是给 WKWebView 一个正常的宿主环境。

        Self.webView = webView
        Self.window = window
        _ = await configuration.websiteDataStore.httpCookieStore.allCookies()
    }
}

// MARK: - WKWebViewHeadlessLoader

/// macOS native WKWebView 包装，用于 headless 抓取订阅管理页。
///
/// 工作流：
/// 1. 使用 `WKWebsiteDataStore.default()` 里 App 自有 WebView 会话的登录态
///    （由 `WebAuthorizationController` 的一次性 App 内 WebView 登录写入）；
/// 2. `WKWebView.load` 加载 URL；
/// 3. 等 `WKNavigationDelegate.didFinish` 回调；
/// 4. `evaluateJavaScript("document.documentElement.outerHTML")` 拿渲染后的 DOM 字符串。
///
/// 2026-07-08 移除了读取真实浏览器 Cookie 文件、注入到临时 data store 的旧路径
/// （见 `BrowserCookieReader.swift` 顶部说明）——只保留 App 自有会话这一种模式。
///
/// **线程约束**：WKWebView 必须在 main thread 创建与交互；本类用 `@MainActor`
/// 强制。调用方（`SubscriptionExpiryResolver`）也在 main actor 上，所以 `await`
/// 是 no-op actor 切换。
///
/// **超时**：独立 Task 计时，到点调 `webView.stopLoading()` 并抛
/// `QuotaFetchError.transient`。
///
/// **风险点**：
/// - Cloudflare / reCAPTCHA 挑战可能让页面永远不进入 didFinish，超时兜底；
/// - 某些 SPA 需要 network idle 才能完整渲染，本类只等 didFinish，调用方
///   在 `harvester.extract` 之前可以 sleep 一下（实际看效果再说）。
@MainActor
final class WKWebViewHeadlessLoader {
    /// didFinish 后再等这么久才提取 outerHTML：hash 路由 SPA（chatgpt.com /
    /// claude.ai 等）在 didFinish 时目标面板往往还没被 JS 渲染出来。
    private let settleDelay: TimeInterval

    init(settleDelay: TimeInterval = 2.0) {
        self.settleDelay = settleDelay
    }

    /// App 自有会话模式：使用 `WKWebsiteDataStore.default()` 里的登录态
    /// （由 `WebAuthorizationController` 的一次性 WebView 登录写入），
    /// 完全不读浏览器 Cookie、不触碰 Keychain。
    ///
    /// - Returns: 渲染后的 outerHTML；default store 没有该域 cookie 时抛
    ///   `.missingCredentials`（调用方可降级到浏览器 Cookie 路径）。
    static func appSessionHasCookies(for domains: [String]) async -> Bool {
        let cookies = await WKWebsiteDataStore.default().httpCookieStore.allCookies()
        return cookies.contains { cookie in
            let normalized = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
            return domains.contains { normalized == $0 || normalized.hasSuffix("." + $0) }
        }
    }

    func loadUsingAppSession(
        url: URL,
        cookieDomains: [String],
        timeout: TimeInterval,
        identifier: String
    ) async throws -> String {
        guard await Self.appSessionHasCookies(for: cookieDomains) else {
            throw QuotaFetchError.missingCredentials(detail: "App 内 WebView 尚未授权")
        }
        NSLog("QuotaBar: [\(identifier)] loading \(url.absoluteString) with app session cookies")
        return try await loadPageSource(
            url: url,
            timeout: timeout,
            identifier: identifier
        )
    }

    private func loadPageSource(
        url: URL,
        timeout: TimeInterval,
        identifier: String
    ) async throws -> String {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        config.websiteDataStore = .default()

        let webView = WKWebView(frame: .zero, configuration: config)
        let delegate = LoaderDelegate(settleDelay: settleDelay)
        webView.navigationDelegate = delegate

        // 超时 Task：到点停 load + 抛 transient
        let timeoutTask = Task { @MainActor [weak webView, weak delegate] in
            try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
            guard !Task.isCancelled else { return }
            NSLog("QuotaBar: [\(identifier)] WKWebView 加载超时（\(Int(timeout))s）")
            webView?.stopLoading()
            delegate?.fail(with: QuotaFetchError.transient(
                detail: "WKWebView 加载超时（\(Int(timeout))s）"
            ))
        }

        defer {
            timeoutTask.cancel()
            webView.navigationDelegate = nil
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String, Error>) in
                delegate.continuation = continuation
                webView.load(URLRequest(url: url))
            }
        } onCancel: {
            Task { @MainActor in
                delegate.fail(with: QuotaFetchError.transient(detail: "WKWebView 加载被取消"))
            }
        }
    }
}

// MARK: - Navigation Delegate

@MainActor
private final class LoaderDelegate: NSObject, WKNavigationDelegate {
    var continuation: CheckedContinuation<String, Error>?
    private var resumed = false
    private let settleDelay: TimeInterval

    init(settleDelay: TimeInterval = 0) {
        self.settleDelay = settleDelay
    }

    func fail(with error: Error) {
        guard !resumed else { return }
        resumed = true
        continuation?.resume(throwing: error)
        continuation = nil
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        // SPA settle：didFinish 只代表初始文档加载完成，hash 路由页面的目标内容
        // 还要等 JS 异步渲染；延迟提取（超时 task 仍在守门，最坏走超时降级）。
        Task { @MainActor [weak self, weak webView] in
            guard let self else { return }
            if self.settleDelay > 0 {
                try? await Task.sleep(nanoseconds: UInt64(self.settleDelay * 1_000_000_000))
            }
            guard !self.resumed, let webView else { return }
            self.extractHTML(from: webView)
        }
    }

    private func extractHTML(from webView: WKWebView) {
        webView.evaluateJavaScript("document.documentElement.outerHTML") { [weak self] result, error in
            // evaluateJavaScript callback 不一定在 main thread，wrap 进 MainActor
            Task { @MainActor [weak self] in
                guard let self, !self.resumed else { return }
                self.resumed = true
                if let error {
                    self.continuation?.resume(throwing: QuotaFetchError.transient(
                        detail: "JS 提取失败: \(error.localizedDescription)"
                    ))
                } else if let html = result as? String {
                    self.continuation?.resume(returning: html)
                } else {
                    self.continuation?.resume(throwing: QuotaFetchError.transient(
                        detail: "JS 提取返回非 String"
                    ))
                }
                self.continuation = nil
            }
        }
    }

    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.fail(with: QuotaFetchError.transient(
                detail: "WKWebView 加载失败: \(error.localizedDescription)"
            ))
        }
    }

    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        Task { @MainActor in
            self.fail(with: QuotaFetchError.transient(
                detail: "WKWebView 加载失败: \(error.localizedDescription)"
            ))
        }
    }
}
