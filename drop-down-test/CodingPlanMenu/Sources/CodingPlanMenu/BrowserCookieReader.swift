import Foundation
import SweetCookieKit

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

        for browser in preferredBrowsers {
            do {
                let cookies = try client.cookies(matching: query, in: browser)
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

    /// 返回当前用户在系统里实际有 cookie store 的浏览器。
    /// 用于 UI 提示用户「去这些浏览器里登录」。
    func availableBrowsers() -> [Browser] {
        preferredBrowsers.filter { !client.stores(for: $0).isEmpty }
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