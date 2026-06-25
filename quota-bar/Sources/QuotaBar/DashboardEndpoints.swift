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
        var method: String = "GET"
        var body: Data?
        var headers: [String: String] = [:]
        var followUpURL: (@Sendable (Data) -> URL?)?
        let parser: DashboardParser
        /// 如果指定了此 cookie 名称，`BrowserCookieProvider` 会从读取到的 cookie 中
        /// 提取该名称的值，作为 `Authorization: Bearer <value>` 发送，而不是
        /// 传统的 `Cookie:` header。适用于 Kimi 等把 auth token 放在 cookie 中
        /// 但 API 要求 Bearer 认证的场景。
        var bearerTokenCookieName: String? = nil
    }

    static func endpoint(for kind: ProviderKind) -> Endpoint? {
        switch kind {
        case .codex, .openai:
            return Endpoint(
                url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
                parser: CodexDashboardParser()
            )
        case .claude:
            return Endpoint(
                url: URL(string: "https://claude.ai/api/organizations")!,
                followUpURL: ClaudeDashboardParser.usageURL(from:),
                parser: ClaudeDashboardParser()
            )
        case .minimax:
            // MiniMax Web Coding Plan dashboard，用 minimax.chat 登录态 cookie。
            // 该路径可能仍受 Cloudflare / 签名策略影响，失败时 pipeline 会安全降级。
            return Endpoint(
                url: URL(string: "https://api.minimax.chat/v1/api/openplatform/coding_plan/remains")!,
                parser: MiniMaxDashboardParser()
            )
        case .kimi:
            return Endpoint(
                url: URL(string: "https://www.kimi.com/apiv2/kimi.gateway.membership.v2.MembershipService/GetSubscriptionStat")!,
                method: "POST",
                body: Data("{}".utf8),
                headers: [
                    "Content-Type": "application/json",
                    "Origin": "https://www.kimi.com",
                    "Referer": "https://www.kimi.com/"
                ],
                parser: KimiSubscriptionStatParser(),
                bearerTokenCookieName: "kimi-auth"
            )
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
    /// 从响应数据提取订阅档位；默认 nil，由 ProviderPricing 或 UI 安全降级。
    func parseTier(data: Data) -> String?
    /// 从响应数据提取已知订阅价格；默认 nil，避免无依据地猜价格。
    func parseMonthlyPrice(data: Data) -> String?
}

extension DashboardParser {
    func parseTier(data: Data) -> String? { nil }
    func parseMonthlyPrice(data: Data) -> String? { nil }
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
        let rateLimit = (json["rate_limit"] as? [String: Any]) ?? json
        var windows: [QuotaWindow] = []

        // Codex 5h + 周额度属于同一订阅组，共享额度，任一归零即全废。
        if let primary = pickWindow(in: rateLimit, names: ["five_hour", "primary_window", "five_hour_limit"]),
           let window = makeWindow(from: primary, title: "") {
            windows.append(window)
        }
        if let secondary = pickWindow(in: rateLimit, names: ["weekly", "secondary_window", "weekly_limit"]),
           let window = makeWindow(from: secondary, title: "") {
            windows.append(window)
        }

        // 按"最短订阅周期优先"排序（5小时 < 周），UI 层会再 sort 一遍保证一致性。
        windows.sort { ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude) }

        return windows.isEmpty ? nil : windows
    }

    func parseTier(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        // 顶层 plan_type
        let planType = json["plan_type"] as? String
            ?? json["planType"] as? String
            ?? json["plan"] as? String
            ?? json["subscription"] as? String
            ?? json["tier"] as? String
        // 嵌套在 account / user 中
        if planType == nil {
            if let account = json["account"] as? [String: Any] {
                return account["plan_type"] as? String
                    ?? account["planType"] as? String
                    ?? account["plan"] as? String
                    ?? account["tier"] as? String
                    ?? account["subscription"] as? String
            }
            if let user = json["user"] as? [String: Any] {
                return user["plan_type"] as? String
                    ?? user["planType"] as? String
                    ?? user["plan"] as? String
                    ?? user["tier"] as? String
                    ?? user["subscription"] as? String
            }
        }
        return planType.flatMap { ProviderPricing.normalizedTier($0) }
    }

    private func pickWindow(in rateLimit: [String: Any], names: [String]) -> [String: Any]? {
        for name in names {
            if let dict = rateLimit[name] as? [String: Any] {
                return dict
            }
        }
        return nil
    }

    private func makeWindow(from dict: [String: Any], title: String) -> QuotaWindow? {
        let usedPercent = (dict["used_percent"] as? NSNumber)?.doubleValue
            ?? (dict["percent_used"] as? NSNumber)?.doubleValue
            ?? (dict["usage_percent"] as? NSNumber)?.doubleValue
            ?? (dict["usage"] as? NSNumber)?.doubleValue
        guard let usedPercent else { return nil }
        let remainingFraction = max(0, min(1, 1.0 - usedPercent / 100.0))

        let periodSeconds: TimeInterval? = {
            if let raw = (dict["limit_window_seconds"] as? NSNumber)?.doubleValue
                ?? (dict["window_seconds"] as? NSNumber)?.doubleValue {
                return raw
            }
            // 从标题推断兜底（"5小时额度" / "周额度"）
            if title.contains("5小时") { return 5 * 3600 }
            if title.contains("周") { return 7 * 86400 }
            if title.contains("天") { return 86400 }
            return nil
        }()

        let resetAt: Date? = {
            if let raw = (dict["reset_at"] as? NSNumber)?.doubleValue {
                return Date(timeIntervalSince1970: raw)
            }
            if let str = dict["reset_at"] as? String,
               let raw = TimeInterval(str) {
                return Date(timeIntervalSince1970: raw)
            }
            return nil
        }()

        let refreshText: String = {
            guard let resetAt else { return "刷新时间未知" }
            return QuotaResetText.description(for: resetAt)
        }()

        return QuotaWindow(
            title: title,
            remainingFraction: remainingFraction,
            refreshDescription: refreshText,
            resetsAt: resetAt,
            periodSeconds: periodSeconds,
            // Codex 是单一订阅：5h + 周窗口共享同一订阅组
            subscriptionGroup: ProviderKind.codex.rawValue
        )
    }
}

