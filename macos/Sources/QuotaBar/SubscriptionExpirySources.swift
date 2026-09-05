import Foundation

// MARK: - 订阅过期日 source pipeline

/// 订阅过期日来源类型。
///
/// 额度 pipeline 负责回答「还有多少可用额度」；订阅过期日 source pipeline 负责回答
/// 「付费订阅什么时候续费 / 到期」。两者不能互相阻塞：没有付费订阅时仍可展示免费额度，
/// 找不到过期日时只隐藏日期。
enum SubscriptionExpirySourceKind: String, Codable, Hashable, Sendable {
    /// Provider API 或 dashboard API 明确返回的订阅到期字段。
    case api
    /// 本地 App 缓存、LocalStorage、SQLite、配置文件或本地服务。
    case appCache
    /// CLI 命令或 CLI 自身缓存。
    case cli
    /// 复用浏览器 Cookie 直接请求 Web App 内部 API。
    case browserAPI
    /// Headless WebView 打开订阅页，从渲染后 DOM 文本提取。
    case headlessDOM
}

/// 订阅过期日可信度。用于调试和后续 UI 解释。
enum SubscriptionExpiryConfidence: String, Codable, Hashable, Sendable {
    case high
    case medium
    case low
}

/// 订阅页日期在业务上的含义。
///
/// UI 展示的是「最后有效日」。有些页面直接写到期日；有些页面写的是下一次续费日，
/// 这类日期需要减去一个本地自然日，才能变成最后有效日。
enum SubscriptionExpiryDateMeaning: String, Codable, Hashable, Sendable {
    case lastValidDate
    case nextRenewalDate
}

/// browserAPI source 的可执行请求：用会话 Cookie 调 JSON API 提取原始日期。
/// 比 headless DOM 抓取稳定得多（SPA 渲染时序无关），是 headless 的上位替代。
struct SubscriptionExpiryAPIRequest: Sendable {
    let url: URL
    let method: String
    let headers: [String: String]
    /// 从响应 body 提取原始日期（语义由 source.dateMeaning 决定）；解析不出返回 nil。
    let extractDate: @Sendable (Data) -> Date?

    init(
        url: URL,
        method: String = "GET",
        headers: [String: String] = [:],
        extractDate: @escaping @Sendable (Data) -> Date?
    ) {
        self.url = url
        self.method = method
        self.headers = headers
        self.extractDate = extractDate
    }
}

/// 单个 provider 的一个过期日 source。
struct SubscriptionExpirySource: Sendable {
    let id: String
    let kind: SubscriptionExpirySourceKind
    let confidence: SubscriptionExpiryConfidence
    let dateMeaning: SubscriptionExpiryDateMeaning
    let pageURL: URL?
    let cookieDomains: [String]
    let harvester: SubscriptionDateHarvester?
    let apiRequest: SubscriptionExpiryAPIRequest?

    static func api(id: String, confidence: SubscriptionExpiryConfidence = .high) -> SubscriptionExpirySource {
        SubscriptionExpirySource(
            id: id,
            kind: .api,
            confidence: confidence,
            dateMeaning: .lastValidDate,
            pageURL: nil,
            cookieDomains: [],
            harvester: nil,
            apiRequest: nil
        )
    }

    static func browserAPI(
        id: String,
        confidence: SubscriptionExpiryConfidence = .high,
        dateMeaning: SubscriptionExpiryDateMeaning = .lastValidDate,
        cookieDomains: [String] = [],
        request: SubscriptionExpiryAPIRequest? = nil
    ) -> SubscriptionExpirySource {
        SubscriptionExpirySource(
            id: id,
            kind: .browserAPI,
            confidence: confidence,
            dateMeaning: dateMeaning,
            pageURL: nil,
            cookieDomains: cookieDomains,
            harvester: nil,
            apiRequest: request
        )
    }

    static func headlessDOM(
        id: String,
        confidence: SubscriptionExpiryConfidence = .medium,
        dateMeaning: SubscriptionExpiryDateMeaning = .lastValidDate,
        cookieDomains: [String],
        harvester: SubscriptionDateHarvester
    ) -> SubscriptionExpirySource {
        SubscriptionExpirySource(
            id: id,
            kind: .headlessDOM,
            confidence: confidence,
            dateMeaning: dateMeaning,
            pageURL: harvester.pageURL,
            cookieDomains: cookieDomains,
            harvester: harvester,
            apiRequest: nil
        )
    }

