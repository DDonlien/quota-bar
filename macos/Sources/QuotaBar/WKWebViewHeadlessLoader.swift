import Foundation
import WebKit

// MARK: - WKWebViewHeadlessLoader

/// macOS native WKWebView 包装，用于 headless 抓取订阅管理页。
///
/// 工作流（v0.6.0 起订阅到期日真实数据源）：
/// 1. 通过 `BrowserCookieReader` 读取目标域 cookies；
/// 2. 注入到 `WKHTTPCookieStore`（非持久 data store，**不污染**用户浏览器 cookie）；
/// 3. `WKWebView.load` 加载 URL；
/// 4. 等 `WKNavigationDelegate.didFinish` 回调；
/// 5. `evaluateJavaScript("document.documentElement.outerHTML")` 拿渲染后的 DOM 字符串。
///
/// **线程约束**：WKWebView 必须在 main thread 创建与交互；本类用 `@MainActor`
/// 强制。调用方（`BrowserCookieProvider` / `FetchPipeline` strategy）也在
/// main actor 上，所以 `await` 是 no-op actor 切换。
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
    private let cookieReader: BrowserCookieReader
    /// didFinish 后再等这么久才提取 outerHTML：hash 路由 SPA（chatgpt.com /
    /// claude.ai 等）在 didFinish 时目标面板往往还没被 JS 渲染出来。
    private let settleDelay: TimeInterval

    init(cookieReader: BrowserCookieReader, settleDelay: TimeInterval = 2.0) {
        self.cookieReader = cookieReader
        self.settleDelay = settleDelay
    }

    /// 加载订阅管理页并返回 `document.documentElement.outerHTML`。
    ///
    /// - Parameters:
    ///   - url: 目标订阅页 URL。
    ///   - kind: 用来决定从哪些域读 cookie（见 `ProviderKind.dashboardCookieDomains`）。
    ///   - timeout: 整体超时（含 cookie 读取 + 页面加载 + JS 提取）。
    ///   - identifier: 日志前缀，建议填 harvester 的 `identifier`。
    /// - Returns: 渲染后的 outerHTML。
    /// - Throws: `QuotaFetchError.missingCredentials` / `.permissionRequired` /
    ///           `.transient`。
    func load(
        url: URL,
        kind: ProviderKind,
        timeout: TimeInterval,
        identifier: String
    ) async throws -> String {
        try await load(
            url: url,
            cookieDomains: kind.dashboardCookieDomains,
            timeout: timeout,
            identifier: identifier
        )
    }

    /// 加载订阅管理页并返回 `document.documentElement.outerHTML`。
    ///
    /// 与 `load(url:kind:timeout:identifier:)` 相同，但 cookie 域由 caller 显式提供。
    /// 订阅过期日 source 可能和额度 dashboard 使用不同域名，例如 MiniMax 额度来自
    /// `minimax.chat`，订阅页在 `platform.minimaxi.com`。
    func load(
        url: URL,
        cookieDomains: [String],
        timeout: TimeInterval,
        identifier: String
    ) async throws -> String {
        let cookies: [HTTPCookie]
        do {
            cookies = try await cookieReader.readCookies(matching: cookieDomains)
        } catch let error as FilesystemCookieReader.ReaderError {
            switch error {
            case .privacyAccessDenied:
                throw QuotaFetchError.permissionRequired(detail: "读取浏览器 Cookie 需要 Full Disk Access")
            case .cookieStoreUnavailable:
                throw QuotaFetchError.missingCredentials(detail: "未发现已登录的浏览器")
            case .loadFailed(_, let detail):
                throw QuotaFetchError.transient(detail: detail)
            }
        }
        guard !cookies.isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "浏览器未登录")
        }

        NSLog("QuotaBar: [\(identifier)] loading \(url.absoluteString) with \(cookies.count) cookies")

        return try await loadPageSource(
            url: url,
            cookies: cookies,
            timeout: timeout,
            identifier: identifier
        )
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
            cookies: nil,
            timeout: timeout,
            identifier: identifier
        )
    }

    /// - Parameter cookies: 非 nil 时注入到一次性非持久 data store（浏览器 Cookie 模式）；
    ///   nil 时直接使用 `WKWebsiteDataStore.default()`（App 自有会话模式）。
    private func loadPageSource(
        url: URL,
        cookies: [HTTPCookie]?,
        timeout: TimeInterval,
        identifier: String
    ) async throws -> String {
        let config = WKWebViewConfiguration()
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        if let cookies {
            let dataStore = WKWebsiteDataStore.nonPersistent()
            config.websiteDataStore = dataStore
            for cookie in cookies {
                await dataStore.httpCookieStore.setCookie(cookie)
            }
        } else {
            config.websiteDataStore = .default()
        }

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
