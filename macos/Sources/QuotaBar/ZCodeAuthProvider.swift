import Foundation

final class ZCodeAuthProvider: QuotaProvider, @unchecked Sendable {
    let id = "zcode-auth"
    let kind: ProviderKind = .zcode
    var displayName: String { kind.displayName }

    private let configPaths: [String]
    private let session: URLSession
    private let environment: [String: String]
    private let dateProvider: () -> Date

    init(
        configPaths: [String] = [
            "~/.zcode/v2/config.json",
            "~/.zcode/v2/credentials.json",
            "~/.zcode/config.json",
            "~/.glm/config.json",
            "~/.bigmodel/config.json",
        ],
        session: URLSession = .shared,
        environment: [String: String] = ProcessInfo.processInfo.environment,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.configPaths = configPaths
        self.session = session
        self.environment = environment
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let config = try loadConfig()
        let url = try resolveQuotaURL(config: config)

        var request = URLRequest(url: url, timeoutInterval: timeout)
        request.httpMethod = "GET"
        request.setValue("Bearer \(config.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "Z Code quota 返回非 HTTP 响应")
        }
        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw QuotaFetchError.missingCredentials(detail: "Z Code API key 无效或已过期")
        default:
            throw QuotaFetchError.transient(detail: "Z Code quota HTTP \(http.statusCode)")
        }