// MARK: - Claude Dashboard 解析

/// Claude dashboard 需要两个步骤：
/// 1. `GET /api/organizations` → `[{uuid, name, capabilities, ...}]`
/// 2. `GET /api/organizations/{uuid}/usage` → `[{utilization, resets_at}, ...]`
struct ClaudeDashboardParser: DashboardParser {
    static func usageURL(from data: Data) -> URL? {
        guard let json = try? JSONSerialization.jsonObject(with: data) else { return nil }
        let organizations: [[String: Any]]
        if let array = json as? [[String: Any]] {
            organizations = array
        } else if let dict = json as? [String: Any],
                  let array = dict["organizations"] as? [[String: Any]] {
            organizations = array
        } else {
            return nil
        }

        for org in organizations {
            let id = org["uuid"] as? String
                ?? org["id"] as? String
                ?? org["organization_uuid"] as? String
            if let id, !id.isEmpty {
                return URL(string: "https://claude.ai/api/organizations/\(id)/usage")
            }
        }
        return nil
    }

    func parse(data: Data) -> [QuotaWindow]? {
        guard let payload = try? JSONSerialization.jsonObject(with: data) else { return nil }
        let candidates = Self.flattenUsageCandidates(payload)
        let windows = candidates.compactMap(Self.makeWindow(from:))
        return windows.isEmpty ? nil : windows.sorted {
            ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude)
        }
    }

    private static func flattenUsageCandidates(_ payload: Any) -> [[String: Any]] {
        if let array = payload as? [[String: Any]] { return array }
        guard let dict = payload as? [String: Any] else { return [] }
        for key in ["usage", "usages", "limits", "rate_limits", "quota", "quotas"] {
            if let array = dict[key] as? [[String: Any]] { return array }
            if let nested = dict[key] as? [String: Any] { return flattenUsageCandidates(nested) }
        }
        return dict.values.flatMap { flattenUsageCandidates($0) }
    }

    private static func makeWindow(from dict: [String: Any]) -> QuotaWindow? {
        let title = dict["name"] as? String
            ?? dict["model"] as? String
            ?? dict["type"] as? String
            ?? dict["window"] as? String
            ?? "Claude 额度"

        let remainingFraction: Double?
        if let utilization = number(dict["utilization"]) ?? number(dict["usage_percent"]) {
            remainingFraction = 1 - utilization / (utilization > 1 ? 100 : 1)
        } else if let used = number(dict["used"]),
                  let limit = number(dict["limit"]),
                  limit > 0 {
            remainingFraction = 1 - used / limit
        } else if let remaining = number(dict["remaining"]),
                  let limit = number(dict["limit"]),
                  limit > 0 {
            remainingFraction = remaining / limit
        } else {
            remainingFraction = number(dict["remaining_fraction"])
                ?? number(dict["remainingFraction"])
        }
        guard let remainingFraction else { return nil }

        let resetsAt = date(dict["resets_at"])
            ?? date(dict["reset_at"])
            ?? date(dict["resetTime"])
        let periodSeconds = number(dict["window_seconds"])
            ?? number(dict["limit_window_seconds"])
        let refreshText = resetsAt.map { QuotaResetText.description(for: $0) } ?? "重置时间未知"

        return QuotaWindow(
            title: title,
            remainingFraction: remainingFraction,
            refreshDescription: refreshText,
            resetsAt: resetsAt,
            periodSeconds: periodSeconds
        )
    }

    private static func number(_ raw: Any?) -> Double? {
        if let n = raw as? NSNumber { return n.doubleValue }
        if let s = raw as? String { return Double(s) }
        return raw as? Double
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

// MARK: - Kimi Web GetUsages 解析

struct KimiDashboardParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        if let parsed = try? KimiUsageParser.parse(data: data, fetchedAt: Date()) {
            return parsed.windows
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        for key in ["data", "result", "usage", "payload"] {
            guard let nested = json[key] else { continue }
            if let data = try? JSONSerialization.data(withJSONObject: nested),
               let parsed = try? KimiUsageParser.parse(data: data, fetchedAt: Date()) {
                return parsed.windows
            }
        }
        return nil
    }

    func parseTier(data: Data) -> String? {
        if let parsed = try? KimiUsageParser.parse(data: data, fetchedAt: Date()) {
            return parsed.tier
        }
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        for key in ["data", "result", "usage", "payload"] {
            guard let nested = json[key],
                  let nestedData = try? JSONSerialization.data(withJSONObject: nested),
                  let parsed = try? KimiUsageParser.parse(data: nestedData, fetchedAt: Date())
            else { continue }
            return parsed.tier
        }
        return nil
    }
}

