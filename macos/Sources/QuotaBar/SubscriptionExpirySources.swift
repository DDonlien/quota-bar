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

// MARK: - Codex accounts/check 解析

/// 解析 `https://chatgpt.com/backend-api/accounts/check/v4-2023-04-27` 响应：
/// ```json
/// {"accounts": {"default": {"entitlement": {
///     "has_active_subscription": true,
///     "subscription_plan": "chatgptplusplan",
///     "expires_at": "2026-07-25T15:23:58+00:00"
/// }}}}
/// ```
/// 活跃订阅的 `expires_at` 优先；多账号时取最晚日期。
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
                  let raw = entitlement["expires_at"] as? String,
                  let date = parseISODate(raw)
            else { continue }
            if (entitlement["has_active_subscription"] as? Bool) == true {
                activeDates.append(date)
            } else {
                otherDates.append(date)
            }
        }
        return activeDates.max() ?? otherDates.max()
    }

    private static func parseISODate(_ raw: String) -> Date? {
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = withFraction.date(from: raw) { return date }
        let plain = ISO8601DateFormatter()
        return plain.date(from: raw)
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
    private let cookieReader: BrowserCookieReader
    private let timeout: TimeInterval

    init(cookieReader: BrowserCookieReader, timeout: TimeInterval) {
        self.cookieReader = cookieReader
        self.timeout = timeout
    }

    /// 尝试为 snapshot 补充订阅过期日。
    ///
    /// 返回 nil 表示找不到过期日；调用方应保留原 snapshot 和额度状态，不把日期失败
    /// 映射成 quota 失败。
    func resolve(for snapshot: ProviderSnapshot) async -> SubscriptionExpiryResolution? {
        // snapshot 已带日期就直接采用（无论来源标记是否齐全），
        // 不再为一个已知日期跑 headless / 浏览器 Cookie（那是弹窗与超时的来源）。
        if let expiresAt = snapshot.subscriptionExpiresAt {
            let sourceKind = snapshot.subscriptionExpiresAtSource ?? .api
            let confidence = snapshot.subscriptionExpiresAtConfidence ?? .medium
            let source = SubscriptionExpirySource(
                id: "snapshot-\(sourceKind.rawValue)",
                kind: sourceKind,
                confidence: confidence,
                dateMeaning: .lastValidDate,
                pageURL: nil,
                cookieDomains: [],
                harvester: nil,
                apiRequest: nil
            )
            await ProviderCheckLog.shared.record(
                kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel,
                outcome: .success, detail: "来源 \(source.id)：沿用额度层已带的日期，跳过独立过期日 resolver：\(expiresAt)"
            )
            return SubscriptionExpiryResolution(expiresAt: expiresAt, source: source)
        }

        let sources = SubscriptionExpirySources.sources(for: snapshot.kind)
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
                if let expiresAt = snapshot.subscriptionExpiresAt {
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .success, detail: "来源 \(source.id)：\(expiresAt)")
                    return SubscriptionExpiryResolution(expiresAt: expiresAt, source: source)
                }
            case .browserAPI:
                // 可执行的 browserAPI source：用会话 Cookie 打 JSON API。
                // Cookie 来源两级：App 自有 WebView 会话（无弹窗）→ 浏览器 Cookie
                // （Safari/Firefox 文件读取，FDA 授权后静默；Chromium 默认被 Keychain gate 挡掉）。
                guard let request = source.apiRequest else { continue }
                do {
                    let cookies = await sessionCookies(for: source.cookieDomains)
                    guard !cookies.isEmpty else {
                        QuotaBarDiagnostics.write("[\(source.id)] no session cookies for \(source.cookieDomains.joined(separator: ","))")
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：无会话 Cookie（\(source.cookieDomains.joined(separator: ","))）")
                        continue
                    }
                    guard let rawDate = try await executeAPIRequest(request, cookies: cookies, identifier: source.id) else {
                        QuotaBarDiagnostics.write("[\(source.id)] extractDate returned nil")
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：响应里未解析出日期字段")
                        continue
                    }
                    let lastValidDate = source.lastValidDate(from: rawDate)
                    QuotaBarDiagnostics.write("[\(source.id)] parsed rawDate=\(rawDate) meaning=\(source.dateMeaning.rawValue) lastValidDate=\(lastValidDate)")
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .success, detail: "来源 \(source.id)：\(lastValidDate)")
                    return SubscriptionExpiryResolution(expiresAt: lastValidDate, source: source)
                } catch {
                    QuotaBarDiagnostics.write("[\(source.id)] failed: \(error)")
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：\(error.localizedDescription)")
                    continue
                }
            case .headlessDOM:
                guard let harvester = source.harvester else { continue }
                guard let url = source.pageURL else { continue }
                let loader = WKWebViewHeadlessLoader(cookieReader: cookieReader)
                do {
                    let html = try await loadHeadlessHTML(
                        loader: loader,
                        url: url,
                        source: source
                    )
                    guard let expiresAt = harvester.extract(from: html) else {
                        QuotaBarDiagnostics.write("[\(source.id)] extract returned nil")
                        await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：页面里未提取出日期")
                        continue
                    }
                    let lastValidDate = source.lastValidDate(from: expiresAt)
                    QuotaBarDiagnostics.write("[\(source.id)] parsed rawDate=\(expiresAt) meaning=\(source.dateMeaning.rawValue) lastValidDate=\(lastValidDate)")
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .success, detail: "来源 \(source.id)：\(lastValidDate)")
                    return SubscriptionExpiryResolution(expiresAt: lastValidDate, source: source)
                } catch {
                    QuotaBarDiagnostics.write("[\(source.id)] failed: \(error)")
                    await ProviderCheckLog.shared.record(kind: snapshot.kind, step: .expiration, method: source.kind.checkLogLabel, outcome: .failure, detail: "来源 \(source.id)：\(error.localizedDescription)")
                    continue
                }
            }
        }
        return nil
    }

    /// browserAPI source 的会话 Cookie：App 自有 WebView 会话优先，浏览器 Cookie 兜底。
    private func sessionCookies(for domains: [String]) async -> [HTTPCookie] {
        let appSession = (try? await AppWebViewSessionCookieReader().readCookies(matching: domains)) ?? []
        if !appSession.isEmpty { return appSession }
        return (try? await cookieReader.readCookies(matching: domains)) ?? []
    }

    /// 执行 browserAPI 请求并提取日期。
    private func executeAPIRequest(
        _ request: SubscriptionExpiryAPIRequest,
        cookies: [HTTPCookie],
        identifier: String
    ) async throws -> Date? {
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

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let http = response as? HTTPURLResponse else {
            throw QuotaFetchError.transient(detail: "browserAPI 返回非 HTTP 响应")
        }
        guard (200..<300).contains(http.statusCode) else {
            throw QuotaFetchError.transient(detail: "browserAPI HTTP \(http.statusCode)")
        }
        QuotaBarDiagnostics.write("[\(identifier)] browserAPI HTTP \(http.statusCode), \(data.count) bytes")
        return request.extractDate(data)
    }

    /// headless 页面加载的两级会话：
    /// 1. **App 自有 WebView 会话**（用户在 App 内 WebView 登录过一次即可，永久静默）；
    /// 2. **浏览器 Cookie**（Safari/Firefox 文件读取，FDA 授权后静默；
    ///    Chromium 系默认被 KeychainAccessGate 挡掉，绝不弹窗）。
    private func loadHeadlessHTML(
        loader: WKWebViewHeadlessLoader,
        url: URL,
        source: SubscriptionExpirySource
    ) async throws -> String {
        if await WKWebViewHeadlessLoader.appSessionHasCookies(for: source.cookieDomains) {
            QuotaBarDiagnostics.write("[\(source.id)] starting subscription expiry source headlessDOM(appSession) url=\(url.absoluteString)")
            do {
                return try await loader.loadUsingAppSession(
                    url: url,
                    cookieDomains: source.cookieDomains,
                    timeout: timeout,
                    identifier: source.id
                )
            } catch {
                QuotaBarDiagnostics.write("[\(source.id)] appSession load failed: \(error)，降级到浏览器 Cookie")
            }
        }
        QuotaBarDiagnostics.write("[\(source.id)] starting subscription expiry source \(source.kind.rawValue) url=\(url.absoluteString) domains=\(source.cookieDomains.joined(separator: ","))")
        return try await loader.load(
            url: url,
            cookieDomains: source.cookieDomains,
            timeout: timeout,
            identifier: source.id
        )
    }
}
