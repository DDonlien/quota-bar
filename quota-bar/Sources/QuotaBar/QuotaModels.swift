import Foundation
import SwiftUI

// MARK: - Provider 种类

enum ProviderKind: String, CaseIterable, Hashable, Identifiable, Sendable {
    case codex
    case minimax
    case kimi
    case claude
    case cursor
    case gemini
    case openai
    case deepseek
    case copilot
    case openrouter
    case perplexity
    case warp
    case trae
    case antigravity

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: return "Codex"
        case .minimax: return "MiniMax"
        case .kimi: return "Kimi"
        case .claude: return "Claude"
        case .cursor: return "Cursor"
        case .gemini: return "Gemini"
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .copilot: return "Copilot"
        case .openrouter: return "OpenRouter"
        case .perplexity: return "Perplexity"
        case .warp: return "Warp"
        case .trae: return "Trae"
        case .antigravity: return "Antigravity"
        }
    }

    var fallbackMonthlyPrice: String? {
        switch self {
        default: return nil
        }
    }

    var brandColor: Color {
        switch self {
        case .codex: return Color(hex: "#35C85A")
        case .minimax: return Color(hex: "#FF453A")
        case .kimi: return Color(hex: "#FF9F0A")
        case .claude: return Color(hex: "#D4A574")
        case .cursor: return Color(hex: "#5E6AD2")
        case .gemini: return Color(hex: "#4285F4")
        case .openai: return Color(hex: "#10A37F")
        case .deepseek: return Color(hex: "#4D6BFA")
        case .copilot: return Color(hex: "#6E7681")
        case .openrouter: return Color(hex: "#F59E0B")
        case .perplexity: return Color(hex: "#1FB8CD")
        case .warp: return Color(hex: "#5E6AD2")
        case .trae: return Color(hex: "#3D7CFF")
        case .antigravity: return Color(hex: "#1A73E8")
        }
    }

    /// SF Symbol 名，用于菜单里的小图标。
    var iconSymbol: String {
        switch self {
        case .codex: return "terminal"
        case .claude: return "message"
        case .cursor: return "cursorarrow"
        case .gemini: return "sparkles"
        case .kimi: return "moon"
        case .minimax: return "bolt"
        case .openai: return "brain"
        case .deepseek: return "magnifyingglass"
        case .copilot: return "airplane"
        case .openrouter: return "network"
        case .perplexity: return "questionmark.circle"
        case .warp: return "arrow.right.circle"
        case .trae: return "hammer"
        case .antigravity: return "paperplane"
        }
    }

    /// 本机可执行的 CLI 命令（如 `codex` / `claude` / `kimi`）。
    ///
    /// 注意：`gemini` 已 deprecate —— Google 在用 `antigravity` CLI 取代它，
    /// 所以 Gemini 的检测不再依赖 gemini CLI（凭证也已迁移到 antigravity）。
    var cliCommand: String? {
        switch self {
        case .codex: return "codex"
        case .claude: return "claude"
        case .kimi: return "kimi"
        case .minimax: return "minimax"
        case .antigravity: return "antigravity"
        default: return nil
        }
    }

    /// 已安装桌面 App 的 bundle id（用于探测 app bundle 安装）。
    var bundleIdentifier: String? {
        switch self {
        case .cursor: return "com.todesktop.230313mzl4w4u92"
        case .warp: return "dev.warp.Warp-Stable"
        case .trae: return "com.trae.solo.app"
        case .antigravity: return "com.google.antigravity"
        case .kimi: return "com.moonshot.kimichat"
        case .minimax: return "com.minimax.agent.cn"
        default: return nil
        }
    }

    /// 用于探测 API Key 配置的环境变量名。
    var envVarNames: [String] {
        switch self {
        case .openai: return ["OPENAI_API_KEY"]
        case .claude: return ["ANTHROPIC_API_KEY"]
        case .deepseek: return ["DEEPSEEK_API_KEY"]
        case .openrouter: return ["OPENROUTER_API_KEY"]
        case .copilot: return ["GITHUB_TOKEN", "GITHUB_COPILOT_TOKEN"]
        default: return []
        }
    }

    /// 该 Provider 已知的本地凭证/配置文件路径（~ 开头会展开）。
    /// `InstallDetectorProvider` 会探测这些文件的存在来判断 service 是否装好。
    var credentialFiles: [String] {
        switch self {
        case .codex: return ["~/.codex/auth.json"]
        case .kimi: return ["~/.kimi-code/credentials/kimi-code.json"]
        case .minimax: return ["~/.mavis/config.yaml"]
        case .claude: return ["~/.claude/.credentials.json"]
        case .gemini: return ["~/.gemini/oauth_creds.json"]
        default: return []
        }
    }

    /// 用于在浏览器 cookie 里查找的域。
    var cookieDomains: [String] {
        switch self {
        case .codex, .openai: return ["openai.com", "chat.openai.com", "platform.openai.com", "chatgpt.com"]
        case .claude: return ["anthropic.com", "claude.ai"]
        case .cursor: return ["cursor.com", "cursor.sh"]
        case .gemini: return ["google.com", "gemini.google.com"]
        case .kimi: return ["kimi.moonshot.cn", "moonshot.cn", "kimi.com"]
        case .minimax: return ["minimax.chat", "minimax.com"]
        case .deepseek: return ["deepseek.com", "chat.deepseek.com"]
        case .copilot: return ["github.com", "copilot.github.com"]
        case .openrouter: return ["openrouter.ai"]
        case .perplexity: return ["perplexity.ai"]
        case .warp, .trae, .antigravity: return []
        }
    }
}

