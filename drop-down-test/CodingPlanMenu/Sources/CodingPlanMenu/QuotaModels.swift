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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .codex: return "Codex Plus"
        case .minimax: return "MiniMax Plus"
        case .kimi: return "Kimi Plus"
        case .claude: return "Claude"
        case .cursor: return "Cursor"
        case .gemini: return "Gemini"
        case .openai: return "OpenAI"
        case .deepseek: return "DeepSeek"
        case .copilot: return "Copilot"
        case .openrouter: return "OpenRouter"
        case .perplexity: return "Perplexity"
        case .warp: return "Warp"
        }
    }

    var fallbackMonthlyPrice: String {
        switch self {
        case .codex: return "¥150/月"
        case .minimax: return "¥150/月"
        case .kimi: return "¥150/月"
        default: return "—"
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

    init(
        id: UUID = UUID(),
        title: String,
        remainingFraction: Double,
        refreshDescription: String,
        resetsAt: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.remainingFraction = max(0, min(1, remainingFraction))
        self.refreshDescription = refreshDescription
        self.resetsAt = resetsAt
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
    let availability: ProviderAvailability
    let quotas: [QuotaWindow]
    let monthlyPrice: String?
    let fetchedAt: Date
    let isStale: Bool

    init(
        id: UUID = UUID(),
        kind: ProviderKind,
        availability: ProviderAvailability,
        quotas: [QuotaWindow],
        monthlyPrice: String?,
        fetchedAt: Date,
        isStale: Bool = false
    ) {
        self.id = id
        self.kind = kind
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
    case sourceUnavailable(detail: String)
    case transient(detail: String)

    var errorDescription: String? {
        switch self {
        case .missingCredentials(let d), .sourceUnavailable(let d), .transient(let d):
            return d
        }
    }

    var availabilityFallback: ProviderAvailability {
        switch self {
        case .missingCredentials(let reason):
            return .needsConfiguration(reason: reason)
        case .sourceUnavailable:
            return .notInstalled
        case .transient(let reason):
            return .fetchFailed(reason: reason)
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
        return total > 0 ? "¥\(Int(total))/月" : "—"
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
