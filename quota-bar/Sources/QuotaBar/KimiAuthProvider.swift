import Foundation

/// Kimi CLI / App OAuth + Dashboard 数据源。
///
/// 接入 Kimi CLI (`@moonshot-ai/kimi-code`) 使用的 managed-usage 接口：
/// 1. 读 `~/.kimi-code/credentials/kimi-code.json`（OAuth access_token + refresh_token）；
/// 2. token 距过期 < 30s 时主动 refresh：
///    `POST https://auth.kimi.com/api/oauth/token`
///    body=`client_id=...&grant_type=refresh_token&refresh_token=...`；
/// 3. `GET https://api.kimi.com/coding/v1/usages` 带 `Authorization: Bearer <token>`；
/// 4. 解析 `{user.membership.level, usage, limits[], parallel}` → `QuotaWindow`。
///
/// OAuth `client_id = 17e5f671-d194-4dfb-9706-5516cb48c098` 来自 Kimi CLI
/// `managed:kimi-code` provider 配置（与 JWT 内 `client_id` claim 一致）。
///
/// 同身份合并：access_token 即同一身份标识，OAuth 同一 sub 即视为同一用户。
final class KimiAuthProvider: QuotaProvider, @unchecked Sendable {

    let id = "kimi-auth"
    let kind: ProviderKind = .kimi
    var displayName: String { kind.displayName }

    private static let oauthClientId = "17e5f671-d194-4dfb-9706-5516cb48c098"
    private static let tokenURL = URL(string: "https://auth.kimi.com/api/oauth/token")!
    private static let usageURL = URL(string: "https://api.kimi.com/coding/v1/usages")!

    /// 与 Kimi CLI 的 `defaultRefreshThreshold` 一致：距过期 30s 前主动 refresh。
    private static let refreshLeadSeconds: TimeInterval = 30

    private let credentialsPath: String
    private let session: URLSession
    private let dateProvider: () -> Date

    /// 串行化 in-flight refresh，多个并发 fetchSnapshot 会复用同一个 refresh Task。
    /// 用 `os_unfair_lock` 而不是 `NSLock` —— 后者不能在 async 上下文里用。
    private var refreshTask: Task<Credentials, Error>?
    private var refreshLock = os_unfair_lock_s()

    init(
        credentialsPath: String? = nil,
        session: URLSession = .shared,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        if let credentialsPath {
            self.credentialsPath = credentialsPath
        } else {
            let kimiHome = ProcessInfo.processInfo.environment["KIMI_HOME"]
                ?? NSHomeDirectory() + "/.kimi-code"
            self.credentialsPath = kimiHome + "/credentials/kimi-code.json"
        }
        self.session = session
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let creds = try await ensureFreshCredentials()
        let parsed = try await fetchUsage(
            accessToken: creds.accessToken,
            timeout: timeout,
            fetchedAt: fetchedAt
        )
        return ProviderSnapshot(
            kind: .kimi,
            subscriptionTier: parsed.tier,
            availability: .available,
            quotas: parsed.windows,
            monthlyPrice: await ProviderPricing.localizedMonthlyPrice(kind: .kimi, tier: parsed.tier),
            fetchedAt: fetchedAt
        )
    }

    // MARK: - 凭证

    fileprivate struct Credentials: Sendable {
        let accessToken: String
        let refreshToken: String?
        let expiresAt: Date?
    }

    /// 读凭证 → 需要 refresh 则 refresh；多个并发调用复用同一个 refresh Task。
    private func ensureFreshCredentials() async throws -> Credentials {
        if let existing = currentRefreshTask() {
            return try await existing.value
        }

        guard let current = readCredentials() else {
            throw QuotaFetchError.missingCredentials(
                detail: "未找到 \(credentialsPath)，请先 kimi login"
            )
        }

        if !Self.shouldRefresh(current, now: dateProvider()) {
            return current
        }

        guard current.refreshToken?.isEmpty == false else {
            // 没 refresh_token，access_token 一旦过期就废了
            throw QuotaFetchError.missingCredentials(
                detail: "Kimi 凭证缺少 refresh_token，请重新 kimi login"
            )
        }

        let task = Task<Credentials, Error> { [weak self] in
            guard let self else {
                throw QuotaFetchError.sourceUnavailable(detail: "KimiAuthProvider 已释放")
            }
            return try await self.performRefresh(using: current)
        }
        setRefreshTask(task)

        defer { clearRefreshTask() }

        let refreshed = try await task.value
        try? persistCredentials(refreshed)
        return refreshed
    }

