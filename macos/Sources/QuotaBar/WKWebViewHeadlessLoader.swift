import Foundation
import WebKit

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