        let parsed = try Self.parseQuotaLimitResponse(
            data: data,
            now: fetchedAt,
            fallbackPlanName: config.planName
        )
        guard !parsed.quotas.isEmpty else {
            throw QuotaFetchError.sourceUnavailable(detail: "Z Code 服务端未返回可渲染额度数值")
        }
        let tier = ProviderPricing.normalizedTier(parsed.planName ?? config.planName)
        return ProviderSnapshot(
            kind: .zcode,
            subscriptionTier: tier,
            availability: .available,
            quotas: parsed.quotas,
            monthlyPrice: parsed.monthlyPrice ?? config.monthlyPrice,
            fetchedAt: fetchedAt
        )
    }

    // MARK: - Config

    private struct Config {
        let apiKey: String
        let baseURL: String?
        let quotaURL: String?
        let planName: String?
        let monthlyPrice: String?
        let enabled: Bool
    }

    private func loadConfig() throws -> Config {
        var candidates = ConfigCandidates()

        for key in ["Z_AI_API_KEY", "ZAI_API_KEY", "BIGMODEL_API_KEY", "ZHIPUAI_API_KEY", "GLM_API_KEY"] {
            if let value = environment[key], !value.isEmpty {
                candidates.apiKeys.append(value)
            }
        }
        for key in ["Z_AI_API_HOST", "ZAI_API_BASE_URL", "BIGMODEL_BASE_URL", "GLM_BASE_URL"] {
            if let value = environment[key], !value.isEmpty {
                candidates.baseURLs.append(value)
            }
        }
        if let value = environment["Z_AI_QUOTA_URL"], !value.isEmpty {
            candidates.quotaURLs.append(value)
        }

        for rawPath in configPaths {
            let path = (rawPath as NSString).expandingTildeInPath
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let root = try? JSONSerialization.jsonObject(with: data) else {
                continue
            }
            candidates.merge(Self.extractCandidates(from: root, sourcePath: rawPath))
        }

        guard let apiKey = candidates.apiKeys.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw QuotaFetchError.missingCredentials(detail: "未找到 Z Code API key（~/.zcode/v2/config.json 或 credentials.json）")
        }

        return Config(
            apiKey: apiKey,
            baseURL: candidates.baseURLs.first,
            quotaURL: candidates.quotaURLs.first,
            planName: candidates.planNames.first,
            monthlyPrice: candidates.monthlyPrices.first,
            enabled: candidates.enabledFlags.first ?? false
        )
    }

    private func resolveQuotaURL(config: Config) throws -> URL {
        if let quotaURL = config.quotaURL,
           let url = URL(string: quotaURL) {
            return url
        }

        if let balanceURL = Self.zcodePlanBalanceURL(from: config.baseURL) {
            return balanceURL
        }

        let base = Self.quotaBaseURL(for: config) ?? Self.defaultBaseURL(for: config.planName)
        guard let root = Self.rootURLString(from: base),
              let url = URL(string: "\(root)/api/monitor/usage/quota/limit") else {
            throw QuotaFetchError.transient(detail: "Z Code API URL 无效")
        }
        return url
    }

    private struct ConfigCandidates {
        var apiKeys: [String] = []
        var baseURLs: [String] = []
        var quotaURLs: [String] = []
        var planNames: [String] = []
        var monthlyPrices: [String] = []
        var enabledFlags: [Bool] = []

        mutating func merge(_ other: ConfigCandidates) {
            apiKeys.append(contentsOf: other.apiKeys)
            baseURLs.append(contentsOf: other.baseURLs)
            quotaURLs.append(contentsOf: other.quotaURLs)
            planNames.append(contentsOf: other.planNames)
            monthlyPrices.append(contentsOf: other.monthlyPrices)
            enabledFlags.append(contentsOf: other.enabledFlags)
        }
    }

    private static func extractCandidates(from root: Any, sourcePath: String) -> ConfigCandidates {
        if let structured = extractStructuredProviderCandidates(from: root) {
            return structured
        }

        var candidates = ConfigCandidates()
        for entry in flattenStrings(root) {
            let key = entry.keyPath.lowercased()
            let value = entry.value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { continue }
            let lowerValue = value.lowercased()

            if lowerValue.contains("/api/monitor/usage/quota/limit"), URL(string: value) != nil {
                candidates.quotaURLs.append(value)
                continue
            }

            if URL(string: value) != nil,
               lowerValue.contains("z.ai") || lowerValue.contains("bigmodel.cn") {
                candidates.baseURLs.append(value)
                continue
            }

            if key.contains("plan") || key.contains("package") || key.contains("tier") {
                if value.contains("builtin:") || lowerValue.contains("coding") || lowerValue.contains("start") {
                    candidates.planNames.append(value)
                }
            }

            if key.contains("price") || key.contains("amount") || key.contains("cost") {
                if value.contains("¥") || value.contains("$") {
                    candidates.monthlyPrices.append(value)
                }
            }

            if isLikelyAPIKey(keyPath: key, value: value) {
                candidates.apiKeys.append(value)
            }
        }
        return candidates
    }

    private static func extractStructuredProviderCandidates(from root: Any) -> ConfigCandidates? {
        guard let dict = root as? [String: Any],
              let providers = (dict["provider"] ?? dict["providers"]) as? [String: Any] else {
            return nil
        }

        let parsed = providers.compactMap { id, value -> ConfigCandidates? in
            guard let provider = value as? [String: Any],
                  let options = provider["options"] as? [String: Any],
                  let apiKey = options["apiKey"] as? String,
                  !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                return nil
            }
            var candidate = ConfigCandidates()
            candidate.apiKeys = [apiKey]
            if let baseURL = options["baseURL"] as? String, !baseURL.isEmpty {
                candidate.baseURLs = [baseURL]
            }
            let name = provider["name"] as? String
            candidate.planNames = [id, name].compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty }
            candidate.enabledFlags = [(provider["enabled"] as? Bool) ?? false]
            return candidate
        }

        guard !parsed.isEmpty else { return nil }
        let sorted = parsed.sorted { lhs, rhs in
            let leftEnabled = lhs.enabledFlags.first ?? false
            let rightEnabled = rhs.enabledFlags.first ?? false
            if leftEnabled != rightEnabled { return leftEnabled && !rightEnabled }
            let leftPlan = lhs.planNames.first ?? ""
            let rightPlan = rhs.planNames.first ?? ""
            return leftPlan < rightPlan
        }

        var merged = ConfigCandidates()
        for candidate in sorted {
            merged.merge(candidate)
        }
        return merged
    }

    private static func isLikelyAPIKey(keyPath: String, value: String) -> Bool {
        let key = keyPath.lowercased()
        let lowerValue = value.lowercased()
        guard !lowerValue.hasPrefix("http://"), !lowerValue.hasPrefix("https://") else {
            return false
        }
        guard !value.contains("builtin:"), value.count >= 16 else {
            return false
        }
        return key.contains("api_key")
            || key.contains("apikey")
            || key.contains("api-key")
            || key.hasSuffix(".key")
            || key.contains("access_token")
            || key.contains("auth_token")
            || key.contains("token")
    }

    private static func defaultBaseURL(for planName: String?) -> String {
        let plan = planName?.lowercased() ?? ""
        if plan.contains("bigmodel") {
            return "https://open.bigmodel.cn"
        }
        return "https://api.z.ai"
    }

    private static func quotaBaseURL(for config: Config) -> String? {
        let plan = config.planName?.lowercased() ?? ""
        if plan.contains("bigmodel") {
            return "https://open.bigmodel.cn"
        }
        if plan.contains("zai") || plan.contains("z.ai") {
            return "https://api.z.ai"
        }
        guard let baseURL = config.baseURL,
              let host = URL(string: baseURL)?.host?.lowercased() else {
            return nil
        }
        if host.contains("zcode.z.ai") {
            return defaultBaseURL(for: config.planName)
        }
        return baseURL
    }

    private static func rootURLString(from raw: String) -> String? {
        guard let url = URL(string: raw),
              let scheme = url.scheme,
              let host = url.host else {
            return nil
        }
        var root = "\(scheme)://\(host)"
        if let port = url.port {
            root += ":\(port)"
        }
        return root
    }

    private static func zcodePlanBalanceURL(from raw: String?) -> URL? {
        guard let raw,
              let url = URL(string: raw),
              let scheme = url.scheme,
              let host = url.host?.lowercased(),
              host.contains("zcode.z.ai") else {
            return nil
        }
        var root = "\(scheme)://\(host)"
        if let port = url.port {
            root += ":\(port)"
        }
        return URL(string: "\(root)/api/v1/zcode-plan/billing/balance?app_version=3.1.5")
    }

    private static func flattenStrings(_ value: Any, prefix: String = "") -> [(keyPath: String, value: String)] {
        if let dict = value as? [String: Any] {
            return dict.flatMap { key, child in
                flattenStrings(child, prefix: prefix.isEmpty ? key : "\(prefix).\(key)")
            }
        }
        if let array = value as? [Any] {
            return array.enumerated().flatMap { index, child in
                flattenStrings(child, prefix: "\(prefix)[\(index)]")
            }
        }
        if let string = value as? String {
            return [(prefix, string)]
        }
        if let number = value as? NSNumber {
            return [(prefix, number.stringValue)]
        }
        return []
    }

    // MARK: - Parser

    struct ParsedQuotaResponse: Sendable {
        let quotas: [QuotaWindow]
        let planName: String?
        let monthlyPrice: String?
    }

    static func parseQuotaLimitResponse(
        data: Data,
        now: Date = Date(),
        fallbackPlanName: String? = nil
    ) throws -> ParsedQuotaResponse {
        if let balance = try? parseBillingBalanceResponse(
            data: data,
            now: now,
            fallbackPlanName: fallbackPlanName
        ), !balance.quotas.isEmpty {
            return balance
        }

        let response: QuotaLimitResponse
        do {
            response = try JSONDecoder().decode(QuotaLimitResponse.self, from: data)
        } catch {
            throw QuotaFetchError.transient(detail: "Z Code quota JSON 解析失败")
        }

        if let success = response.success, success == false {
            throw QuotaFetchError.transient(detail: response.msg ?? "Z Code quota API 返回失败")
        }

        guard let limits = response.data?.limits, !limits.isEmpty else {
            throw QuotaFetchError.transient(detail: "Z Code quota 响应无 limits")
        }

        let planName = response.data?.planName ?? fallbackPlanName
        let subscriptionGroup = planName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? ProviderKind.zcode.rawValue

        let quotas = limits.compactMap { limit -> QuotaWindow? in
            guard let descriptor = quotaDescriptor(type: limit.type, unit: limit.unit, number: limit.number) else {
                return nil
            }
            guard let usedPercent = limit.usedPercent else {
                return nil
            }
            let remaining = 1 - max(0, min(100, usedPercent)) / 100
            let resetsAt = limit.nextResetTime?.date
            return QuotaWindow(
                title: descriptor.title,
                remainingFraction: remaining,
                refreshDescription: resetsAt.map { QuotaResetText.description(for: $0, relativeTo: now) } ?? "—",
                resetsAt: resetsAt,
                periodSeconds: descriptor.periodSeconds,
                scope: descriptor.scope,
                subscriptionGroup: subscriptionGroup
            )
        }

        return ParsedQuotaResponse(
            quotas: quotas.sorted {
                ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude)
            },
            planName: planName,
            monthlyPrice: response.data?.monthlyPrice
        )
    }

    static func parseBillingBalanceResponse(
        data: Data,
        now: Date = Date(),
        fallbackPlanName: String? = nil
    ) throws -> ParsedQuotaResponse {
        let response: ZCodeBillingBalanceResponse
        do {
            response = try JSONDecoder().decode(ZCodeBillingBalanceResponse.self, from: data)
        } catch {
            throw QuotaFetchError.transient(detail: "Z Code billing balance JSON 解析失败")
        }
        if let code = response.code, code != 0 {
            throw QuotaFetchError.transient(detail: response.msg ?? "Z Code billing balance API 返回失败")
        }
        guard let payload = response.data else {
            throw QuotaFetchError.transient(detail: "Z Code billing balance 响应无 data")
        }
        guard let balances = payload.balances, !balances.isEmpty else {
            let plans = payload.plans ?? []
            if plans.isEmpty {
                throw QuotaFetchError.sourceUnavailable(detail: "Z Code billing balance 返回空 plans/balances")
            }
            throw QuotaFetchError.sourceUnavailable(detail: "Z Code billing balance 有 plan 但没有 balances")
        }

        let planName = fallbackPlanName
            ?? balances.compactMap(\.planId).first
        let subscriptionGroup = planName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? ProviderKind.zcode.rawValue

        let quotas = balances.compactMap { balance -> QuotaWindow? in
            guard let total = balance.totalUnits, total > 0 else { return nil }
            let remaining = balance.availableUnits ?? balance.remainingUnits ?? max(0, total - (balance.usedUnits ?? 0))
            let remainingFraction = max(0, min(1, Double(remaining) / Double(total)))
            let resetsAt = balance.expiresAt.map { Date(timeIntervalSince1970: TimeInterval($0)) }
            let periodSeconds: TimeInterval? = {
                guard let start = balance.periodStart,
                      let end = balance.periodEnd,
                      end > start else {
                    return nil
                }
                return TimeInterval(end - start + 1)
            }()
            return QuotaWindow(
                title: balance.showName ?? "GLM",
                remainingFraction: remainingFraction,
                refreshDescription: resetsAt.map { QuotaResetText.description(for: $0, relativeTo: now) } ?? "—",
                resetsAt: resetsAt,
                periodSeconds: periodSeconds,
                scope: balance.entitlementId,
                subscriptionGroup: subscriptionGroup
            )
        }

        return ParsedQuotaResponse(
            quotas: quotas.sorted {
                ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude)
            },
            planName: planName,
            monthlyPrice: nil
        )
    }

    private struct QuotaDescriptor {
        let title: String
        let periodSeconds: TimeInterval?
        let scope: String
    }

    private static func quotaDescriptor(type: String, unit: Int?, number: Int?) -> QuotaDescriptor? {
        let upperType = type.uppercased()
        switch (upperType, unit) {
        case ("TIME_LIMIT", _):
            return QuotaDescriptor(
                title: "MCP",
                periodSeconds: 30 * 24 * 60 * 60,
                scope: "time:\(unit.map(String.init) ?? "unknown")"
            )
        case ("TOKENS_LIMIT", 3):
            return QuotaDescriptor(
                title: "Code",
                periodSeconds: windowSeconds(unit: unit, number: number) ?? 5 * 60 * 60,
                scope: "tokens:session"
            )
        case ("TOKENS_LIMIT", 6):
            return QuotaDescriptor(
                title: "Code",
                periodSeconds: windowSeconds(unit: unit, number: number) ?? 7 * 24 * 60 * 60,
                scope: "tokens:weekly"
            )
        case ("TOKENS_LIMIT", 7):
            return QuotaDescriptor(
                title: "Code",
                periodSeconds: 30 * 24 * 60 * 60,
                scope: "tokens:monthly"
            )
        case ("TOKENS_LIMIT", nil):
            return QuotaDescriptor(
                title: "Code",
                periodSeconds: 5 * 60 * 60,
                scope: "tokens:session"
            )
        case ("TOKENS_LIMIT", let unknownUnit?):
            return QuotaDescriptor(
                title: "Tokens",
                periodSeconds: windowSeconds(unit: unknownUnit, number: number),
                scope: "tokens:unit-\(unknownUnit)"
            )
        default:
            return nil
        }
    }

    private static func windowSeconds(unit: Int?, number: Int?) -> TimeInterval? {
        guard let unit, let number, number > 0 else { return nil }
        switch unit {
        case 1:
            return TimeInterval(number * 24 * 60 * 60)
        case 3:
            return TimeInterval(number * 60 * 60)
        case 5:
            return TimeInterval(number * 60)
        case 6:
            return TimeInterval(number * 7 * 24 * 60 * 60)
        default:
            return nil
        }
    }
}

