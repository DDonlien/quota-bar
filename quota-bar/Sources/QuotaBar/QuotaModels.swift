import Foundation
import SwiftUI

// MARK: - Provider 种类

enum ProviderKind: String, CaseIterable, Hashable, Identifiable, Codable, Sendable {
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
    /// 额度名称（如 "Code"、"Work"、"General"、"Video"、"Gemini"、"Other"）。
    /// 不包含周期信息，周期由 `periodLabel` 根据 `periodSeconds` 自动生成。
    let title: String
    let remainingFraction: Double
    let refreshDescription: String
    let resetsAt: Date?
    /// 该额度窗口覆盖的时间段长度（秒），用于排序"最短周期优先"和生成本地化周期标签。
    /// `nil` 表示无固定周期（如固定额度包或按量付费），会排到末尾。
    let periodSeconds: TimeInterval?
    /// 该额度窗口所属 scope（如 "code" / "work"），用于调试/日志，**不再显示在 UI 中**。
    /// 渲染时通过 `title` 区分不同 scope，避免重复。
    let scope: String?
    /// **订阅组** key：相同 subscriptionGroup 的窗口属于同一个独立订阅（共享额度池），
    /// 任一归零即整订阅不可用；不同 subscriptionGroup 是**独立计费**的订阅（如 MiniMax 的
    /// General / Video、Antigravity 的 Gemini / Other），各自有独立的额度池。
    ///
    /// 决定两层行为：
    /// - **UI 拖拽**：dropdown 里相同 subscriptionGroup 的窗口会聚成一个 sub-section，
    ///   多订阅组 provider 显示多个 sub-section（独立可拖）；单订阅组 provider 显示 1 个
    ///   sub-section（与原 UI 一致）。
    /// - **bar/灯取值**：`primarySubscriptionGroupWorstQuota` 取用户排序后第一个 subscriptionGroup
    ///   里的最差 quota，决定状态栏 bar 高度和 dropdown 状态灯颜色。
    ///
    /// `nil` 时 fallback 到 `provider.kind.rawValue`（即整个 provider 视为 1 个订阅组）。
    let subscriptionGroup: String?

    init(
        id: UUID = UUID(),
        title: String,
        remainingFraction: Double,
        refreshDescription: String,
        resetsAt: Date? = nil,
        periodSeconds: TimeInterval? = nil,
        scope: String? = nil,
        subscriptionGroup: String? = nil
    ) {
        self.id = id
        self.title = title
        self.remainingFraction = max(0, min(1, remainingFraction))
        self.refreshDescription = refreshDescription
        self.resetsAt = resetsAt
        self.periodSeconds = periodSeconds
        self.scope = scope
        self.subscriptionGroup = subscriptionGroup
    }

    /// 从 `periodSeconds` 生成本地化周期标签。
    /// 优先推断标准周期（周/月/日/5小时），否则按精确时间计算。
    /// 规则：
    /// - `periodSeconds` 为 nil → "固定额度"
    /// - 4~8 天 → "周额度"（Weekly Limit）
    /// - 28~32 天 → "月额度"
    /// - 22~26 小时 → "日额度"
    /// - 3~6 小时 → "5 小时额度"
    /// - 精确计算：x 小时额度 / x 日额度 / x 月额度（x 为 1 时隐藏数字）
    var periodLabel: String? {
        guard let period = periodSeconds else {
            return "固定额度"
        }
        let days = Int(period / 86400)
        let hours = Int(period / 3600)
        let minutes = Int(period / 60)

        // 标准周期推断（基于剩余时间范围，适配 Weekly/Monthly/Daily 等）
        if days >= 4 && days <= 8 {
            return "周额度"
        } else if days >= 28 && days <= 32 {
            return "月额度"
        } else if hours >= 22 && hours <= 26 {
            return "日额度"
        } else if hours >= 3 && hours <= 6 {
            return "5 小时额度"
        }

        // 精确计算（非标准周期）
        if days >= 30 {
            let months = days / 30
            return months == 1 ? "月额度" : "\(months) 月额度"
        } else if days >= 7 {
            let weeks = days / 7
            return weeks == 1 ? "周额度" : "\(weeks) 周额度"
        } else if days >= 1 {
            return days == 1 ? "日额度" : "\(days) 日额度"
        } else if hours >= 1 {
            return hours == 1 ? "小时额度" : "\(hours) 小时额度"
        } else if minutes >= 1 {
            return minutes == 1 ? "分钟额度" : "\(minutes) 分钟额度"
        }
        return nil
    }

