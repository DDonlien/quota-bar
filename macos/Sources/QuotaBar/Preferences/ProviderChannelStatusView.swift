import SwiftUI

/// 「模型」页每个 provider 行展开后的渠道状态列表——回应用户诊断 Kimi「Work 成功、
/// Code 失败」时提出的诉求："应该在 preference 里面，去调整每个渠道获取的情况：
/// 1. 自动化获取的：正常显示。2. 没有获取到的：样式区分。3. Web view：未授权时
/// 可点击展开手动授权。"（见 REQUIREMENTS.md 0.14.0-FE-C-000 一节）
///
/// 数据完全来自已有的持久化状态（`ProviderSourceIndexStore` + `ProviderPipelines`
/// 静态声明），本视图不触发任何额外的额度请求。
struct ProviderChannelStatusList: View {
    let kind: ProviderKind

    @State private var channels: [ProviderPipelines.ProviderChannelDescriptor] = []
    @State private var recordsById: [String: ProviderSourceRecord] = [:]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if channels.isEmpty {
                Text("该 Provider 未声明任何额度获取渠道。")
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
            } else {
                ForEach(Array(channels.enumerated()), id: \.element.id) { index, channel in
                    if index > 0 { SettingsDivider() }
                    ProviderChannelRow(kind: kind, channel: channel, record: recordsById[channel.id])
                }
            }
        }
        .background(Color.primary.opacity(0.03))
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .providerSourceIndexDidChange)) { _ in
            reload()
        }
    }

    private func reload() {
        channels = ProviderPipelines.quotaChannels(for: kind)
        let records = ProviderSourceIndexStore.shared.records(for: kind, layer: .quota)
        recordsById = Dictionary(uniqueKeysWithValues: records.map { ($0.sourceId, $0) })
    }
}

private struct ProviderChannelRow: View {
    let kind: ProviderKind
    let channel: ProviderPipelines.ProviderChannelDescriptor
    let record: ProviderSourceRecord?

    /// 初始猜测：webview 渠道且从未成功过 → 先假定"待授权"，避免首帧闪一下
    /// "失败"文案再被 `.task` 的真实检查纠正——跟 `QuotaAuthPromptRow` 用
    /// `availableAuthRemediationTiers.first` 做初始同步猜测是同一个思路。
    /// 真正决定要不要展示"去授权"按钮的，是下面 `.task` 里对当前 WebView 会话
    /// 的实际检查，不是这个初始猜测本身。
    @State private var needsWebAuth: Bool

    init(kind: ProviderKind, channel: ProviderPipelines.ProviderChannelDescriptor, record: ProviderSourceRecord?) {
        self.kind = kind
        self.channel = channel
        self.record = record
        _needsWebAuth = State(initialValue: Self.isWebViewChannel(channel) && record?.succeededAt == nil)
    }

    private static func isWebViewChannel(_ channel: ProviderPipelines.ProviderChannelDescriptor) -> Bool {
        channel.sourceKind == .browserCookie || channel.sourceKind == .webViewSession
    }

    private var isWebViewChannel: Bool { Self.isWebViewChannel(channel) }

    private var isSuccess: Bool {
        guard let record else { return false }
        return record.succeededAt != nil && record.failureCount == 0
    }

    var body: some View {
        SettingsRow(
            label: {
                HStack(spacing: 8) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)
                    Text(Self.channelLabel(id: channel.id, kind: kind))
                        .font(.system(size: 12))
                }
            },
            subtitle: subtitleText,
            subtitleLeading: 14,
            horizontalPadding: 16,
            verticalPadding: 7,
            trailing: {
                // `&& !isSuccess` 是必要的兜底：`needsWebAuth` 由下面的 `.task` 异步
                // 刷新，`.task(id:)` 绑定的是 `record?.sourceId`（同一个渠道跨刷新
                // 周期不变），record 本身的 succeededAt/failureCount 变化不会让
                // `.task` 重新执行——如果不加这层判断，授权成功后的第一次重新渲染
                // 会短暂展示"已经成功却仍带着去授权按钮"的错误状态，直到某次刚好
                // 触发 `.task` 重跑才纠正过来。`isSuccess` 是每次 body 求值都会
                // 用最新 record 重算的计算属性，不存在这个滞后问题。
                if isWebViewChannel && needsWebAuth && !isSuccess {
                    Button("去授权") {
                        WebAuthorizationController.shared.openAuthorization(for: kind)
                    }
                    .font(.system(size: 11))
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.accentColor)
                }
            }
        )
        // 只有 webview 渠道才需要问"当前是否已授权"——这是唯一能可靠区分
        // "未授权导致的失败"（重新走一遍登录能修好）和"其他原因导致的失败"
        // （比如接口下线，重新登录也没用，见 0.14.0-BUG-B-001 里 kimi-webview
        // 曾经打一个 404 死接口的教训）的办法，不能只看"这个渠道有没有失败记录"
        // 就展示一个不一定管用的"去授权"入口。
        .task(id: record?.sourceId) {
            guard isWebViewChannel else { return }
            needsWebAuth = await !WKWebViewHeadlessLoader.appSessionHasCookies(for: kind.dashboardCookieDomains)
        }
    }

    private var statusColor: Color {
        if isSuccess { return .green }
        if isWebViewChannel && needsWebAuth { return .orange }
        return Color.secondary.opacity(0.5)
    }

    private var subtitleText: String {
        var parts: [String] = [channel.sourceKind.checkLogLabel]
        if isSuccess, let succeededAt = record?.succeededAt {
            parts.append("成功 · \(Self.relativeFormatter.localizedString(for: succeededAt, relativeTo: Date()))")
        } else if isWebViewChannel && needsWebAuth {
            parts.append("未授权 · 点击右侧按钮手动登录")
        } else if let summary = record?.lastErrorSummary {
            parts.append("失败 · \(summary)")
        } else {
            parts.append("尚未获取到")
        }
        return parts.joined(separator: " · ")
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    /// 从 strategy id 机械推导展示名：去掉 `"<kind>-"` 前缀、按 `-` 分词后 Title
    /// Case（如 `"kimi-desktop-token"` → `"Desktop Token"`）。不新建手工映射表——
    /// 这是诊断向的设置页，标签略技术化可以接受（「获取日志」页本来就直接展示
    /// 原始 strategy id），机械推导保证永远跟 id 本身同步，不会有第二份列表漂移。
    static func channelLabel(id: String, kind: ProviderKind) -> String {
        let prefix = "\(kind.rawValue)-"
        let suffix = id.hasPrefix(prefix) ? String(id.dropFirst(prefix.count)) : id
        return suffix
            .split(separator: "-")
            .map { $0.prefix(1).uppercased() + $0.dropFirst() }
            .joined(separator: " ")
    }
}

#Preview("Provider Channel Status") {
    ProviderChannelStatusList(kind: .kimi)
        .frame(width: 500)
        .padding()
}