private struct QuotaLimitResponse: Decodable {
    let code: Int?
    let msg: String?
    let success: Bool?
    let data: QuotaLimitData?
}

private struct ZCodeBillingBalanceResponse: Decodable {
    let code: Int?
    let msg: String?
    let data: DataPayload?

    struct DataPayload: Decodable {
        let balances: [Balance]?
        let plans: [Plan]?
    }

    struct Plan: Decodable {}

    struct Balance: Decodable {
        let planId: String?
        let entitlementId: String?
        let showName: String?
        let totalUnits: Int?
        let usedUnits: Int?
        let remainingUnits: Int?
        let availableUnits: Int?
        let periodStart: Int?
        let periodEnd: Int?
        let expiresAt: Int?

        private enum CodingKeys: String, CodingKey {
            case planId = "plan_id"
            case entitlementId = "entitlement_id"
            case showName = "show_name"
            case totalUnits = "total_units"
            case usedUnits = "used_units"
            case remainingUnits = "remaining_units"
            case availableUnits = "available_units"
            case periodStart = "period_start"
            case periodEnd = "period_end"
            case expiresAt = "expires_at"
        }
    }
}

private struct QuotaLimitData: Decodable {
    let limits: [QuotaLimit]
    let planName: String?
    let monthlyPrice: String?

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        limits = try container.decodeIfPresent([QuotaLimit].self, forKey: .limits) ?? []
        planName = try [
            container.decodeIfPresent(String.self, forKey: .planName),
            container.decodeIfPresent(String.self, forKey: .plan),
            container.decodeIfPresent(String.self, forKey: .planType),
            container.decodeIfPresent(String.self, forKey: .packageName),
        ].compactMap(\.self).first?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        monthlyPrice = try [
            container.decodeIfPresent(String.self, forKey: .monthlyPrice),
            container.decodeIfPresent(String.self, forKey: .price),
            container.decodeIfPresent(String.self, forKey: .amount),
        ].compactMap(\.self).first?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
    }

    private enum CodingKeys: String, CodingKey {
        case limits
        case planName
        case plan
        case planType = "plan_type"
        case packageName
        case monthlyPrice
        case price
        case amount
    }
}

