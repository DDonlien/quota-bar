import Foundation
import SwiftUI

// MARK: - 偏好设置模型

/// 用户可配置的 Quota Bar 偏好设置。
///
/// 设计目标：
/// - 支持 Provider 开关、刷新间隔、浏览器来源、图标模式等 P2 配置；
/// - 所有字段可序列化到 `~/Library/Application Support/QuotaBar/preferences.json`；
/// - 不存储任何凭证、Cookie、API key，只存开关与选项；
/// - 未来新增字段时保持向后兼容（Codable + default value）。
struct QuotaPreferences: Codable, Equatable, Sendable {
    /// 每个 Provider 的覆盖配置。
    var providerOverrides: [ProviderOverride]

    /// 每个 Provider 的 quota 组显示顺序（旧版分组排序，已废弃，保留以兼容旧配置）。
    /// Key 为 `ProviderKind.rawValue`，Value 为该 provider 下 quota title 的自定义顺序。
    /// 未出现的 title 按默认顺序排在后面。
    var quotaGroupOrder: [String: [String]]

    /// Provider 区块的显示顺序。
    /// 数组元素为 `ProviderKind.rawValue`，越靠前越靠上；未出现的 Provider 按 `kind.rawValue` 字母顺序排在后面。
    var providerOrder: [String]

    /// 每个 Provider 下具体额度对象的显示顺序。
    /// Key 为 `ProviderKind.rawValue`，Value 为该 provider 下额度对象的 `QuotaWindow.stableKey` 顺序。
    /// 未出现的对象按默认顺序排在后面。
    var quotaItemOrder: [String: [String]]

    /// 每个 Provider 下**订阅组**的自定义显示顺序。
    /// Key 为 `ProviderKind.rawValue`，Value 为该 provider 下 `QuotaWindow.subscriptionGroup` 的顺序。
    /// 决定状态栏 bar 高度和 dropdown 状态灯取值的"top subscription group"——
    /// 多订阅组 provider（MiniMax General/Video、Antigravity Gemini/Other）拖拽排序后立即生效。
    /// 单订阅组 provider（Codex/Kimi）只有一个组，排序无视觉差异但语义保留。
    var subscriptionGroupOrder: [String: [String]]

    /// 自动刷新间隔（秒）。默认 5 分钟。
    var refreshIntervalSeconds: TimeInterval

    /// 界面语言偏好。
    var language: LanguagePreference

    /// 菜单栏图标展示模式。
    var iconMode: IconModePreference

    /// 高级选项。
    var advanced: AdvancedPreferences

    /// 是否在用户登录 macOS 后自动启动 Quota Bar。
    /// 通过 `SMAppService.mainApp.register()` / `.unregister()` 落地。
    /// 字段新增于 v0.3.0-PM-A-007，向后兼容（旧配置反序列化时获得 `false`）。
    var launchAtLogin: Bool

    /// 激活邮箱。当前激活体系尚未接入后端，只持久化用户输入。
    var activationEmail: String

    /// 上一次成功检查更新的时间（v0.11.0-FE-A-007，5 分钟内不重复请求 GitHub API）。
    var lastUpdateCheck: Date?

    /// 用户点过「稍后提醒」的版本 tag 列表（v0.11.0-UI-A-002，24h 抑制在 UpdateChecker 内实现）。
    var ignoredVersions: [String]

    /// 是否启用 Claude Code `statusLine` hook 额度捕获（用户显式 opt-in）。
    /// 开启后往 `~/.claude/settings.json` 写入一个小脚本作为 statusLine 命令，
    /// 捕获 Claude Code 自己在终端状态栏渲染时携带的 `rate_limits` 数据到本地
    /// 缓存文件；关闭时移除该脚本（若用户已有其他 statusLine 配置则不会覆盖，
    /// 也不会移除）。见 `ClaudeStatusLineHookInstaller`。
    var claudeStatusLineHookEnabled: Bool