// MARK: - Kimi Subscription Stat 解析（Web 端额度）

/// 解析 `https://www.kimi.com/apiv2/kimi.gateway.membership.v2.MembershipService/GetSubscriptionStat`
/// 的响应，该端点同时返回 Kimi Work 月度额度和 Kimi Code 速率限制额度。
///
/// 响应结构：
/// ```json
/// {
///   "ratelimitCode5h": { "enabled": true, "resetTime": "..." },
///   "ratelimitCode7d": { "ratio": 0.70, "enabled": true, "resetTime": "..." },
///   "subscriptionBalance": {
///     "amountUsedRatio": 0.62,
///     "kimiCodeUsedRatio": 0.15,
///     "expireTime": "..."
///   }
/// }
/// ```
struct KimiSubscriptionStatParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let fetchedAt = Date()
        var windows: [QuotaWindow] = []

        // Work 月度额度：从 subscriptionBalance.amountUsedRatio 推算
        if let balance = json["subscriptionBalance"] as? [String: Any],
           let amountUsedRatio = parseNum(balance["amountUsedRatio"]) {
            let remainingFraction = max(0, min(1, 1 - amountUsedRatio))
            let expireTime = parseDate(balance["expireTime"])
            let refreshText = expireTime.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"
            windows.append(QuotaWindow(
                title: "Work",
                remainingFraction: remainingFraction,
                refreshDescription: refreshText,
                resetsAt: expireTime,
                periodSeconds: 30 * 86400,
                scope: "work",
                // Kimi 是单一订阅：Code 5h/Code 周/Work 月共享额度，任一归零即全废
                subscriptionGroup: ProviderKind.kimi.rawValue
            ))
        }

        // Code 7天额度
        if let ratelimitCode7d = json["ratelimitCode7d"] as? [String: Any],
           let ratio = parseNum(ratelimitCode7d["ratio"]) {
            let remainingFraction = max(0, min(1, 1 - ratio))
            let resetTime = parseDate(ratelimitCode7d["resetTime"])
            let refreshText = resetTime.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"
            windows.append(QuotaWindow(
                title: "Code",
                remainingFraction: remainingFraction,
                refreshDescription: refreshText,
                resetsAt: resetTime,
                periodSeconds: 7 * 86400,
                scope: "code",
                subscriptionGroup: ProviderKind.kimi.rawValue
            ))
        }

        // Code 5小时额度
        if let ratelimitCode5h = json["ratelimitCode5h"] as? [String: Any],
           (ratelimitCode5h["enabled"] as? Bool) == true {
            let resetTime = parseDate(ratelimitCode5h["resetTime"])
            let remainingFraction: Double = {
                if let ratio = parseNum(ratelimitCode5h["ratio"]) {
                    return max(0, min(1, 1 - ratio))
                }
                return 1.0
            }()
            let refreshText = resetTime.map { QuotaResetText.description(for: $0, relativeTo: fetchedAt) } ?? "重置时间未知"
            windows.append(QuotaWindow(
                title: "Code",
                remainingFraction: remainingFraction,
                refreshDescription: refreshText,
                resetsAt: resetTime,
                periodSeconds: 5 * 3600,
                scope: "code",
                subscriptionGroup: ProviderKind.kimi.rawValue
            ))
        }

        return windows.isEmpty ? nil : windows
    }

    func parseTier(data: Data) -> String? {
        // GetSubscriptionStat 不返回 tier，不猜测，让 UI 显示 provider 名称即可。
        return nil
    }

    private func parseNum(_ value: Any?) -> Double? {
        if let n = value as? NSNumber { return n.doubleValue }
        if let s = value as? String, let n = Double(s) { return n }
        return nil
    }

    private func parseDate(_ raw: Any?) -> Date? {
        guard let s = raw as? String else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: s) { return d }
        let isoFallback = ISO8601DateFormatter()
        isoFallback.formatOptions = [.withInternetDateTime]
        return isoFallback.date(from: s)
    }
}

