import Foundation
import SweetCookieKit
import WebKit

/// 浏览器 Cookie 读取器抽象。
///
/// 真实实现会从 Safari/Chrome/Firefox 的 cookie 数据库里按 domain 过滤；
/// 测试中可注入返回固定 cookie 的实现，便于在沙盒/CI 环境跑通流程。
protocol BrowserCookieReader: Sendable {
    /// 读取与目标域匹配的 Cookie。
    ///
    /// - Parameter domains: 期望匹配的 cookie 域，例如 `["chatgpt.com", "openai.com"]`。
    /// - Returns: 匹配到的 `HTTPCookie` 列表。
    /// - Throws: 读取失败时抛出错误；空数组表示「没有可用登录态」。
    func readCookies(matching domains: [String]) async throws -> [HTTPCookie]
}

// MARK: - SweetCookieKit 适配器

/// 通过 SweetCookieKit 从系统安装的浏览器读取 Cookie。
///
/// 行为：
/// 1. 用 `BrowserCookieClient` 枚举所有受支持浏览器（按 `Browser.defaultImportOrder`）；
/// 2. 在每个浏览器的每个 profile 里按 domain 过滤；
/// 3. 命中后合并去重，返回 `HTTPCookie` 列表。
///
/// 错误映射：
/// - `accessDenied` → `PrivacyAccessDenied`，由调用方决定是否引导用户授权；
/// - `notFound` → `CookieStoreUnavailable`；
/// - `loadFailed` → 透传 detail。
final class FilesystemCookieReader: BrowserCookieReader, @unchecked Sendable {

    enum ReaderError: LocalizedError {
        case cookieStoreUnavailable(browser: String)
        case privacyAccessDenied(browser: String, hint: String)
        case loadFailed(browser: String, detail: String)

        var errorDescription: String? {
            switch self {
            case .cookieStoreUnavailable(let browser):
                return "\(browser) 未安装或未登录"
            case .privacyAccessDenied(_, let hint):
                return "缺少 Full Disk Access 权限：\(hint)"
            case .loadFailed(let browser, let detail):
                return "\(browser) Cookie 读取失败：\(detail)"
            }
        }
    }

    private let client: BrowserCookieClient
    private let preferredBrowsers: [Browser]

    init(
        client: BrowserCookieClient = BrowserCookieClient(),
        preferredBrowsers: [Browser] = Browser.defaultImportOrder
    ) {
        self.client = client
        self.preferredBrowsers = preferredBrowsers
    }

    func readCookies(matching domains: [String]) async throws -> [HTTPCookie] {
        guard !domains.isEmpty else { return [] }

        let query = BrowserCookieQuery(
            domains: domains,
            domainMatch: .suffix,
            includeExpired: false
        )

        var collected: [HTTPCookie] = []
        var seen = Set<String>()
        var lastAccessDenied: ReaderError?

        // SweetCookieKit 的 `client.cookies(...)` 是同步文件 I/O，
        // 在 Codex.app / Edge.app 等 Chromium-based 浏览器上偶尔会 hang。
        // 用 DispatchQueue 异步包装（让同步调用在 background queue 执行），
        // 主线程用 continuation 等待 + withCheckedContinuation + race timeout。
        for browser in preferredBrowsers {
            let perBrowserTimeout: TimeInterval = 2
            do {
                let cookies = try await readCookiesForBrowser(
                    browser: browser,
                    query: query,
                    timeout: perBrowserTimeout
                )
                for cookie in cookies {
                    let key = "\(cookie.domain)|\(cookie.name)"
                    if seen.insert(key).inserted {
                        collected.append(cookie)
                    }
                }
                if !cookies.isEmpty { return collected }
            } catch let error as BrowserCookieError {
                switch error {
                case .accessDenied(_, let hint):
                    lastAccessDenied = .privacyAccessDenied(browser: browser.displayName, hint: hint)
                    continue
                case .notFound:
                    continue
                case .loadFailed:
                    continue
                }
            } catch {
                // 超时 / 其他 → 跳过这个浏览器
                continue
            }
        }

        if !collected.isEmpty {
            return collected
        }

        if let lastAccessDenied {
            throw lastAccessDenied
        }

        throw ReaderError.cookieStoreUnavailable(browser: preferredBrowsers.first?.displayName ?? "browser")
    }