    init(
        providerOverrides: [ProviderOverride] = [],
        quotaGroupOrder: [String: [String]] = [:],
        providerOrder: [String] = [],
        quotaItemOrder: [String: [String]] = [:],
        subscriptionGroupOrder: [String: [String]] = [:],
        refreshIntervalSeconds: TimeInterval = 5 * 60,
        language: LanguagePreference = .chinese,
        iconMode: IconModePreference = .combined,
        advanced: AdvancedPreferences = AdvancedPreferences(),
        launchAtLogin: Bool = false,
        activationEmail: String = "",
        lastUpdateCheck: Date? = nil,
        ignoredVersions: [String] = [],
        claudeStatusLineHookEnabled: Bool = false
    ) {
        self.providerOverrides = providerOverrides
        self.quotaGroupOrder = quotaGroupOrder
        self.providerOrder = providerOrder
        self.quotaItemOrder = quotaItemOrder
        self.subscriptionGroupOrder = subscriptionGroupOrder
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.language = language
        self.iconMode = iconMode
        self.advanced = advanced
        self.launchAtLogin = launchAtLogin
        self.activationEmail = activationEmail
        self.lastUpdateCheck = lastUpdateCheck
        self.ignoredVersions = ignoredVersions
        self.claudeStatusLineHookEnabled = claudeStatusLineHookEnabled
    }

    enum CodingKeys: String, CodingKey {
        case providerOverrides
        case quotaGroupOrder
        case providerOrder
        case quotaItemOrder
        case subscriptionGroupOrder
        case refreshIntervalSeconds
        case language
        case iconMode
        case advanced
        case launchAtLogin
        case activationEmail
        case lastUpdateCheck
        case ignoredVersions
        case claudeStatusLineHookEnabled
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            providerOverrides: try container.decodeIfPresent([ProviderOverride].self, forKey: .providerOverrides) ?? [],
            quotaGroupOrder: try container.decodeIfPresent([String: [String]].self, forKey: .quotaGroupOrder) ?? [:],
            providerOrder: try container.decodeIfPresent([String].self, forKey: .providerOrder) ?? [],
            quotaItemOrder: try container.decodeIfPresent([String: [String]].self, forKey: .quotaItemOrder) ?? [:],
            subscriptionGroupOrder: try container.decodeIfPresent([String: [String]].self, forKey: .subscriptionGroupOrder) ?? [:],
            refreshIntervalSeconds: try container.decodeIfPresent(TimeInterval.self, forKey: .refreshIntervalSeconds) ?? 5 * 60,
            language: try container.decodeIfPresent(LanguagePreference.self, forKey: .language) ?? .chinese,
            iconMode: try container.decodeIfPresent(IconModePreference.self, forKey: .iconMode) ?? .combined,
            advanced: try container.decodeIfPresent(AdvancedPreferences.self, forKey: .advanced) ?? AdvancedPreferences(),
            launchAtLogin: try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false,
            activationEmail: try container.decodeIfPresent(String.self, forKey: .activationEmail) ?? "",
            lastUpdateCheck: try container.decodeIfPresent(Date.self, forKey: .lastUpdateCheck),
            ignoredVersions: try container.decodeIfPresent([String].self, forKey: .ignoredVersions) ?? [],
            claudeStatusLineHookEnabled: try container.decodeIfPresent(Bool.self, forKey: .claudeStatusLineHookEnabled) ?? false
        )
    }
}

// MARK: - 语言

enum LanguagePreference: String, Codable, CaseIterable, Sendable {
    case chinese = "zh-Hans"
    case english = "en"

    var displayName: String {
        switch self {
        case .chinese: return "中文"
        case .english: return "English"
        }
    }
}

// MARK: - Provider 覆盖

/// 用户对单个 Provider 的手动覆盖。
///
/// - `isEnabled`：是否参与刷新与展示；关闭后即使本机已安装也不显示。
struct ProviderOverride: Codable, Equatable, Identifiable, Sendable {
    var id: ProviderKind { kind }
    let kind: ProviderKind
    var isEnabled: Bool

    init(kind: ProviderKind, isEnabled: Bool = true) {
        self.kind = kind
        self.isEnabled = isEnabled
    }
}

// MARK: - 图标模式