// MARK: - MiniMax Coding Plan 解析

/// 解析 `https://api.minimaxi.com/v1/coding_plan/remains` 响应：
/// ```json
/// {
///   "model_remains": [{"model_name": "MiniMax-M2", "remains": 500}, ...],
///   "current_package_name": "Plus",
///   "current_package_id": 1,
///   "remains": ["unlimited" | 500],
///   "tool_remains": [...],
///   "base_resp": {"status_code": 0, "status_msg": "success"}
/// }
/// ```
///
/// 注意：MiniMax 响应里**没有传统意义的 5h/周额度**，而是按 model 维度给出剩余
/// 调用次数。`remains` 数组（顶层）通常对应单一主套餐剩余；`model_remains[]`
/// 是各 model 的剩余配额。我们把每个 model 渲染成 1 个 QuotaWindow。
struct MiniMaxDashboardParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // status_code != 0 → API 失败（cloudflare 拦截 / cookie 过期等）
        if let baseResp = json["base_resp"] as? [String: Any],
           let statusCode = (baseResp["status_code"] as? NSNumber)?.intValue,
           statusCode != 0
        {
            return nil
        }

        var windows: [QuotaWindow] = []

        // 1. current_package_name 作为顶层"主套餐"剩余（如果有数字）
        if let mainRemains = json["remains"] as? [Any],
           let numeric = mainRemains.compactMap({ $0 as? NSNumber }).first
        {
            let fraction = max(0, min(1, numeric.doubleValue / 1000.0))  // 经验值
            windows.append(QuotaWindow(
                title: json["current_package_name"] as? String ?? "Coding Plan",
                remainingFraction: fraction,
                refreshDescription: "Coding Plan 主套餐",
                periodSeconds: 30 * 86400  // 月度
            ))
        }

        // 2. model_remains[] 每个 model 一个 QuotaWindow
        if let modelRemains = json["model_remains"] as? [[String: Any]] {
            for entry in modelRemains {
                guard let name = entry["model_name"] as? String,
                      let remains = (entry["remains"] as? NSNumber)?.doubleValue
                else { continue }
                // 经验阈值：每 model 单月可用 1000 次，超过 1.0 上限按 1.0 显示
                let fraction = max(0, min(1, remains / 1000.0))
                windows.append(QuotaWindow(
                    title: name,
                    remainingFraction: fraction,
                    refreshDescription: "Coding Plan",
                    periodSeconds: 30 * 86400
                ))
            }
        }

        return windows.isEmpty ? nil : windows
    }

    func parseTier(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let packageName = json["current_package_name"] as? String,
              !packageName.isEmpty
        else { return nil }
        return ProviderPricing.normalizedTier(packageName) ?? packageName
    }

    func parseMonthlyPrice(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let packageName = json["current_package_name"] as? String
        return Self.mapMonthlyPrice(packageName: packageName)
    }

    private static func mapMonthlyPrice(packageName: String?) -> String? {
        let name = packageName?.lowercased() ?? ""
        let priceUSD: Double?
        switch name {
        case "starter": priceUSD = 29
        case "plus": priceUSD = 49
        case "max": priceUSD = 119
        case "plus-highspeed", "plus_highspeed": priceUSD = 98
        case "max-highspeed", "max_highspeed": priceUSD = 199
        case "ultra-highspeed", "ultra_highspeed": priceUSD = 899
        default: priceUSD = nil
        }
        guard let priceUSD else { return nil }
        let cny = priceUSD * 7.25
        return String(format: "¥%.0f/月", cny)
    }
}

// MARK: - Kimi Subscription 解析（获取 tier 和价格）

/// 解析 `GetSubscription` 响应，提取 tier 名称和订阅价格。
/// 该端点同时返回 `subscription.goods.title`（Andante/Moderato/Allegretto/Allegro）
/// 和 `subscription.goods.amounts`（价格信息）。
struct KimiSubscriptionParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        // GetSubscription 主要用于获取 tier，额度从 GetSubscriptionStat 获取
        return nil
    }

    func parseTier(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let subscription = json["subscription"] as? [String: Any],
              let goods = subscription["goods"] as? [String: Any],
              let title = goods["title"] as? String
        else { return nil }
        return title
    }

    func parseMonthlyPrice(data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let subscription = json["subscription"] as? [String: Any],
              let goods = subscription["goods"] as? [String: Any],
              let amounts = goods["amounts"] as? [[String: Any]],
              let firstAmount = amounts.first,
              let priceInCents = firstAmount["priceInCents"] as? String,
              let price = Double(priceInCents)
        else { return nil }
        return String(format: "¥%.0f/月", price / 100.0)
    }
}
