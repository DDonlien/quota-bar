import Foundation

// MARK: - Dashboard 端点注册表

/// 每个 ProviderKind 对应的真实 dashboard 端点 + 解析器。
///
/// 端点来源：参考 CodexBar 的实现。
/// - Codex (chatgpt.com)：`https://chatgpt.com/backend-api/wham/usage`
/// - Claude (claude.ai)：先用 `/api/organizations` 拿 org_id，再 `/api/organizations/{orgId}/usage`
/// - Gemini：暂未对接（需要 Google Cloud 项目 ID + Vertex AI API key）
///
/// 当 endpoint 改变或被反爬时，解析器返回 nil，由 BrowserCookieProvider 走降级路径。
enum DashboardEndpoints {

    struct Endpoint {
        let url: URL
        let parser: DashboardParser
    }

    static func endpoint(for kind: ProviderKind) -> Endpoint? {
        switch kind {
        case .codex, .openai:
            return Endpoint(
                url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
                parser: CodexDashboardParser()
            )
        case .claude:
            // Claude 需要先发现 org id，单 endpoint 拿不到；这里先返 nil，让
            // BrowserCookieProvider 在缺 endpoint 时走"已登录但暂无数据"占位。
            return nil
        case .gemini:
            return nil
        default:
            return nil
        }
    }
}

// MARK: - 解析器协议

protocol DashboardParser: Sendable {
    /// 从响应数据解析出 quota 窗口；解析失败返回 nil（让上层降级）。
    func parse(data: Data) -> [QuotaWindow]?
}

// MARK: - Codex / OpenAI Wham Usage 解析

/// 解析 `https://chatgpt.com/backend-api/wham/usage` 返回的 JSON：
/// ```json
/// {
///   "plan_type": "plus",
///   "rate_limit": {
///     "primary_window":   { "used_percent": 25, "reset_at": 1735689600, "limit_window_seconds": 18000 },
///     "secondary_window": { "used_percent": 60, "reset_at": 1736294400, "limit_window_seconds": 604800 }
///   }
/// }
/// ```
struct CodexDashboardParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        guard let rateLimit = json["rate_limit"] as? [String: Any] else {
            return nil
        }
        var windows: [QuotaWindow] = []

        if let primary = rateLimit["primary_window"] as? [String: Any],
           let window = makeWindow(from: primary, title: "5小时额度") {
            windows.append(window)
        }
        if let secondary = rateLimit["secondary_window"] as? [String: Any],
           let window = makeWindow(from: secondary, title: "周额度") {
            windows.append(window)
        }

        return windows.isEmpty ? nil : windows
    }

    private func makeWindow(from dict: [String: Any], title: String) -> QuotaWindow? {
        guard let usedPercent = (dict["used_percent"] as? NSNumber)?.doubleValue else {
            return nil
        }
        let remainingFraction = max(0, min(1, 1.0 - usedPercent / 100.0))
        let resetAt: Date? = {
            guard let raw = (dict["reset_at"] as? NSNumber)?.doubleValue else { return nil }
            return Date(timeIntervalSince1970: raw)
        }()

        let refreshText: String = {
            guard let resetAt else { return "刷新时间未知" }
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.localizedString(for: resetAt, relativeTo: Date())
        }()

        return QuotaWindow(
            title: title,
            remainingFraction: remainingFraction,
            refreshDescription: refreshText,
            resetsAt: resetAt
        )
    }
}