    /// 服务端返回 401 时调用：无视本地 expires_at 强制 refresh 一次。
    private func forceRefresh() async throws -> Credentials {
        if let existing = currentRefreshTask() {
            return try await existing.value
        }

        guard let current = readCredentials(),
              let rt = current.refreshToken, !rt.isEmpty
        else {
            throw QuotaFetchError.missingCredentials(
                detail: "Kimi OAuth 已过期，请重新 kimi login"
            )
        }

        let task = Task<Credentials, Error> { [weak self] in
            guard let self else {
                throw QuotaFetchError.sourceUnavailable(detail: "KimiAuthProvider 已释放")
            }
            return try await self.performRefresh(using: current)
        }
        setRefreshTask(task)

        defer { clearRefreshTask() }

        let refreshed = try await task.value
        try? persistCredentials(refreshed)
        return refreshed
    }

    private func performRefresh(using current: Credentials) async throws -> Credentials {
        guard let refreshToken = current.refreshToken, !refreshToken.isEmpty else {
            throw QuotaFetchError.missingCredentials(detail: "Kimi 缺少 refresh_token")
        }

        var request = URLRequest(url: Self.tokenURL, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        let body = "client_id=\(Self.oauthClientId)"
            + "&grant_type=refresh_token"
            + "&refresh_token=\(refreshToken)"
        request.httpBody = Data(body.utf8)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Kimi token endpoint 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300: break
        case 400, 401, 403:
            throw QuotaFetchError.missingCredentials(
                detail: "Kimi refresh_token 已失效，请重新 kimi login"
            )
        default:
            throw QuotaFetchError.transient(detail: "Kimi token endpoint HTTP \(http.statusCode)")
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let newAccess = json["access_token"] as? String, !newAccess.isEmpty
        else {
            throw QuotaFetchError.transient(detail: "Kimi token 响应缺 access_token")
        }
        let newRefresh = (json["refresh_token"] as? String).flatMap { $0.isEmpty ? nil : $0 }
            ?? current.refreshToken
        let expiresIn = (json["expires_in"] as? NSNumber)?.doubleValue
            ?? (json["expires_in"] as? Double)
            ?? 0
        let expiresAt: Date? = expiresIn > 0
            ? dateProvider().addingTimeInterval(expiresIn)
            : nil

        return Credentials(
            accessToken: newAccess,
            refreshToken: newRefresh,
            expiresAt: expiresAt
        )
    }

    // MARK: - 用量

    private func fetchUsage(
        accessToken: String,
        timeout: TimeInterval,
        fetchedAt: Date
    ) async throws -> KimiUsageParser.ParsedUsage {
        var request = URLRequest(url: Self.usageURL, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Kimi usage 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300: break
        case 401, 403:
            // 服务端撤销了当前 token —— 强制 refresh 后重试一次
            let refreshed = try await forceRefresh()
            if refreshed.accessToken != accessToken {
                return try await fetchUsage(
                    accessToken: refreshed.accessToken,
                    timeout: timeout,
                    fetchedAt: fetchedAt
                )
            }
            throw QuotaFetchError.missingCredentials(
                detail: "Kimi OAuth 已过期，请重新 kimi login"
            )
        default:
            throw QuotaFetchError.transient(detail: "Kimi usage HTTP \(http.statusCode)")
        }
        return try KimiUsageParser.parse(data: data, fetchedAt: fetchedAt)
    }

    // MARK: - 文件 IO

    private func readCredentials() -> Credentials? {
        let url = URL(fileURLWithPath: credentialsPath)
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        guard let access = json["access_token"] as? String, !access.isEmpty else { return nil }
        let refresh = (json["refresh_token"] as? String).flatMap { $0.isEmpty ? nil : $0 }
        var expiresAt: Date?
        if let exp = (json["expires_at"] as? NSNumber)?.doubleValue
            ?? (json["expires_at"] as? Double)
        {
            expiresAt = Date(timeIntervalSince1970: exp)
        }
        return Credentials(accessToken: access, refreshToken: refresh, expiresAt: expiresAt)
    }

    private func persistCredentials(_ c: Credentials) throws {
        var dict: [String: Any] = ["access_token": c.accessToken]
        if let rt = c.refreshToken { dict["refresh_token"] = rt }
        if let exp = c.expiresAt { dict["expires_at"] = exp.timeIntervalSince1970 }
        let data = try JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys])
        try data.write(to: URL(fileURLWithPath: credentialsPath), options: [.atomic])
    }

    private static func shouldRefresh(_ c: Credentials, now: Date) -> Bool {
        guard let exp = c.expiresAt else { return false }  // 没 expires_at：信任文件
        return exp.timeIntervalSince(now) < refreshLeadSeconds
    }

    // MARK: - Refresh 串行化

    private func currentRefreshTask() -> Task<Credentials, Error>? {
        os_unfair_lock_lock(&refreshLock)
        defer { os_unfair_lock_unlock(&refreshLock) }
        return refreshTask
    }

    private func setRefreshTask(_ task: Task<Credentials, Error>) {
        os_unfair_lock_lock(&refreshLock)
        refreshTask = task
        os_unfair_lock_unlock(&refreshLock)
    }

    private func clearRefreshTask() {
        os_unfair_lock_lock(&refreshLock)
        refreshTask = nil
        os_unfair_lock_unlock(&refreshLock)
    }
}