enum IconModePreference: String, Codable, CaseIterable, Sendable {
    /// 单图标汇总：当前行为，画 N 个 bar 汇总所有可用订阅。
    case combined = "combined"
    /// 多图标分 Provider：每个 Provider 一个独立状态栏图标。
    /// 当前阶段仅持久化该选项，UI 实现延后。
    case perProvider = "perProvider"

    var displayName: String {
        switch self {
        case .combined: return "合并"
        case .perProvider: return "拆分"
        }
    }
}

// MARK: - 刷新间隔

/// 偏好窗口里「刷新间隔」下拉框的 4 个固定选项。
///
/// v0.3.0-PM-A-008 引入：从连续的 slider（1-60 分钟）改为离散下拉。
/// 字段仍然存 `refreshIntervalSeconds: TimeInterval`（向后兼容老 JSON），
/// `from(seconds:)` 用最接近法迁移老值。
enum RefreshIntervalOption: Int, CaseIterable, Identifiable, Codable, Sendable {
    case oneMinute = 60
    case fiveMinutes = 300
    case tenMinutes = 600
    case thirtyMinutes = 1800

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .oneMinute: return "1 分钟"
        case .fiveMinutes: return "5 分钟"
        case .tenMinutes: return "10 分钟"
        case .thirtyMinutes: return "30 分钟"
        }
    }

    var seconds: TimeInterval { TimeInterval(rawValue) }

    /// 从任意 seconds 找最近的 option（迁移老 slider 值到新 picker）。
    static func nearest(to seconds: TimeInterval) -> RefreshIntervalOption {
        allCases.min(by: { abs($0.seconds - seconds) < abs($1.seconds - seconds) }) ?? .fiveMinutes
    }
}

// MARK: - 高级选项

struct AdvancedPreferences: Codable, Equatable, Sendable {
    /// 单次 provider 刷新超时（秒）。用于 `RefreshCoordinator.providerTimeout`——
    /// 2026-07-08 之前这个字段虽然存在，但没有任何 UI 暴露、也没有被
    /// `RefreshCoordinator` 读取过，后者一直用自己构造函数的硬编码默认值（10 秒），
    /// 两边完全不同步（跟当时的 `refreshIntervalSeconds` 是同一类"看着像接通了、
    /// 实际没有"的 bug）。现在正式接通：见 `GeneralSettingsView` 的高级设置区
    /// 和 `RefreshCoordinator.applyProviderTimeoutChange()`。
    var providerTimeoutSeconds: TimeInterval

    /// 「日志」页诊断日志保留的刷新轮数（不是行数）。2026-07-10 用户反馈：日志之前
    /// 只按总行数截断（`ProviderCheckLogStore.maxLines`，4000 行），没有一个用户能
    /// 直接理解的"保留几轮"概念，而且默认无限攒到截断阈值才清；现在按轮次分隔
    /// （每轮开头有 `[刷新额度] - 时间戳` 标记），这里控制保留最近几轮，旧的整轮
    /// 直接从磁盘删掉。
    var logRetentionCycles: Int

    init(providerTimeoutSeconds: TimeInterval = 10, logRetentionCycles: Int = 20) {
        self.providerTimeoutSeconds = providerTimeoutSeconds
        self.logRetentionCycles = logRetentionCycles
    }

    enum CodingKeys: String, CodingKey {
        case providerTimeoutSeconds
        case logRetentionCycles
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            providerTimeoutSeconds: try container.decodeIfPresent(TimeInterval.self, forKey: .providerTimeoutSeconds) ?? 10,
            logRetentionCycles: try container.decodeIfPresent(Int.self, forKey: .logRetentionCycles) ?? 20
        )
    }
}