private struct QuotaLimit: Decodable {
    let type: String
    let unit: Int?
    let number: Int?
    let usage: Double?
    let currentValue: Double?
    let remaining: Double?
    let percentage: Double?
    let nextResetTime: FlexibleQuotaDate?

    var usedPercent: Double? {
        if let usage, usage > 0 {
            var usedRaw: Double?
            if let remaining {
                usedRaw = usage - remaining
                if let currentValue {
                    usedRaw = max(usedRaw ?? 0, currentValue)
                }
            } else if let currentValue {
                usedRaw = currentValue
            }
            if let usedRaw {
                return max(0, min(100, usedRaw / usage * 100))
            }
        }
        return percentage.map { max(0, min(100, $0)) }
    }
}

private enum FlexibleQuotaDate: Decodable {
    case timestamp(Double)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let number = try? container.decode(Double.self) {
            self = .timestamp(number)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else {
            throw DecodingError.typeMismatch(
                FlexibleQuotaDate.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected timestamp or string")
            )
        }
    }

    var date: Date? {
        switch self {
        case .timestamp(let raw):
            let seconds = raw > 10_000_000_000 ? raw / 1000 : raw
            return Date(timeIntervalSince1970: seconds)
        case .string(let text):
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if let number = Double(trimmed) {
                let seconds = number > 10_000_000_000 ? number / 1000 : number
                return Date(timeIntervalSince1970: seconds)
            }
            let withFraction = ISO8601DateFormatter()
            withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = withFraction.date(from: trimmed) {
                return date
            }
            let withoutFraction = ISO8601DateFormatter()
            withoutFraction.formatOptions = [.withInternetDateTime]
            return withoutFraction.date(from: trimmed)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