// MARK: - 额度窗口

struct QuotaWindow: Identifiable, Hashable {
    let id: UUID
    let title: String
    let remainingFraction: Double
    let refreshDescription: String
    let resetsAt: Date?
    /// 该额度窗口覆盖的时间段长度（秒），用于排序"最短周期优先"。
    /// `nil` 表示未知/未配置，会排到末尾。
    let periodSeconds: TimeInterval?
    /// 该额度窗口所属 scope（如 "code" / "work"），用于分组渲染。
    /// `nil` 表示无 scope（如单一维度的额度），渲染时与其它无 scope 的合并。
    let scope: String?

    init(
        id: UUID = UUID(),
        title: String,
        remainingFraction: Double,
        refreshDescription: String,
        resetsAt: Date? = nil,
        periodSeconds: TimeInterval? = nil,
        scope: String? = nil
    ) {
        self.id = id
        self.title = title
        self.remainingFraction = max(0, min(1, remainingFraction))
        self.refreshDescription = refreshDescription
        self.resetsAt = resetsAt
        self.periodSeconds = periodSeconds
        self.scope = scope
    }
}

// MARK: - Provider 可用性

enum ProviderAvailability: Hashable {
    case available
    case needsConfiguration(reason: String)
    case notInstalled
    case fetchFailed(reason: String)
}

// MARK: - Provider 快照

struct ProviderSnapshot: Identifiable, Hashable {
    let id: UUID
    let kind: ProviderKind
    let subscriptionTier: String?
    let availability: ProviderAvailability
    let quotas: [QuotaWindow]
    let monthlyPrice: String?
    let fetchedAt: Date
    let isStale: Bool

    init(
        id: UUID = UUID(),
        kind: ProviderKind,
        subscriptionTier: String? = nil,
        availability: ProviderAvailability,
        quotas: [QuotaWindow],
        monthlyPrice: String?,
        fetchedAt: Date,
        isStale: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.subscriptionTier = subscriptionTier
        self.availability = availability
        self.quotas = quotas
        self.monthlyPrice = monthlyPrice
        self.fetchedAt = fetchedAt
        self.isStale = isStale
    }

    var statusColor: Color {
        switch availability {
        case .available: return kind.brandColor
        case .needsConfiguration: return Color(hex: "#8E8E93")
        case .notInstalled: return Color(hex: "#8E8E93")
        case .fetchFailed: return Color(hex: "#FF9F0A")
        }
    }