    func lastValidDate(from extractedDate: Date, calendar: Calendar = .current) -> Date {
        switch dateMeaning {
        case .lastValidDate:
            return extractedDate
        case .nextRenewalDate:
            let startOfRenewalDay = calendar.startOfDay(for: extractedDate)
            return calendar.date(byAdding: .day, value: -1, to: startOfRenewalDay)
                ?? extractedDate.addingTimeInterval(-86_400)
        }
    }
}

struct SubscriptionExpiryResolution: Sendable {
    let expiresAt: Date
    let source: SubscriptionExpirySource
}

/// 订阅页可能只提供档位而不提供日期（例如通过 iOS 订阅的 Claude）。
/// 这类结果仍然足以补全费用，因此不能再用「必须有日期」作为成功条件。
struct SubscriptionMetadataResolution: Sendable {
    let expiresAt: Date?
    let subscriptionTier: String?
    let source: SubscriptionExpirySource
}

// MARK: - Codex accounts/check 解析

/// 解析 `https://chatgpt.com/backend-api/accounts/check/v4-2023-04-27` 响应：
/// ```json
/// {"accounts": {"default": {"entitlement": {
///     "has_active_subscription": true,
///     "subscription_plan": "chatgptplusplan",
///     "renews_at": "2026-07-25T15:23:58+00:00",
///     "expires_at": null
/// }}}}
/// ```
/// 活跃订阅优先取下一次真实扣费边界 `renews_at`，仅当它不存在时才退到
/// `expires_at`；两者都兼容 ISO-8601、Unix 秒和 Unix 毫秒。多账号时取最晚日期。
enum CodexAccountsCheckParser {
    static func extractExpiresAt(from data: Data) -> Date? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accounts = json["accounts"] as? [String: Any]
        else { return nil }

        var activeDates: [Date] = []
        var otherDates: [Date] = []
        for value in accounts.values {
            guard let account = value as? [String: Any],
                  let entitlement = account["entitlement"] as? [String: Any],
                  let date = parseDate(entitlement["renews_at"])
                    ?? parseDate(entitlement["expires_at"])
            else { continue }
            if (entitlement["has_active_subscription"] as? Bool) == true {
                activeDates.append(date)
            } else {
                otherDates.append(date)
            }
        }
        return activeDates.max() ?? otherDates.max()
    }

    /// 只输出 JSON 的字段结构，不输出账号 key、字段值或任何 Cookie/token。
    /// accounts/check schema 漂移时，这份摘要可区分「字段改名」和「当前会话没有
    /// entitlement」，同时保持诊断日志不含个人账号信息。
    static func safeShapeSummary(from data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "non-object-json"
        }
        let topLevelKeys = json.keys.sorted().joined(separator: ",")
        guard let accountsValue = json["accounts"] else {
            return "top=[\(topLevelKeys)]; accounts=missing"
        }

        let accountObjects: [[String: Any]]
        let accountsShape: String
        if let accounts = accountsValue as? [String: Any] {
            accountObjects = accounts.values.compactMap { $0 as? [String: Any] }
            accountsShape = "object(\(accounts.count))"
        } else if let accounts = accountsValue as? [[String: Any]] {
            accountObjects = accounts
            accountsShape = "array(\(accounts.count))"
        } else {
            accountObjects = []
            accountsShape = String(describing: type(of: accountsValue))
        }

        let accountKeys = Set(accountObjects.flatMap(\.keys)).sorted().joined(separator: ",")
        let entitlements = accountObjects.compactMap { $0["entitlement"] as? [String: Any] }
        let entitlementKeys = Set(entitlements.flatMap(\.keys)).sorted().joined(separator: ",")
        let dateFieldShapes = Set(entitlements.flatMap { entitlement in
            ["renews_at", "expires_at"].map { key in
                "\(key)=\(safeValueShape(entitlement[key]))"
            }
        }).sorted().joined(separator: ",")
        let lastActiveSubscriptions = accountObjects.compactMap {
            $0["last_active_subscription"] as? [String: Any]
        }
        let lastActiveKeys = Set(lastActiveSubscriptions.flatMap(\.keys)).sorted().joined(separator: ",")
        return "top=[\(topLevelKeys)]; accounts=\(accountsShape); accountKeys=[\(accountKeys)]; entitlementKeys=[\(entitlementKeys)]; dateFields=[\(dateFieldShapes)]; lastActiveKeys=[\(lastActiveKeys)]"
    }

    private static func parseDate(_ raw: Any?) -> Date? {
        if let number = raw as? NSNumber {
            let value = number.doubleValue
            guard value.isFinite, value > 0 else { return nil }
            let seconds = value > 10_000_000_000 ? value / 1_000 : value
            return Date(timeIntervalSince1970: seconds)
        }
        guard let raw = raw as? String else { return nil }
        if let value = Double(raw), value.isFinite, value > 0 {
            let seconds = value > 10_000_000_000 ? value / 1_000 : value
            return Date(timeIntervalSince1970: seconds)
        }
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        let plain = ISO8601DateFormatter()
        return plain.date(from: raw)
    }

    private static func safeValueShape(_ value: Any?) -> String {
        switch value {
        case nil:
            return "missing"
        case is NSNull:
            return "null"
        case let string as String:
            return "string(\(string.count))"
        case is NSNumber:
            return "number"
        case let object as [String: Any]:
            return "object[\(object.keys.sorted().joined(separator: ","))]"
        case let array as [Any]:
            return "array(\(array.count))"
        default:
            return String(describing: type(of: value))
        }
    }
}