    /// 完整的显示标题："名字 周期标签"。
    /// 如果 `title` 为空，只显示周期标签。
    var displayTitle: String {
        let name = title.trimmingCharacters(in: .whitespaces)
        guard let label = periodLabel else {
            return name.isEmpty ? "额度" : name
        }
        if name.isEmpty {
            return label
        }
        return "\(name) \(label)"
    }

    /// 用于跨刷新周期稳定识别同一条额度的 key。
    /// 由 `title` 与 `periodSeconds` 组成；UUID 每次刷新都会变，不能用于持久化排序。
    var stableKey: String {
        let period = periodSeconds.map { String(Int($0)) } ?? "fixed"
        return "\(title)|\(period)"
    }
}

// MARK: - Provider 可用性

enum ProviderAvailability: Hashable {
    /// 探测到已安装、正在刷新中（pipeline 尚未返回真实数据）。
    /// UI 展示「订阅组名 + 状态灯（灰色）+ 骨架占位」，直到真实数据回填。
    /// 与 `available` 的区别：loading 状态下没有真实 quota 窗口，只有骨架；
    /// 一旦 pipeline 返回或 fallback 决定，availability 会切到 `.available` / `.needsConfiguration` /
    /// `.fetchFailed` / `.notInstalled` 之一。
    case loading
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

    /// 构造一个「正在刷新中」的占位 snapshot：
    /// - `availability = .loading`
    /// - 无 quota、无 tier、无价格
    /// - `fetchedAt = now`（用于排序时稳定占位）
    /// - `isStale = false`（loading 不算 stale）
    ///
    /// 由 `RefreshCoordinator.runRefreshCycle` 在探测到 installed kind 后立刻
    /// 注入到 `state.snapshots`，使 UI 立即出现该 provider 的骨架行；pipeline 返回
    /// 后会被替换为真实 snapshot。
    static func loading(kind: ProviderKind, fetchedAt: Date = Date()) -> ProviderSnapshot {
        ProviderSnapshot(
            kind: kind,
            subscriptionTier: nil,
            availability: .loading,
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: fetchedAt,
            isStale: false
        )
    }

    /// 按 `title` 分组排序后的 quotas：
    /// 1. 保持 `title` 首次出现的顺序（子服务顺序不变）
    /// 2. 每组内按 `periodSeconds` 升序（最短周期优先）
    var sortedQuotas: [QuotaWindow] {
        sortedQuotas(customOrder: [])
    }