    var displayName: String {
        guard let subscriptionTier, !subscriptionTier.isEmpty else {
            return kind.displayName
        }
        return "\(kind.displayName) \(subscriptionTier)"
    }
}

// MARK: - 刷新状态

enum RefreshState: Equatable, Sendable {
    case idle
    case refreshing
    case succeeded(at: Date)
    case partialFailure(at: Date, failedProviderIds: [String])
    case failed(at: Date?, message: String)

    var isRefreshing: Bool {
        if case .refreshing = self { return true }
        return false
    }

    var lastSuccessAt: Date? {
        switch self {
        case .succeeded(let at), .partialFailure(let at, _):
            return at
        case .failed(let at, _):
            return at
        case .idle, .refreshing:
            return nil
        }
    }
}

// MARK: - 错误

enum QuotaFetchError: LocalizedError, Equatable {
    case missingCredentials(detail: String)
    case permissionRequired(detail: String)
    case sourceUnavailable(detail: String)
    case transient(detail: String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials(let d), .permissionRequired(let d), .sourceUnavailable(let d), .transient(let d):
            return d
        }
    }

    var availabilityFallback: ProviderAvailability {
        switch self {
        case .missingCredentials(let reason):
            return .needsConfiguration(reason: reason)
        case .permissionRequired(let reason):
            return .needsConfiguration(reason: reason)
        case .sourceUnavailable:
            return .notInstalled
        case .transient(let reason):
            return .fetchFailed(reason: reason)
        }
    }

    var fallbackPriority: Int {
        switch self {
        case .permissionRequired: return 3
        case .missingCredentials: return 2
        case .transient: return 1
        case .sourceUnavailable: return 0
        }
    }
}

// MARK: - 聚合状态

struct DashboardState: Equatable, Sendable {
    var snapshots: [ProviderSnapshot]
    var refreshState: RefreshState
    var lastUpdated: Date?

    static let empty = DashboardState(snapshots: [], refreshState: .idle, lastUpdated: nil)

    var isEmpty: Bool { snapshots.isEmpty }

    var hasAnyAvailable: Bool {
        snapshots.contains { $0.availability == .available }
    }

    var isInitialLoading: Bool {
        guard refreshState.isRefreshing else { return false }
        return !hasAnyAvailable
    }

    var availableCount: Int {
        snapshots.filter { $0.availability == .available }.count
    }

    var totalCount: Int { snapshots.count }

    var totalMonthlyCostText: String {
        let total = snapshots
            .filter { $0.availability == .available }
            .compactMap { $0.monthlyPrice }
            .compactMap { parseMonthlyAmount($0) }
            .reduce(0, +)
        return total > 0 ? "\(PreferredCurrency.current.symbol)\(Int(total.rounded()))/月" : "—"
    }

    var availabilityText: String {
        guard totalCount > 0 else { return "—/—" }
        return "\(availableCount)/\(totalCount)"
    }

    var hasStaleData: Bool {
        snapshots.contains { $0.isStale }
    }
}

private func parseMonthlyAmount(_ text: String) -> Double? {
    var collected = ""
    var seenDigit = false
    for character in text {
        if character.isNumber || (character == "." && seenDigit) {
            collected.append(character)
            seenDigit = true
        } else if seenDigit {
            break
        }
    }
    return Double(collected)
}

enum ProviderPricing {
    static func normalizedTier(_ rawTier: String?) -> String? {
        guard let rawTier else { return nil }
        let normalized = rawTier.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !normalized.isEmpty, normalized != "free" else { return nil }
        switch normalized {
        case "plus": return "Plus"
        case "pro": return "Pro"
        case "max": return "Max"
        case "ultra": return "Ultra"
        default:
            return rawTier.prefix(1).uppercased() + rawTier.dropFirst()
        }
    }