/// ProviderKind → 订阅过期日 source 注册表。
///
/// 当前已落地的可执行 source：
/// - Headless DOM：Codex / Claude / Cursor / MiniMax / Antigravity 打开用户可见订阅页。
///
/// `appCache` / `cli` / `browserAPI` 作为明确的扩展层级保留，后续发现真实缓存或 CLI
/// status 输出时只需在这里插入更高优先级 source。
enum SubscriptionExpirySources {
    static func sources(for kind: ProviderKind) -> [SubscriptionExpirySource] {
        switch kind {
        case .kimi:
            return [
                .headlessDOM(
                    id: "kimi-membership-page",
                    confidence: .medium,
                    dateMeaning: .nextRenewalDate,
                    cookieDomains: ["kimi.com", "kimi.moonshot.cn", "moonshot.cn"],
                    harvester: KimiHarvester()
                ),
            ]
        case .codex, .openai:
            return [
                // 首选：accounts/check JSON API（entitlement.expires_at = 当前付费周期
                // 截止时刻）。headless DOM 抓 chatgpt.com 账单页是 hash 路由 SPA，
                // didFinish 时账单数据尚未渲染，实测长期 extract nil —— JSON API 无此问题。
                .browserAPI(
                    id: "codex-accounts-check",
                    confidence: .high,
                    dateMeaning: .lastValidDate,
                    cookieDomains: ["chatgpt.com", "openai.com"],
                    request: SubscriptionExpiryAPIRequest(
                        url: URL(string: "https://chatgpt.com/backend-api/accounts/check/v4-2023-04-27")!,
                        headers: ["Accept": "application/json"],
                        extractDate: { CodexAccountsCheckParser.extractExpiresAt(from: $0) }
                    )
                ),
                .headlessDOM(
                    id: "codex-chatgpt-billing-page",
                    cookieDomains: ["chatgpt.com", "openai.com"],
                    harvester: CodexHarvester()
                ),
            ]
        case .claude:
            return [
                .headlessDOM(
                    id: "claude-billing-settings-page",
                    cookieDomains: ["claude.ai", "anthropic.com"],
                    harvester: ClaudeHarvester()
                ),
            ]
        case .cursor:
            return [
                .headlessDOM(
                    id: "cursor-dashboard-page",
                    cookieDomains: ["cursor.com", "cursor.sh"],
                    harvester: CursorHarvester()
                ),
            ]
        case .minimax:
            return [
                .headlessDOM(
                    id: "minimax-platform-plan-page",
                    cookieDomains: ["platform.minimaxi.com", "minimaxi.com", "minimax.chat", "minimax.com"],
                    harvester: MiniMaxHarvester()
                ),
            ]
        case .antigravity:
            return [
                .headlessDOM(
                    id: "antigravity-settings-page",
                    cookieDomains: ["antigravity.google", "google.com", "accounts.google.com"],
                    harvester: AntigravityHarvester()
                ),
            ]
        default:
            return []
        }
    }

    static var supportedKinds: [ProviderKind] {
        ProviderKind.allCases.filter { !sources(for: $0).isEmpty }
    }

    static var headlessKinds: [ProviderKind] {
        ProviderKind.allCases.filter { kind in
            sources(for: kind).contains { $0.kind == .headlessDOM }
        }
    }
}

@MainActor
final class SubscriptionExpiryResolver {
    private let timeout: TimeInterval
    private let session: URLSession
    private let cookiesProvider: ([String]) async -> [HTTPCookie]
    private let sourcesProvider: (ProviderKind) -> [SubscriptionExpirySource]