// MARK: - 响应解析

/// Kimi `/coding/v1/usages` 响应解析。
///
/// 新 schema（与 CLI 的 `parseManagedUsagePayload` 一致）：
/// ```json
/// {
///   "user": { "userId": "cn0m...", "membership": { "level": "LEVEL_TRIAL" } },
///   "usage": { "limit": "100", "used": "20", "remaining": "80",
///              "resetTime": "2026-06-23T14:33:09.132464Z" },
///   "limits": [
///     { "window": { "duration": 300, "timeUnit": "TIME_UNIT_MINUTE" },
///       "detail": { "limit": "100", "used": "100", "resetTime": "..." } }
///   ],
///   "parallel": { "limit": "10" },
///   "totalQuota": { "limit": "100", "remaining": "99" }
/// }
/// ```
enum KimiUsageParser {

    struct ParsedUsage: Sendable {
        let tier: String?
        let windows: [QuotaWindow]
    }

    static func parse(data: Data, fetchedAt: Date) throws -> ParsedUsage {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw QuotaFetchError.transient(detail: "无法解析 Kimi usage 响应（非 JSON）")
        }

        let tier = parseTier(json["user"] as? [String: Any], subType: json["subType"] as? String)
        let scope = parseScope(json["authentication"] as? [String: Any])

        var windows: [QuotaWindow] = []

        // 顶层 usage：周额度（基础周期窗口）。
        if let usage = json["usage"] as? [String: Any],
           let window = makeWindow(
               from: usage,
               title: "周额度",
               fetchedAt: fetchedAt,
               periodSeconds: 7 * 24 * 60 * 60,
               scope: scope
           )
        {
            windows.append(window)
        }

        // limits[]：速率限制（每条带 window.duration + window.timeUnit）。
        if let limits = json["limits"] as? [[String: Any]] {
            for item in limits {
                let windowSeconds = parseWindowSeconds(item)
                let label = limitLabel(item, fallbackSeconds: windowSeconds)
                let detail = item["detail"] as? [String: Any] ?? item
                if let window = makeWindow(
                    from: detail,
                    title: label,
                    fetchedAt: fetchedAt,
                    periodSeconds: windowSeconds,
                    scope: scope
                ) {
                    windows.append(window)
                }
            }
        }

        guard !windows.isEmpty else {
            throw QuotaFetchError.transient(detail: "Kimi usage 响应里没有任何额度窗口")
        }

        // 按"最短订阅周期优先"排序：速率限制窗口（秒数最小）放最前，
        // 周额度（无 window.duration 标记为最大）放最后。
        windows.sort { a, b in
            let sa = a.periodSeconds ?? .greatestFiniteMagnitude
            let sb = b.periodSeconds ?? .greatestFiniteMagnitude
            return sa < sb
        }

