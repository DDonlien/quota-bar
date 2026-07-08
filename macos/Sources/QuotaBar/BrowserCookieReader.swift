import Foundation
import WebKit

/// 浏览器 Cookie 读取器抽象。
///
/// 2026-07-08 之前还有一个真实读取 Safari/Chrome/Firefox cookie 数据库的实现
/// （`FilesystemCookieReader`，基于 SweetCookieKit），但它一直被
/// `QUOTABAR_ENABLE_BROWSER_COOKIE` 环境变量挡着、没有任何 UI 能打开，对真实
/// 用户来说是不可达的死路径；核实后确认 `AppWebViewSessionCookieReader`
/// 覆盖同一批 provider/endpoint 且不需要 Full Disk Access / Keychain 弹窗，
/// 两者功能等价，已删除文件读取实现，只保留这一个协议和下面两个实现。
protocol BrowserCookieReader: Sendable {
    /// 读取与目标域匹配的 Cookie。
    ///
    /// - Parameter domains: 期望匹配的 cookie 域，例如 `["chatgpt.com", "openai.com"]`。
    /// - Returns: 匹配到的 `HTTPCookie` 列表。
    /// - Throws: 读取失败时抛出错误；空数组表示「没有可用登录态」。
    func readCookies(matching domains: [String]) async throws -> [HTTPCookie]
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