/// 偏好窗口里「Provider 刷新超时」下拉框的固定选项，跟 `RefreshIntervalOption`
/// 同一套设计（离散下拉而非连续 slider）。Antigravity 的 `antigravity-cli-session`
/// 策略内部预留的有效时间大约是 `timeout - 1` 秒（2 秒 settle + 轮询），10 秒的
/// 默认值对它来说余量很紧，系统稍有波动就可能超时——这正是新增这个可调选项的
/// 直接动机。
enum ProviderTimeoutOption: Int, CaseIterable, Identifiable, Codable, Sendable {
    case tenSeconds = 10
    case fifteenSeconds = 15
    case twentySeconds = 20
    case thirtySeconds = 30

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .tenSeconds: return "10 秒"
        case .fifteenSeconds: return "15 秒"
        case .twentySeconds: return "20 秒"
        case .thirtySeconds: return "30 秒"
        }
    }

    var seconds: TimeInterval { TimeInterval(rawValue) }

    static func nearest(to seconds: TimeInterval) -> ProviderTimeoutOption {
        allCases.min(by: { abs($0.seconds - seconds) < abs($1.seconds - seconds) }) ?? .tenSeconds
    }
}

/// 「日志」页「保留轮数」下拉框的固定选项，跟 `RefreshIntervalOption`/
/// `ProviderTimeoutOption` 同一套设计。
enum LogRetentionOption: Int, CaseIterable, Identifiable, Codable, Sendable {
    case one = 1
    case two = 2
    case five = 5
    case ten = 10
    case twenty = 20
    case fifty = 50

    var id: Int { rawValue }

    var displayName: String {
        switch self {
        case .one: return "1 轮"
        case .two: return "2 轮"
        case .five: return "5 轮"
        case .ten: return "10 轮"
        case .twenty: return "20 轮"
        case .fifty: return "50 轮"
        }
    }

    static func nearest(to cycles: Int) -> LogRetentionOption {
        allCases.min(by: { abs($0.rawValue - cycles) < abs($1.rawValue - cycles) }) ?? .twenty
    }
}

// MARK: - 偏好设置持久化

/// 管理 `QuotaPreferences` 的读取、写入与发布。
///
/// 采用 `@MainActor` + `@Observable`（SwiftUI）模式，让偏好设置变化能自动驱动 UI。
@MainActor
@Observable
final class PreferencesStore {
    static let shared = PreferencesStore()

    private(set) var preferences: QuotaPreferences

    /// 文件变更通知的发布者，供需要显式监听的业务对象使用。
    let preferencesDidChange = NotificationCenter.default.publisher(
        for: .quotaPreferencesDidChange
    )

    private let fileURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    convenience init() {
        self.init(fileURL: PreferencesStore.preferencesFileURL())
    }

    /// 测试专用入口：注入临时文件路径，避免测试读写真实用户的 `preferences.json`
    /// （`.shared` 单例硬编码真实路径，历史上没有其他 store 那样的临时目录注入支持，
    /// 这里补上，跟 `ProviderSourceIndexStore`/`ProviderSnapshotCacheStore` 的模式一致）。
    init(fileURL: URL) {
        self.fileURL = fileURL
        self.encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder.dateEncodingStrategy = .iso8601
        self.decoder.dateDecodingStrategy = .iso8601

        // 先尝试从磁盘读取；失败则使用默认配置并保存一份。
        if let stored = try? PreferencesStore.load(from: fileURL, using: decoder) {
            self.preferences = stored
            // 确保所有 Provider 都有覆盖项（新增 provider 时补齐）。
            self.preferences = Self.mergedWithDefaults(stored)
        } else {
            self.preferences = Self.defaultPreferences()
        }

        // 首次初始化时落盘，保证文件存在且格式正确。
        _ = try? save()
    }

    // MARK: - 读取辅助

    /// 该 Provider 是否被用户启用。
    func isEnabled(kind: ProviderKind) -> Bool {
        override(for: kind)?.isEnabled ?? true
    }

    /// 获取或创建某个 Provider 的覆盖配置。
    func override(for kind: ProviderKind) -> ProviderOverride? {
        preferences.providerOverrides.first { $0.kind == kind }
    }

    func setEnabled(_ enabled: Bool, for kind: ProviderKind) {
        ensureOverride(for: kind)
        if let index = preferences.providerOverrides.firstIndex(where: { $0.kind == kind }) {
            preferences.providerOverrides[index].isEnabled = enabled
            _ = try? persist()
        }
    }

