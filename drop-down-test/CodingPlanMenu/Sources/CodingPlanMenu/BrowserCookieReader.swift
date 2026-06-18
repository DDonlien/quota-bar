import Foundation

/// 浏览器 Cookie 读取器抽象。
///
/// 真实实现会从 Safari/Chrome 的 cookie 数据库里按 domain 过滤；
/// 测试中可注入返回固定 cookie 的实现，便于在沙盒/CI 环境跑通流程。
protocol BrowserCookieReader: Sendable {
    /// 读取与目标域匹配的 Cookie。
    ///
    /// - Parameter domains: 期望匹配的 cookie 域，例如 `["chatgpt.com", "openai.com"]`。
    /// - Returns: 匹配到的 `HTTPCookie` 列表。
    /// - Throws: 读取失败时抛出错误；空数组表示「没有可用登录态」。
    func readCookies(matching domains: [String]) async throws -> [HTTPCookie]
}

// MARK: - 文件系统读取器

/// 通过读取磁盘上的浏览器 Cookie 数据库来获取 cookie。
///
/// 现阶段只覆盖 Chrome 的 SQLite 路径：
/// `~/Library/Application Support/Google/Chrome/Default/Cookies`。
///
/// Safari 的 `Cookies.binarycookies` 是二进制 plist 格式，解析稍复杂，
/// 后续按需扩展。
///
/// **注意**：在 macOS 沙盒下读取其他 App 的数据需要 Full Disk Access；
/// 读不到时抛 `transient`，由 `QuotaAggregator` 决定降级策略。
final class FilesystemCookieReader: BrowserCookieReader, @unchecked Sendable {

    enum ReaderError: LocalizedError {
        case cookieStoreUnavailable(path: String)
        case databaseOpenFailed(path: String, underlying: String)
        case decryptionUnsupported

        var errorDescription: String? {
            switch self {
            case .cookieStoreUnavailable(let path):
                return "未找到浏览器 Cookie 数据库：\(path)"
            case .databaseOpenFailed(let path, let underlying):
                return "打开 Cookie 数据库失败（\(path)）：\(underlying)"
            case .decryptionUnsupported:
                return "当前 Chrome 数据库使用了系统 Keychain 加密，无法在用户态解密"
            }
        }
    }

    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func readCookies(matching domains: [String]) async throws -> [HTTPCookie] {
        let path = Self.chromeCookiesPath(fileManager: fileManager)
        guard fileManager.fileExists(atPath: path) else {
            throw ReaderError.cookieStoreUnavailable(path: path)
        }

        // 这里只验证路径存在并返回空结果，真正解析留给后续 PR。
        // 完整实现需调用 sqlite3 C API 解密 encrypted_value 列，
        // 当前阶段避免引入额外的 C 依赖。
        return try Self.parseChromeCookieStore(at: path, matching: domains)
    }

    static func chromeCookiesPath(fileManager: FileManager) -> String {
        let home = fileManager.homeDirectoryForCurrentUser
        return home
            .appendingPathComponent("Library/Application Support/Google/Chrome/Default/Cookies", isDirectory: false)
            .path
    }

    /// 占位解析：当前不真正解码加密的 encrypted_value，
    /// 只检测文件可读 + 包含匹配域的记录数。
    ///
    /// 后续 PR 会用 sqlite3 + Keychain 解密完整实现替换。
    /// 在那之前返回空数组，让 `BrowserCookieProvider` 走 `missingCredentials` 降级。
    private static func parseChromeCookieStore(at path: String, matching domains: [String]) throws -> [HTTPCookie] {
        guard FileManager.default.isReadableFile(atPath: path) else {
            throw ReaderError.databaseOpenFailed(path: path, underlying: "文件不可读")
        }
        // 占位：真实实现读取 cookies 表并按 host_key 过滤。
        _ = domains
        return []
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