        return ParsedUsage(tier: tier, windows: windows)
    }

    /// 订阅名处理：subType 优先于 level，但保留 level 信息（subType=TYPE_PURCHASE +
    /// level=LEVEL_TRIAL 时显示「Trial（已购）」，让用户知道是 trial 期内付费的）。
    ///
    /// - `subType=TYPE_PURCHASE` + `level=LEVEL_TRIAL` → "Trial（已购）"
    /// - `subType=TYPE_PURCHASE` + 其他 level → "Paid"（已购买）
    /// - `subType=TYPE_FREE` → 用 level（"Trial" / "Free" / "Paid"）
    /// - API 不暴露 SKU 名（Andante / Moderato / Allegro），不要硬猜
    private static func parseTier(_ user: [String: Any]?, subType: String?) -> String? {
        let membership = user?["membership"] as? [String: Any]
        let level = membership?["level"] as? String

        if subType == "TYPE_PURCHASE" {
            // 已购买 — 但如果 level 还说 TRIAL，说明是 trial 期付费（套餐升级未生效），
            // 给用户更准确的提示，避免误以为已升级到正式付费档。
            if level == "LEVEL_TRIAL" {
                return "Trial（已购）"
            }
            return "Paid"
        }

        guard let level else { return nil }
        switch level {
        case "LEVEL_TRIAL": return "Trial"
        case "LEVEL_FREE": return "Free"
        case "LEVEL_PAID": return "Paid"
        default:
            let stripped = level.hasPrefix("LEVEL_") ? String(level.dropFirst(6)) : level
            return stripped.capitalized
        }
    }

    private static func parseWindowSeconds(_ item: [String: Any]) -> TimeInterval? {
        guard let window = item["window"] as? [String: Any],
              let duration = (window["duration"] as? NSNumber)?.doubleValue
                ?? (window["duration"] as? Double)
        else { return nil }
        let unitSeconds = parseUnitSeconds(window["timeUnit"] as? String)
        return duration * unitSeconds
    }

    private static func parseUnitSeconds(_ unit: String?) -> TimeInterval {
        switch unit {
        case "TIME_UNIT_SECOND": return 1
        case "TIME_UNIT_MINUTE": return 60
        case "TIME_UNIT_HOUR": return 3600
        case "TIME_UNIT_DAY": return 86400
        default: return 60  // 默认按分钟
        }
    }

    /// 把 window.duration 转成中文友好 label：5h / 30m / 1d。
    private static func limitLabel(_ item: [String: Any], fallbackSeconds: TimeInterval?) -> String {
        guard let window = item["window"] as? [String: Any],
              let duration = (window["duration"] as? NSNumber)?.intValue
                ?? (window["duration"] as? Int)
        else {
            return "速率限制"
        }
        let unit = window["timeUnit"] as? String ?? ""
        let compact = compactLabel(duration: duration, unit: unit)
        return "\(compact) 限速"
    }

    private static func compactLabel(duration: Int, unit: String) -> String {
        switch unit {
        case "TIME_UNIT_MINUTE":
            if duration >= 60, duration % 60 == 0 {
                return "\(duration / 60)h"
            }
            return "\(duration)m"
        case "TIME_UNIT_HOUR":
            return "\(duration)h"
        case "TIME_UNIT_DAY":
            return "\(duration)d"
        case "TIME_UNIT_SECOND":
            return "\(duration)s"
        default:
            return "\(duration)"
        }
    }

    private static func makeWindow(
        from dict: [String: Any],
        title: String,
        fetchedAt: Date,
        periodSeconds: TimeInterval?,
        scope: String?
    ) -> QuotaWindow? {
        let limit = parseNum(dict["limit"])
        let used = parseNum(dict["used"])
        let remaining = parseNum(dict["remaining"])

        guard let fraction = computeFraction(limit: limit, used: used, remaining: remaining) else {
            return nil
        }

        let resetsAt = parseResetTime(dict["resetTime"])
            ?? parseResetTime(dict["reset_at"])
        let refreshText: String
        if let resetsAt {
            refreshText = QuotaResetText.description(for: resetsAt, relativeTo: fetchedAt)
        } else if let periodSeconds, periodSeconds > 0, periodSeconds < .greatestFiniteMagnitude {
            refreshText = QuotaResetText.description(
                for: fetchedAt.addingTimeInterval(periodSeconds),
                relativeTo: fetchedAt
            )
        } else {
            refreshText = QuotaResetText.description(
                for: fetchedAt.addingTimeInterval(7 * 24 * 60 * 60),
                relativeTo: fetchedAt
            )
        }

        return QuotaWindow(
            title: title,
            remainingFraction: fraction,
            refreshDescription: refreshText,
            resetsAt: resetsAt,
            periodSeconds: periodSeconds,
            scope: scope
        )
    }

    /// 从 `authentication.scope` (e.g. "FEATURE_CODING") 映射到 scope 标签。
    private static func parseScope(_ auth: [String: Any]?) -> String? {
        guard let raw = auth?["scope"] as? String, !raw.isEmpty else { return nil }
        switch raw {
        case "FEATURE_CODING": return "code"
        case "FEATURE_WORK": return "work"
        default:
            let stripped = raw.hasPrefix("FEATURE_") ? String(raw.dropFirst(8)) : raw
            return stripped.lowercased()
        }
    }

    private static func computeFraction(limit: Double?, used: Double?, remaining: Double?) -> Double? {
        if let l = limit, l > 0, let u = used {
            return max(0, min(1, 1 - u / l))
        }
        if let l = limit, l > 0, let r = remaining {
            return max(0, min(1, r / l))
        }
        if let r = remaining, r >= 0, r <= 1 {
            return r
        }
        return nil
    }

    private static func parseNum(_ value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let s = value as? String, let n = Double(s) { return n }
        if let i = value as? Int { return Double(i) }
        return nil
    }

    private static func parseResetTime(_ raw: Any?) -> Date? {
        guard let s = raw as? String else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]
        return isoFallback.date(from: s)
    }
}