import Foundation
import SQLite3

/// 读取 Microsoft Edge 浏览器的 Cookie 数据库。
///
/// Edge 使用与 Chrome 相同的 SQLite 格式，只是路径不同：
/// `~/Library/Application Support/Microsoft Edge/Default/Cookies`
///
/// 作为 `BrowserCookieReader` 的实现，供 `BrowserCookieProvider` 使用。
struct EdgeCookieReader: BrowserCookieReader {

    private let cookiePath: String

    init(cookiePath: String? = nil) {
        if let path = cookiePath {
            self.cookiePath = path
        } else {
            let home = NSHomeDirectory()
            self.cookiePath = "\(home)/Library/Application Support/Microsoft Edge/Default/Cookies"
        }
    }

    func readCookies(matching domains: [String]) async throws -> [HTTPCookie] {
        guard FileManager.default.fileExists(atPath: cookiePath) else {
            throw ReaderError.cookieStoreUnavailable
        }

        // 复制数据库到临时位置（避免原文件被锁定）
        let tempPath = NSTemporaryDirectory() + "edge_cookies_\(UUID().uuidString).db"
        defer { try? FileManager.default.removeItem(atPath: tempPath) }

        try FileManager.default.copyItem(atPath: cookiePath, toPath: tempPath)

        var db: OpaquePointer?
        guard sqlite3_open(tempPath, &db) == SQLITE_OK, let database = db else {
            throw ReaderError.loadFailed(path: cookiePath, detail: "无法打开 SQLite 数据库")
        }
        defer { sqlite3_close(database) }

        // 查询匹配的 cookie
        // 注：当前 SQL 用 LIKE '%' 软匹配全部 host_key，域名硬过滤在下方结果循环里做；
        // 若将来要回到 SQL 层 IN (...) 过滤再补回 `domainPatterns` / `placeholders`。
        let query = "SELECT name, value, host_key, path, expires_utc, is_secure FROM cookies WHERE host_key LIKE ?"

        var cookies: [HTTPCookie] = []
        var stmt: OpaquePointer?

        guard sqlite3_prepare_v2(database, query, -1, &stmt, nil) == SQLITE_OK, let statement = stmt else {
            throw ReaderError.loadFailed(path: cookiePath, detail: "SQL 查询准备失败")
        }
        defer { sqlite3_finalize(statement) }

        // 绑定第一个参数（匹配任意域名）
        sqlite3_bind_text(statement, 1, "%", -1, nil)

        while sqlite3_step(statement) == SQLITE_ROW {
            guard let name = sqlite3_column_text(statement, 0).map({ String(cString: $0) }),
                  let value = sqlite3_column_text(statement, 1).map({ String(cString: $0) }),
                  let host = sqlite3_column_text(statement, 2).map({ String(cString: $0) }),
                  let path = sqlite3_column_text(statement, 3).map({ String(cString: $0) })
            else { continue }

            // 检查域名是否匹配
            let matched = domains.contains { domain in
                host.contains(domain) || domain.contains(host)
            }
            guard matched else { continue }

            let expiresUtc = sqlite3_column_int64(statement, 4)
            let isSecure = sqlite3_column_int(statement, 5) != 0

            // Chrome/Edge 的 expires_utc 是 1601-01-01 以来的微秒数
            // 转换为 Date：微秒 → 秒，然后减去 11644473600（Windows epoch 到 Unix epoch）
            let expiresDate: Date? = if expiresUtc > 0 {
                Date(timeIntervalSince1970: Double(expiresUtc) / 1_000_000 - 11_644_473_600)
            } else {
                nil
            }

            let properties: [HTTPCookiePropertyKey: Any] = [
                .name: name,
                .value: value,
                .domain: host,
                .path: path,
                .secure: isSecure,
                .expires: expiresDate as Any
            ]

            if let cookie = HTTPCookie(properties: properties) {
                cookies.append(cookie)
            }
        }

        return cookies
    }

    enum ReaderError: Error {
        case cookieStoreUnavailable
        case loadFailed(path: String, detail: String)
    }
}

// MARK: - 适配 BrowserCookieReader 协议

extension EdgeCookieReader.ReaderError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .cookieStoreUnavailable:
            return "Edge Cookie 数据库不存在"
        case .loadFailed(let path, let detail):
            return "读取 Edge Cookie 失败（\(path)）：\(detail)"
        }
    }
}