    /// 按 `title` 分组，并允许用 `customOrder` 指定组间顺序。
    /// `customOrder` 中越靠前的 `title` 显示越靠前；未出现的组保持原首次出现顺序排在后面。
    func sortedQuotas(customOrder: [String]) -> [QuotaWindow] {
        var titleOrder: [String] = []
        var grouped: [String: [QuotaWindow]] = [:]
        for quota in quotas {
            let name = quota.title
            if grouped[name] == nil {
                titleOrder.append(name)
                grouped[name] = []
            }
            grouped[name]!.append(quota)
        }

        let orderedTitles: [String] = {
            var ordered: [String] = []
            var remaining = Set(titleOrder)
            for title in customOrder where remaining.remove(title) != nil {
                ordered.append(title)
            }
            // 剩余 title 保持首次出现顺序
            for title in titleOrder where remaining.contains(title) {
                ordered.append(title)
            }
            return ordered
        }()

        return orderedTitles.flatMap { title in
            grouped[title]!.sorted {
                ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude)
            }
        }
    }

    /// 根据用户自定义的额度对象顺序，取"排第一的订阅组里剩余比例最低的对象"决定状态灯颜色。
    ///
    /// 多订阅组（如 MiniMax 的 General / Video、Antigravity 的 Gemini / Other）→ 按用户拖拽顺序取
    /// 排第一的订阅组，再取该组最差那条；单一订阅组（Codex / Kimi 整组）→ 取整组最差那条。
    /// 拖拽排序同时影响 dropdown 展示顺序和 bar/灯取值。
    func statusColor(itemOrder: [String]) -> Color {
        switch availability {
        case .loading:
            // 正在刷新中：灰色"未知"灯，区别于 needsConfiguration（也是灰，但含义不同）。
            return Color(hex: "#8E8E93")
        case .available:
            let worstFraction = primarySubscriptionGroupWorstQuota(itemOrder: itemOrder)?.remainingFraction ?? 1.0
            if worstFraction == 0 {
                return Color.red
            } else if worstFraction <= 0.3 {
                return Color.orange
            } else {
                return Color.green
            }
        case .needsConfiguration: return Color(hex: "#8E8E93")
        case .notInstalled: return Color(hex: "#8E8E93")
        case .fetchFailed: return Color(hex: "#FF9F0A")
        }
    }

    /// 兼容旧代码的便捷属性：使用空自定义顺序时的状态灯颜色。
    var statusColor: Color {
        statusColor(itemOrder: [])
    }

    /// 按用户自定义顺序排列额度对象；未在顺序中的对象按原顺序 appended。
    func orderedQuotas(customItemOrder: [String]) -> [QuotaWindow] {
        var ordered: [QuotaWindow] = []
        var remaining = quotas
        for key in customItemOrder {
            if let index = remaining.firstIndex(where: { $0.stableKey == key }) {
                ordered.append(remaining.remove(at: index))
            }
        }
        ordered.append(contentsOf: remaining)
        return ordered
    }

    /// 按 `subscriptionGroup`（fallback 到 `provider.kind.rawValue`）把 quota 窗口分组。
    ///
    /// 同一组内的 windows 共享"任一归零则全废"的语义（Kimi Code/Code/Work、Codex 5h/周 等）；
    /// 不同组之间是独立计费/独立额度池的订阅（MiniMax General/Video、Antigravity Gemini/Other）。
    ///
    /// `customOrder` 是**订阅组 key**顺序，不是 quota stableKey 顺序。组内 item 顺序由调用方
    /// 再使用 `quotaItemOrder` 控制；bar/灯只关心"第一组里的最差 quota"。
    func subscriptionGroups(customOrder: [String]) -> [(groupKey: String, items: [QuotaWindow])] {
        var groups: [String: [QuotaWindow]] = [:]
        var sourceOrder: [String] = []

        for quota in quotas {
            let key = normalizedSubscriptionGroup(for: quota)
            if groups[key] == nil {
                sourceOrder.append(key)
                groups[key] = []
            }
            groups[key]!.append(quota)
        }

        var remaining = Set(sourceOrder)
        var orderedKeys: [String] = []
        for key in customOrder where remaining.remove(key) != nil {
            orderedKeys.append(key)
        }
        for key in sourceOrder where remaining.contains(key) {
            orderedKeys.append(key)
        }

        return orderedKeys.map { key in
            let items = groups[key]!.sorted {
                ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude)
            }
            return (key, items)
        }
    }

    private func normalizedSubscriptionGroup(for quota: QuotaWindow) -> String {
        switch kind {
        case .kimi:
            // Kimi Work / Code 是同一个订阅池：Work 月额度、Code 周额度、Code 5h 任一归零都会影响整组。
            // 即使旧缓存或 fallback parser 曾写入 work/code，也在聚合层强制归一，避免 UI 拆成两组。
            return ProviderKind.kimi.rawValue
        case .codex:
            return ProviderKind.codex.rawValue
        default:
            let raw = quota.subscriptionGroup?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return raw.isEmpty ? kind.rawValue : raw
        }
    }

    /// 取最上方的额度对象（用于状态灯、菜单栏 bar 高度等）。
    func primaryQuota(itemOrder: [String]) -> QuotaWindow? {
        orderedQuotas(customItemOrder: itemOrder).first
    }

    /// 取用户排序后第一个订阅组（top subscription group）里剩余比例最低的 quota，
    /// 用于状态灯 / 菜单栏 bar 高度。
    ///
    /// 语义：
    /// - **多订阅组**（如 MiniMax 的 General / Video、Antigravity 的 Gemini / Other）→ 取用户拖拽后
    ///   排第一的订阅组，再取该组内剩余最低的那条；
    /// - **单订阅组**（Codex、Kimi 整组）→ 取整组最差那条（语义与"整组最差"一致）。
    ///
    /// 关键：**尊重用户排序**——用户把 General 拖到 Video 之前时，bar/灯会反映 General 的最差 quota，
    /// 而非"整 provider 最差"。这才是"基于排序取值"的正确语义。
    func primarySubscriptionGroupWorstQuota(itemOrder: [String]) -> QuotaWindow? {
        guard let firstGroup = subscriptionGroups(customOrder: itemOrder).first else { return nil }
        return firstGroup.items.min { $0.remainingFraction < $1.remainingFraction }
    }

    /// 取整组中剩余比例最低的额度对象（保留旧 API，备用）。
    ///
    /// **注意**：新代码优先用 `primarySubscriptionGroupWorstQuota`，它会在多订阅组时按用户
    /// 排序取第一个订阅组的最小值。本方法忽略订阅组边界和排序，直接取所有 quota 中最差的那条；
    /// 保留仅为兼容旧调用方。
    func worstQuota(itemOrder: [String]) -> QuotaWindow? {
        orderedQuotas(customItemOrder: itemOrder).min { $0.remainingFraction < $1.remainingFraction }
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

    @MainActor
    var availableCount: Int {
        // 与 dropdown 状态灯颜色保持完全一致——红灯（top group worst quota 已耗尽）
        // 不算"可用订阅"，避免出现"灯红但 N/M 不动"的割裂。
        // 多订阅组 provider 只看 top group（与 statusColor 逻辑一致）。
        snapshots.filter { snapshot in
            guard snapshot.availability == .available else { return false }
            let itemOrder = PreferencesStore.shared.subscriptionGroupOrder(for: snapshot.kind)
            guard let worst = snapshot.primarySubscriptionGroupWorstQuota(itemOrder: itemOrder) else {
                return false
            }
            return worst.remainingFraction > 0
        }.count
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

    @MainActor
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
        // Antigravity / Google AI 订阅档位（官网价格：Plus $4.99, Pro $19.99, Ultra $99.99）
        case (.antigravity, "plus"), (.gemini, "plus"):
            return 4.99  // Google AI Plus (400 GB)
        case (.antigravity, "pro"), (.gemini, "pro"):
            return 19.99  // Google AI Pro (5 TB)
        case (.antigravity, "ultra"), (.gemini, "ultra"):
            return 99.99  // Google AI Ultra (20 TB)
        // Kimi 订阅档位（官网价格：Andante ¥49, Moderato ¥99, Allegretto ¥199, Allegro ¥699）
        case (.kimi, "andante"):
            return 6.76  // ¥49
        case (.kimi, "moderato"):
            return 13.66  // ¥99
        case (.kimi, "allegretto"):
            return 27.45  // ¥199
        case (.kimi, "allegro"):
            return 96.41  // ¥699
        case (.kimi, "paid"), (.kimi, "trial"), (.kimi, "trial（已购）"):
            return 6.76  // 默认按 Andante 价格
        // MiniMax 订阅档位
        case (.minimax, "tokenplan"), (.minimax, "token plan"):
            return 5.0   // 估算价格
        case (.minimax, "plus"):
            return 10.0
        case (.minimax, "pro"):
            return 20.0
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
        let seconds = date.timeIntervalSince(now)
        if seconds <= 0 {
            return "已重置"
        }

        let totalSeconds = Int(seconds)
        let days = totalSeconds / (24 * 3600)
        let hours = (totalSeconds % (24 * 3600)) / 3600
        let minutes = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60

        if days >= 1 {
            return "\(days)d\(hours)h"
        } else if hours >= 1 {
            return "\(hours)h\(minutes)m"
        } else if minutes >= 1 {
            return "\(minutes)m\(secs)s"
        } else {
            return "0m\(secs)s"
        }
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