    static func localizedMonthlyPrice(kind: ProviderKind, tier rawTier: String?) async -> String? {
        guard let usd = usdMonthlyPrice(kind: kind, tier: rawTier) else { return nil }
        let currency = PreferredCurrency.current
        let amount: Double
        switch currency.code {
        case "USD":
            amount = usd
        case "CNY":
            amount = usd * (await ExchangeRateProvider.shared.usdToCNY())
        default:
            amount = usd
        }
        return "\(currency.symbol)\(format(amount, currencyCode: currency.code))/月"
    }

    private static func usdMonthlyPrice(kind: ProviderKind, tier rawTier: String?) -> Double? {
        guard let tier = normalizedTier(rawTier)?.lowercased() else { return nil }
        switch (kind, tier) {
        case (.codex, "plus"), (.openai, "plus"):
            return 20
        case (.codex, "pro"), (.openai, "pro"):
            return 200
        case (.antigravity, "pro"), (.gemini, "pro"):
            return 20  // Google AI Pro（Antigravity / Gemini 共享底座）
        case (.antigravity, "ultra"), (.gemini, "ultra"):
            // Antigravity 2.0 文档：Ultra $100（5x Pro）和 Ultra $200（20x Pro）
            // API 不区分，按低价档默认展示，避免把实际 $100 显示成 $200。
            return 100
        default:
            return nil
        }
    }

    private static func format(_ amount: Double, currencyCode: String) -> String {
        if currencyCode == "USD" {
            return amount.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(amount))
                : String(format: "%.2f", amount)
        }
        return String(Int(amount.rounded()))
    }
}

struct PreferredCurrency {
    let code: String
    let symbol: String

    static var current: PreferredCurrency {
        let preferred = Locale.preferredLanguages.first?.lowercased() ?? ""
        let region = Locale.current.region?.identifier.uppercased()
        if region == "CN" || preferred.contains("hans") || preferred.hasPrefix("zh-cn") {
            return PreferredCurrency(code: "CNY", symbol: "¥")
        }
        return PreferredCurrency(code: "USD", symbol: "$")
    }
}

actor ExchangeRateProvider {
    static let shared = ExchangeRateProvider()

    private var cachedCNYRate: (rate: Double, fetchedAt: Date)?
    private let fallbackUSDToCNY = 7.25

    func usdToCNY() async -> Double {
        if let cachedCNYRate,
           Date().timeIntervalSince(cachedCNYRate.fetchedAt) < 12 * 60 * 60 {
            return cachedCNYRate.rate
        }

        guard let url = URL(string: "https://open.er-api.com/v6/latest/USD") else {
            return fallbackUSDToCNY
        }

        do {
            let request = URLRequest(url: url, timeoutInterval: 3)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse,
                  (200..<300).contains(http.statusCode),
                  let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let rates = json["rates"] as? [String: Any],
                  let rate = (rates["CNY"] as? NSNumber)?.doubleValue,
                  rate > 0 else {
                return fallbackUSDToCNY
            }
            cachedCNYRate = (rate, Date())
            return rate
        } catch {
            return fallbackUSDToCNY
        }
    }
}

enum QuotaResetText {
    static func description(for date: Date, relativeTo now: Date = Date()) -> String {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: now)
        let startOfDate = calendar.startOfDay(for: date)
        let dayOffset = calendar.dateComponents([.day], from: startOfToday, to: startOfDate).day ?? 0

        if dayOffset == 1 { return "明天" }
        if dayOffset == 2 { return "后天" }
        if dayOffset >= 3 {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "zh_CN")
            formatter.dateFormat = "M月d日"
            return formatter.string(from: date)
        }

        let seconds = date.timeIntervalSince(now)
        if seconds > 0, seconds < 24 * 60 * 60 {
            let formatter = RelativeDateTimeFormatter()
            formatter.unitsStyle = .full
            formatter.locale = Locale(identifier: "zh_CN")
            return formatter.localizedString(for: date, relativeTo: now)
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日"
        return formatter.string(from: date)
    }
}

// MARK: - 颜色扩展

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
