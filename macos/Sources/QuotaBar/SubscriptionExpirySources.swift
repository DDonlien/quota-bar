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

/// 单个 provider 的一个过期日 source。
struct SubscriptionExpirySource: Sendable {
    let id: String
    let kind: SubscriptionExpirySourceKind
    let confidence: SubscriptionExpiryConfidence
    let dateMeaning: SubscriptionExpiryDateMeaning
    let pageURL: URL?
    let cookieDomains: [String]
    let harvester: SubscriptionDateHarvester?

    static func api(id: String, confidence: SubscriptionExpiryConfidence = .high) -> SubscriptionExpirySource {
        SubscriptionExpirySource(
            id: id,
            kind: .api,
            confidence: confidence,
            dateMeaning: .lastValidDate,
            pageURL: nil,
            cookieDomains: [],
            harvester: nil
        )
    }

    static func browserAPI(
        id: String,
        confidence: SubscriptionExpiryConfidence = .high,
        dateMeaning: SubscriptionExpiryDateMeaning = .lastValidDate
    ) -> SubscriptionExpirySource {
        SubscriptionExpirySource(
            id: id,
            kind: .browserAPI,
            confidence: confidence,
            dateMeaning: dateMeaning,
            pageURL: nil,
            cookieDomains: [],
            harvester: nil
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
            harvester: harvester
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
        if let expiresAt = snapshot.subscriptionExpiresAt,
           let sourceKind = snapshot.subscriptionExpiresAtSource,
           let confidence = snapshot.subscriptionExpiresAtConfidence {
            let source = SubscriptionExpirySource(
                id: "snapshot-\(sourceKind.rawValue)",
                kind: sourceKind,
                confidence: confidence,
                dateMeaning: .lastValidDate,
                pageURL: nil,
                cookieDomains: [],
                harvester: nil
            )
            return SubscriptionExpiryResolution(expiresAt: expiresAt, source: source)
        }

        let sources = SubscriptionExpirySources.sources(for: snapshot.kind)
        guard !sources.isEmpty else { return nil }

        for source in sources {
            switch source.kind {
            case .api, .appCache, .cli, .browserAPI:
                if let expiresAt = snapshot.subscriptionExpiresAt {
                    return SubscriptionExpiryResolution(expiresAt: expiresAt, source: source)
                }
            case .headlessDOM:
                guard let harvester = source.harvester else { continue }
                guard let url = source.pageURL else { continue }
                let loader = WKWebViewHeadlessLoader(cookieReader: cookieReader)
                do {
                    QuotaBarDiagnostics.write("[\(source.id)] starting subscription expiry source \(source.kind.rawValue) url=\(url.absoluteString) domains=\(source.cookieDomains.joined(separator: ","))")
                    let html = try await loader.load(
                        url: url,
                        cookieDomains: source.cookieDomains,
                        timeout: timeout,
                        identifier: source.id
                    )
                    guard let expiresAt = harvester.extract(from: html) else {
                        QuotaBarDiagnostics.write("[\(source.id)] extract returned nil")
                        continue
                    }
                    let lastValidDate = source.lastValidDate(from: expiresAt)
                    QuotaBarDiagnostics.write("[\(source.id)] parsed rawDate=\(expiresAt) meaning=\(source.dateMeaning.rawValue) lastValidDate=\(lastValidDate)")
                    return SubscriptionExpiryResolution(expiresAt: lastValidDate, source: source)
                } catch {
                    QuotaBarDiagnostics.write("[\(source.id)] failed: \(error)")
                    continue
                }
            }
        }
        return nil
    }
}
