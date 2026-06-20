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

    /// 自动刷新间隔（秒）。默认 5 分钟。
    var refreshIntervalSeconds: TimeInterval

    /// 浏览器 Cookie 来源偏好。
    var browserSource: BrowserSourcePreference

    /// 菜单栏图标展示模式。
    var iconMode: IconModePreference

    /// 是否启用 Provider 服务状态监控（incident 检测）。
    var incidentMonitoringEnabled: Bool

    /// 高级选项。
    var advanced: AdvancedPreferences

    init(
        providerOverrides: [ProviderOverride] = [],
        refreshIntervalSeconds: TimeInterval = 5 * 60,
        browserSource: BrowserSourcePreference = .auto,
        iconMode: IconModePreference = .combined,
        incidentMonitoringEnabled: Bool = false,
        advanced: AdvancedPreferences = AdvancedPreferences()
    ) {
        self.providerOverrides = providerOverrides
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.browserSource = browserSource
        self.iconMode = iconMode
        self.incidentMonitoringEnabled = incidentMonitoringEnabled
        self.advanced = advanced
    }
}

// MARK: - Provider 覆盖

/// 用户对单个 Provider 的手动覆盖。
///
/// - `isEnabled`：是否参与刷新与展示；关闭后即使本机已安装也不显示。
/// - `isForcedVisible`：是否强制显示该 Provider（即使未探测到）；
///   当前阶段仅做数据持久化，后续与「手动添加 Provider」流程对接。
struct ProviderOverride: Codable, Equatable, Identifiable, Sendable {
    var id: ProviderKind { kind }
    let kind: ProviderKind
    var isEnabled: Bool
    var isForcedVisible: Bool

    init(kind: ProviderKind, isEnabled: Bool = true, isForcedVisible: Bool = false) {
        self.kind = kind
        self.isEnabled = isEnabled
        self.isForcedVisible = isForcedVisible
    }
}

// MARK: - 浏览器来源

enum BrowserSourcePreference: String, Codable, CaseIterable, Sendable {
    case auto = "auto"
    case safari = "safari"
    case chrome = "chrome"
    case firefox = "firefox"

    var displayName: String {
        switch self {
        case .auto: return "自动（全部）"
        case .safari: return "Safari"
        case .chrome: return "Chrome"
        case .firefox: return "Firefox"
        }
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
        case .combined: return "单图标汇总"
        case .perProvider: return "多图标分 Provider（预留）"
        }
    }
}

// MARK: - 高级选项

struct AdvancedPreferences: Codable, Equatable, Sendable {
    /// 单次 provider 刷新超时（秒）。
    var providerTimeoutSeconds: TimeInterval

    /// 固定货币代码；`nil` 表示按系统 Locale 自动选择。
    var currencyCode: String?

    /// 是否在额度行展示重置日期。
    var showResetDates: Bool

    init(
        providerTimeoutSeconds: TimeInterval = 10,
        currencyCode: String? = nil,
        showResetDates: Bool = true
    ) {
        self.providerTimeoutSeconds = providerTimeoutSeconds
        self.currencyCode = currencyCode
        self.showResetDates = showResetDates
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

    init() {
        self.fileURL = PreferencesStore.preferencesFileURL()
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

    /// 该 Provider 是否被强制显示（无论是否探测到）。
    func isForcedVisible(kind: ProviderKind) -> Bool {
        override(for: kind)?.isForcedVisible ?? false
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

    func setForcedVisible(_ visible: Bool, for kind: ProviderKind) {
        ensureOverride(for: kind)
        if let index = preferences.providerOverrides.firstIndex(where: { $0.kind == kind }) {
            preferences.providerOverrides[index].isForcedVisible = visible
            _ = try? persist()
        }
    }

    func setRefreshInterval(_ seconds: TimeInterval) {
        preferences.refreshIntervalSeconds = max(60, min(3600, seconds))
        _ = try? persist()
    }

    func setBrowserSource(_ source: BrowserSourcePreference) {
        preferences.browserSource = source
        _ = try? persist()
    }

    func setIconMode(_ mode: IconModePreference) {
        preferences.iconMode = mode
        _ = try? persist()
    }

    func setIncidentMonitoringEnabled(_ enabled: Bool) {
        preferences.incidentMonitoringEnabled = enabled
        _ = try? persist()
    }

    func setAdvanced(_ advanced: AdvancedPreferences) {
        preferences.advanced = advanced
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
}