    init(
        timeout: TimeInterval,
        session: URLSession = .shared,
        cookiesProvider: (([String]) async -> [HTTPCookie])? = nil,
        sourcesProvider: ((ProviderKind) -> [SubscriptionExpirySource])? = nil
    ) {
        self.timeout = timeout
        self.session = session
        self.cookiesProvider = cookiesProvider ?? { domains in
            (try? await AppWebViewSessionCookieReader().readCookies(matching: domains)) ?? []
        }
        self.sourcesProvider = sourcesProvider ?? { SubscriptionExpirySources.sources(for: $0) }
    }

    /// 兼容旧调用方：只返回成功解析出的日期。
    func resolve(for snapshot: ProviderSnapshot) async -> SubscriptionExpiryResolution? {
        guard let result = await resolveMetadata(for: snapshot),
              let expiresAt = result.expiresAt else {
            return nil
        }
        return SubscriptionExpiryResolution(expiresAt: expiresAt, source: result.source)
    }

    /// 尝试为 snapshot 补充订阅元数据。
    ///
    /// 返回结果可以只有档位、没有日期；调用方应保留原 snapshot 和额度状态，
    /// 不把日期解析失败映射成 quota 失败。
    func resolveMetadata(for snapshot: ProviderSnapshot) async -> SubscriptionMetadataResolution? {
        // snapshot 已带、并且仍在当前 snapshot 时间之后的日期才可直接采用。
        // 已过去的日期是历史周期元数据，必须继续查询后续来源，不能让它短路
        // accounts/check（Codex 旧 JWT 日期长期停在首个订阅周期就是这个问题）。
        if let expiresAt = snapshot.subscriptionExpiresAt {
            let source = existingSnapshotSource(for: snapshot)
            if expiresAt > snapshot.fetchedAt {
                await ProviderCheckLog.shared.record(
                    kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel,
                    outcome: .success, detail: "来源 \(source.id)：沿用额度层已带的当前周期日期，跳过独立过期日 resolver：\(expiresAt)"
                )
                return SubscriptionMetadataResolution(expiresAt: expiresAt, subscriptionTier: nil, source: source)
            }
            await ProviderCheckLog.shared.record(
                kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel,
                outcome: .skipped, detail: "来源 \(source.id)：忽略已过去的历史周期日期，继续查询当前订阅周期：\(expiresAt)"
            )
        }

        let sources = sourcesProvider(snapshot.kind)
        guard !sources.isEmpty else {
            await ProviderCheckLog.shared.record(
                kind: snapshot.kind, step: .expiration, method: "-",
                outcome: .skipped, detail: "该 provider 未配置独立过期日来源"
            )
            return nil
        }

        for source in sources {
            switch source.kind {
            case .api, .appCache, .cli:
                // 这些 source 目前只表示 snapshot 已有字段；当前日期已在函数入口返回，
                // 历史日期也已明确淘汰，因此这里没有可执行动作。
                continue
            case .browserAPI:
                // 可执行的 browserAPI source：用 App 自有 WebView 会话 Cookie 打 JSON API
                // （2026-07-08 移除浏览器 Cookie 文件读取兜底）。
                guard let request = source.apiRequest else { continue }
                do {
                    let cookies = await sessionCookies(for: source.cookieDomains)
                    guard !cookies.isEmpty else {
                        QuotaBarDiagnostics.write("[\(source.id)] no session cookies for \(source.cookieDomains.joined(separator: ","))")
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：无会话 Cookie（\(source.cookieDomains.joined(separator: ","))）")
                        continue
                    }
                    let apiResponse = try await executeAPIRequest(
                        request,
                        cookies: cookies,
                        identifier: source.id
                    )
                    guard let rawDate = apiResponse.date else {
                        QuotaBarDiagnostics.write("[\(source.id)] extractDate returned nil")
                        let shape = source.id == "codex-accounts-check"
                            ? "；响应结构 \(CodexAccountsCheckParser.safeShapeSummary(from: apiResponse.data))"
                            : ""
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：响应里未解析出日期字段\(shape)")
                        continue
                    }
                    let lastValidDate = source.lastValidDate(from: rawDate)
                    QuotaBarDiagnostics.write("[\(source.id)] parsed rawDate=\(rawDate) meaning=\(source.dateMeaning.rawValue) lastValidDate=\(lastValidDate)")
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .success, detail: "来源 \(source.id)：\(lastValidDate)")
                    return SubscriptionMetadataResolution(expiresAt: lastValidDate, subscriptionTier: nil, source: source)
                } catch {
                    QuotaBarDiagnostics.write("[\(source.id)] failed: \(error)")
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：\(error.localizedDescription)")
                    continue
                }
            case .headlessDOM:
                guard let harvester = source.harvester else { continue }
                guard let url = source.pageURL else { continue }
                let loader = WKWebViewHeadlessLoader()
                do {
                    let html = try await loadHeadlessHTML(
                        loader: loader,
                        url: url,
                        source: source
                    )
                    let expiresAt = harvester.extract(from: html)
                    let tier = harvester.extractSubscriptionTier(from: html)
                    guard expiresAt != nil || tier != nil else {
                        QuotaBarDiagnostics.write("[\(source.id)] extract returned no subscription metadata")
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：页面里未提取出日期或档位")
                        continue
                    }
                    let lastValidDate = expiresAt.map { source.lastValidDate(from: $0) }
                    if let lastValidDate {
                        QuotaBarDiagnostics.write("[\(source.id)] parsed rawDate=\(expiresAt!) meaning=\(source.dateMeaning.rawValue) lastValidDate=\(lastValidDate)")
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .success, detail: "来源 \(source.id)：\(lastValidDate)")
                    } else {
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .skipped, detail: "来源 \(source.id)：页面没有日期，但已读取档位")
                    }
                    if let tier {
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .plan, method: source.kind.checkLogLabel, outcome: .success, detail: "来源 \(source.id)：档位=\(tier)，费用由档位映射")
                    }
                    return SubscriptionMetadataResolution(expiresAt: lastValidDate, subscriptionTier: tier, source: source)
                } catch {
                    QuotaBarDiagnostics.write("[\(source.id)] failed: \(error)")
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：\(error.localizedDescription)")
                    continue
                }
            }
        }
        return nil
    }

    private func existingSnapshotSource(for snapshot: ProviderSnapshot) -> SubscriptionExpirySource {
        let sourceKind = snapshot.subscriptionExpiresAtSource ?? .api
        let confidence = snapshot.subscriptionExpiresAtConfidence ?? .medium
        return SubscriptionExpirySource(
            id: "snapshot-\(sourceKind.rawValue)",
            kind: sourceKind,
            confidence: confidence,
            dateMeaning: .lastValidDate,
            pageURL: nil,
            cookieDomains: [],
            harvester: nil,
            apiRequest: nil
        )
    }

    /// browserAPI source 的会话 Cookie：只用 App 自有 WebView 会话（2026-07-08
    /// 移除浏览器文件读取兜底，见 `BrowserCookieReader.swift` 顶部说明）。
    private func sessionCookies(for domains: [String]) async -> [HTTPCookie] {
        await cookiesProvider(domains)
    }

    /// 执行 browserAPI 请求并提取日期。
    private func executeAPIRequest(
        _ request: SubscriptionExpiryAPIRequest,
        cookies: [HTTPCookie],
        identifier: String
    ) async throws -> (date: Date?, data: Data) {
        var urlRequest = URLRequest(url: request.url, timeoutInterval: timeout)
        urlRequest.httpMethod = request.method
        urlRequest.setValue(
            "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 QuotaBar/1.0",
            forHTTPHeaderField: "User-Agent"
        )
        let cookieHeader = cookies.map { "\($0.name)=\($0.value)" }.joined(separator: "; ")
        urlRequest.setValue(cookieHeader, forHTTPHeaderField: "Cookie")
        for (key, value) in request.headers {
            urlRequest.setValue(value, forHTTPHeaderField: key)
        }

        let (data, response) = try await session.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "browserAPI 返回非 HTTP 响应")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw QuotaFetchError.transient(detail: "browserAPI HTTP \(http.statusCode)")
        }
        QuotaBarDiagnostics.write("[\(identifier)] browserAPI HTTP \(http.statusCode), \(data.count) bytes")
        return (request.extractDate(data), data)
    }

    /// headless 页面加载：只用 App 自有 WebView 会话（用户在 App 内 WebView
    /// 登录过一次即可，永久静默）。2026-07-08 移除浏览器 Cookie 文件读取兜底，
    /// 见 `BrowserCookieReader.swift` 顶部说明；没有 app session cookie 时直接
    /// 抛 `missingCredentials`，不再尝试读浏览器文件。
    private func loadHeadlessHTML(
        loader: WKWebViewHeadlessLoader,
        url: URL,
        source: SubscriptionExpirySource
    ) async throws -> String {
        guard await WKWebViewHeadlessLoader.appSessionHasCookies(for: source.cookieDomains) else {
            throw QuotaFetchError.missingCredentials(detail: "App 内 WebView 尚未授权")
        }
        QuotaBarDiagnostics.write("[\(source.id)] starting subscription expiry source headlessDOM(appSession) url=\(url.absoluteString)")
        return try await loader.loadUsingAppSession(
            url: url,
            cookieDomains: source.cookieDomains,
            timeout: timeout,
            identifier: source.id
        )
    }
}