    func setRefreshInterval(_ seconds: TimeInterval) {
        preferences.refreshIntervalSeconds = max(60, min(3600, seconds))
        _ = try? persist()
    }

    /// v0.3.0-PM-A-008：用 RefreshIntervalOption 替代连续 slider。底层字段仍是
    /// `refreshIntervalSeconds`，保持 preferences.json 向后兼容。
    func setRefreshInterval(_ option: RefreshIntervalOption) {
        setRefreshInterval(option.seconds)
    }

    /// 偏好窗口读取当前刷新间隔的最近 option。slider 时代（1-60 分钟连续）的
    /// 老配置会被吸附到最接近的离散 option 上，UI 上不会出错。
    var currentRefreshIntervalOption: RefreshIntervalOption {
        RefreshIntervalOption.nearest(to: preferences.refreshIntervalSeconds)
    }

    func setLanguage(_ language: LanguagePreference) {
        preferences.language = language
        _ = try? persist()
    }

    func setIconMode(_ mode: IconModePreference) {
        preferences.iconMode = mode
        _ = try? persist()
    }

    /// 切换 Claude Code statusLine hook；实际的 install/uninstall 副作用由调用方
    /// （UI 层）在切换后调用 `ClaudeStatusLineHookInstaller` 执行，这里只持久化开关状态。
    func setClaudeStatusLineHookEnabled(_ enabled: Bool) {
        preferences.claudeStatusLineHookEnabled = enabled
        _ = try? persist()
    }

    func setProviderTimeout(_ seconds: TimeInterval) {
        preferences.advanced.providerTimeoutSeconds = max(5, min(120, seconds))
        _ = try? persist()
    }

    func setProviderTimeout(_ option: ProviderTimeoutOption) {
        setProviderTimeout(option.seconds)
    }

    func setLogRetentionCycles(_ cycles: Int) {
        preferences.advanced.logRetentionCycles = max(1, min(500, cycles))
        _ = try? persist()
    }

    func setLogRetentionCycles(_ option: LogRetentionOption) {
        setLogRetentionCycles(option.rawValue)
    }

    var currentLogRetentionOption: LogRetentionOption {
        LogRetentionOption.nearest(to: preferences.advanced.logRetentionCycles)
    }

    var currentProviderTimeoutOption: ProviderTimeoutOption {
        ProviderTimeoutOption.nearest(to: preferences.advanced.providerTimeoutSeconds)
    }

    /// 设置是否在登录时启动。落地逻辑由调用方负责（`SMAppService`），本方法只持久化。
    func setLaunchAtLogin(_ enabled: Bool) {
        preferences.launchAtLogin = enabled
        _ = try? persist()
    }

    // MARK: - 更新检查（v0.11.0）

    func setLastUpdateCheck(_ date: Date?) {
        preferences.lastUpdateCheck = date
        _ = try? persist()
    }

    func ignoreVersion(_ tag: String) {
        guard !preferences.ignoredVersions.contains(tag) else { return }
        preferences.ignoredVersions.append(tag)
        _ = try? persist()
    }

    func resetIgnoredVersions() {
        preferences.ignoredVersions = []
        _ = try? persist()
    }

    func setActivationEmail(_ email: String) {
        preferences.activationEmail = email
        _ = try? persist()
    }

    /// 获取某个 Provider 的 quota 组显示顺序。
    func quotaGroupOrder(for kind: ProviderKind) -> [String] {
        preferences.quotaGroupOrder[kind.rawValue] ?? []
    }

    /// 设置某个 Provider 的 quota 组显示顺序。
    func setQuotaGroupOrder(_ order: [String], for kind: ProviderKind) {
        preferences.quotaGroupOrder[kind.rawValue] = order
        _ = try? persist()
    }

    /// 获取 Provider 区块的自定义显示顺序。
    func providerOrder() -> [String] {
        preferences.providerOrder
    }

    /// 设置 Provider 区块的自定义显示顺序。
    func setProviderOrder(_ order: [String]) {
        preferences.providerOrder = order
        _ = try? persist()
    }

