import Foundation

/// 读取 `ClaudeStatusLineHookInstaller` 写入的本地缓存文件，提取
/// `rate_limits.{five_hour,seven_day}`。
///
/// 这是 Claude 额度管线里成本最低的一层：纯文件读取，不需要网络请求、不需要
/// OAuth token、不碰 Keychain、不 spawn 子进程。代价是数据新鲜度依赖用户
/// 最近是否有过交互式 Claude Code 会话——缓存文件太旧时视为不可用，交给
/// 后续（配置文件 → API）层兜底，不把陈旧数字当成当前数字展示。
final class ClaudeStatusLineUsageProvider: QuotaProvider, @unchecked Sendable {
    let id = "claude-statusline"
    let kind: ProviderKind = .claude
    var displayName: String { kind.displayName }

    private let cachePath: String
    private let maxAge: TimeInterval
    private let dateProvider: () -> Date

    /// - Parameter maxAge: 缓存文件超过这个年龄视为陈旧、不可信；默认 6 小时，
    ///   与最短的额度窗口（five_hour）同量级，避免展示明显过期的数字。
    init(
        cachePath: String? = nil,
        maxAge: TimeInterval = 6 * 3600,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.cachePath = cachePath ?? ClaudeStatusLineHookInstaller.shared.cachePath
        self.maxAge = maxAge
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let url = URL(fileURLWithPath: cachePath)
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: url.path),
              let modifiedAt = attributes[.modificationDate] as? Date
        else {
            throw QuotaFetchError.sourceUnavailable(detail: "未找到 Claude statusLine 缓存（未启用或还没跑过一次 claude 会话）")
        }
        guard fetchedAt.timeIntervalSince(modifiedAt) <= maxAge else {
            throw QuotaFetchError.sourceUnavailable(detail: "Claude statusLine 缓存已过期（超过 \(Int(maxAge / 3600))小时未更新，请打开一次 claude 会话刷新）")
        }
        guard let data = try? Data(contentsOf: url) else {
            throw QuotaFetchError.transient(detail: "无法读取 Claude statusLine 缓存")
        }
        guard let windows = Self.parseRateLimits(data), !windows.isEmpty else {
            throw QuotaFetchError.sourceUnavailable(detail: "Claude statusLine 缓存里没有 rate_limits 数据")
        }

        return ProviderSnapshot(
            kind: .claude,
            availability: .available,
            quotas: windows,
            monthlyPrice: nil,
            fetchedAt: fetchedAt
        )
    }

    /// statusLine payload 形状（经 ping-island `ClaudeUsageLoader` 交叉验证）：
    /// ```json
    /// {"rate_limits": {
    ///   "five_hour": {"used_percentage": 42, "resets_at": 1760000000},
    ///   "seven_day": {"utilization": 23, "resets_at": "2026-02-09T12:00:00Z"}
    /// }, "model": {"display_name": "Claude Opus 4.6"}, ...}
    /// ```
    /// `used_percentage`/`utilization` 是别名（同一含义，不同 Claude Code 版本
    /// 用过不同字段名）；`resets_at` 可能是 epoch 数字、ISO8601 字符串或 null。
    static func parseRateLimits(_ data: Data) -> [QuotaWindow]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let rateLimits = json["rate_limits"] as? [String: Any]
        else {
            return nil
        }

        // 跟 DashboardEndpoints.ClaudeUsageWindowParser 同一条规则：five_hour/seven_day
        // 只是时间维度，不是不同 scope，title 留空以跟 Codex 展示一致。
        var windows: [QuotaWindow] = []
        if let window = makeWindow(from: rateLimits["five_hour"] as? [String: Any], title: "", periodSeconds: 5 * 3600) {
            windows.append(window)
        }
        if let window = makeWindow(from: rateLimits["seven_day"] as? [String: Any], title: "", periodSeconds: 7 * 86400) {
            windows.append(window)
        }
        return windows.isEmpty ? nil : windows
    }

    private static func makeWindow(from dict: [String: Any]?, title: String, periodSeconds: TimeInterval) -> QuotaWindow? {
        guard let dict,
              let usedPercentage = number(dict["used_percentage"]) ?? number(dict["utilization"])
        else { return nil }
        let remainingFraction = max(0, min(1, 1 - usedPercentage / (usedPercentage > 1 ? 100 : 1)))
        let resetsAt = date(dict["resets_at"])
        let refreshText = resetsAt.map { QuotaResetText.description(for: $0) } ?? "重置时间未知"
        return QuotaWindow(
            title: title,
            remainingFraction: remainingFraction,
            refreshDescription: refreshText,
            resetsAt: resetsAt,
            periodSeconds: periodSeconds,
            subscriptionGroup: ProviderKind.claude.rawValue
        )
    }

    private static func number(_ raw: Any?) -> Double? {
        if let n = raw as? NSNumber { return n.doubleValue }
        if let s = raw as? String { return Double(s) }
        return nil
    }

    private static func date(_ raw: Any?) -> Date? {
        if let n = raw as? NSNumber { return Date(timeIntervalSince1970: n.doubleValue) }
        guard let s = raw as? String else { return nil }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = withFraction.date(from: s) { return d }
        return ISO8601DateFormatter().date(from: s)
    }
}