    /// 单个浏览器的 cookie 读取（带 timeout 兜底）。
    /// 把同步 SweetCookieKit 调用丢到 DispatchQueue.global，让 timeout 能在主线程真正生效。
    private func readCookiesForBrowser(
        browser: Browser,
        query: BrowserCookieQuery,
        timeout: TimeInterval
    ) async throws -> [HTTPCookie] {
        try await withThrowingTaskGroup(of: [HTTPCookie]?.self) { group in
            // 后台 queue 跑同步 cookies 调用
            group.addTask {
                try await withCheckedThrowingContinuation { (cont: CheckedContinuation<[HTTPCookie], Error>) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            let cookies = try self.client.cookies(matching: query, in: browser)
                            cont.resume(returning: cookies)
                        } catch {
                            cont.resume(throwing: error)
                        }
                    }
                }
            }
            // timeout task
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw ReaderError.loadFailed(
                    browser: browser.displayName,
                    detail: "读取超时（\(Int(timeout))s）"
                )
            }
            // 第一个完成的胜出
            guard let first = try await group.next() else { return [] }
            group.cancelAll()
            return first ?? []
        }
    }

    /// 返回当前用户在系统里实际有 cookie store 的浏览器。
    /// 用于 UI 提示用户「去这些浏览器里登录」。
    func availableBrowsers() -> [Browser] {
        preferredBrowsers.filter { !client.stores(for: $0).isEmpty }
    }
}

// MARK: - App 自有 WebView 会话读取器（分层获取的最后一层）

/// 从 `WKWebsiteDataStore.default()` 读取 Cookie —— 该 store 由
/// `WebAuthorizationController` 的一次性 App 内 WebView 登录写入。
///
/// 特性：
/// - 不读浏览器文件、不碰 Keychain，天然无弹窗、无 FDA 依赖；
/// - 用户在 App 内 WebView 登录一次后，登录态持久保存，之后永久静默复用；
/// - 作为每个 provider 额度管线的**最后一层**（本地 API/RPC → CLI →
///   浏览器 Cookie → WebView 会话），与 `BrowserCookieProvider` 组合即可
///   复用全部 dashboard endpoint / parser 逻辑。
final class AppWebViewSessionCookieReader: BrowserCookieReader, @unchecked Sendable {

    /// Cookie 提供者，默认读 `WKWebsiteDataStore.default()`；测试可注入。
    private let cookiesProvider: @Sendable () async -> [HTTPCookie]

    init(cookiesProvider: (@Sendable () async -> [HTTPCookie])? = nil) {
        self.cookiesProvider = cookiesProvider ?? {
            await Task { @MainActor in
                await WKWebsiteDataStore.default().httpCookieStore.allCookies()
            }.value
        }
    }

    func readCookies(matching domains: [String]) async throws -> [HTTPCookie] {
        guard !domains.isEmpty else { return [] }
        let all = await cookiesProvider()
        let now = Date()
        return all.filter { cookie in
            if let expires = cookie.expiresDate, expires < now { return false }
            let normalized = cookie.domain.hasPrefix(".") ? String(cookie.domain.dropFirst()) : cookie.domain
            return domains.contains { target in
                normalized == target || normalized.hasSuffix("." + target)
            }
        }
    }
}

// MARK: - 内存读取器（测试 / 调试用）

/// 写死在内存里的 Cookie 读取器，便于在沙盒/CI 环境跑通流程。
struct InMemoryCookieReader: BrowserCookieReader {
    let cookies: [HTTPCookie]

    init(cookies: [HTTPCookie]) {
        self.cookies = cookies
    }

    func readCookies(matching domains: [String]) async throws -> [HTTPCookie] {
        cookies.filter { cookie in
            guard let cookieDomain = Optional(cookie.domain) else { return false }
            let normalized = cookieDomain.hasPrefix(".") ? String(cookieDomain.dropFirst()) : cookieDomain
            return domains.contains { target in
                normalized == target || normalized.hasSuffix("." + target)
            }
        }
    }
}