    /// 获取某个 Provider 下具体额度对象的显示顺序。
    func quotaItemOrder(for kind: ProviderKind) -> [String] {
        preferences.quotaItemOrder[kind.rawValue] ?? []
    }

    /// 设置某个 Provider 下具体额度对象的显示顺序。
    func setQuotaItemOrder(_ order: [String], for kind: ProviderKind) {
        preferences.quotaItemOrder[kind.rawValue] = order
        _ = try? persist()
    }

    /// 获取某个 Provider 下**订阅组**的自定义显示顺序。
    func subscriptionGroupOrder(for kind: ProviderKind) -> [String] {
        preferences.subscriptionGroupOrder[kind.rawValue] ?? []
    }

    /// 设置某个 Provider 下**订阅组**的自定义显示顺序。
    func setSubscriptionGroupOrder(_ order: [String], for kind: ProviderKind) {
        preferences.subscriptionGroupOrder[kind.rawValue] = order
        _ = try? persist()
    }

    func resetToDefaults() {
        preferences = Self.defaultPreferences()
        _ = try? persist()
    }

    // MARK: - 持久化

    @discardableResult
    func save() throws -> Bool {
        try persist()
        return true
    }

    @discardableResult
    private func persist() throws -> Bool {
        let data = try encoder.encode(preferences)
        let directory = fileURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try data.write(to: fileURL, options: .atomic)
        NotificationCenter.default.post(name: .quotaPreferencesDidChange, object: nil)
        return true
    }

    // MARK: - Private helpers

    private func ensureOverride(for kind: ProviderKind) {
        guard preferences.providerOverrides.first(where: { $0.kind == kind }) == nil else { return }
        preferences.providerOverrides.append(ProviderOverride(kind: kind))
    }

    private static func defaultPreferences() -> QuotaPreferences {
        QuotaPreferences()
    }

    /// 把已持久化的偏好与当前所有 ProviderKind 合并，确保新增 kind 有默认覆盖项。
    private static func mergedWithDefaults(_ existing: QuotaPreferences) -> QuotaPreferences {
        var merged = existing
        let existingKinds = Set(existing.providerOverrides.map(\.kind))
        for kind in ProviderKind.allCases where !existingKinds.contains(kind) {
            merged.providerOverrides.append(ProviderOverride(kind: kind))
        }
        return merged
    }

    private static func preferencesFileURL() -> URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return appSupport.appendingPathComponent("QuotaBar/preferences.json")
    }

    private static func load(from url: URL, using decoder: JSONDecoder) throws -> QuotaPreferences {
        let data = try Data(contentsOf: url)
        return try decoder.decode(QuotaPreferences.self, from: data)
    }
}

// MARK: - 通知

extension Notification.Name {
    static let quotaPreferencesDidChange = Notification.Name("com.quotabar.preferencesDidChange")

    /// 用户在「偏好设置 → 模型」里手动保存/更新了某个 provider 的 API key（不是
    /// `QuotaPreferences` 里的字段，是外部凭证文件，所以单独一个通知，不复用
    /// `.quotaPreferencesDidChange`）。`RefreshCoordinator` 订阅后立即触发一次刷新，
    /// 不用等下一个自动周期——跟 `.webAuthorizationWindowDidClose` 是同一类"用户刚
    /// 做完授权动作，应该立刻看到结果"诉求。
    static let providerCredentialsDidChange = Notification.Name("com.quotabar.providerCredentialsDidChange")

    /// 「偏好设置 → 日志」页的「刷新」按钮点击。这个按钮此前只是重新读一遍已经落盘
    /// 的日志文件——如果后台没有恰好在这之前跑完一轮真实刷新，点了跟没点一样，
    /// 看起来像坏了（2026-07-08 用户反馈"日志里的刷新按钮没用"）。`RefreshCoordinator`
    /// 订阅后触发一次真正的 `refreshNow()`，日志页面本身已经在监听
    /// `.providerCheckLogDidChange`，新日志写入时会自动跟着刷新，不需要日志页自己
    /// 再手动重读一次。
    static let manualRefreshRequested = Notification.Name("com.quotabar.manualRefreshRequested")
}
