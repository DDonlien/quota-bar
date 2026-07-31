import SwiftUI

/// 「获取日志」偏好页：展示 `ProviderCheckLog` 落盘的分层获取诊断日志。
///
/// 每一行格式：`<时间戳> - <ProviderName>: <CheckStep>, <MethodName>: <Result>`——
/// 见 `ProviderCheckLog` 的规则说明。这里只负责只读展示 + 刷新 + 清空 + 复制，
/// 不做任何过滤/搜索（先满足"能看到真实执行顺序"这个核心诉求，复杂交互按需再加）。
struct DiagnosticsSettingsView: View {
    @State private var lines: [String] = []
    @State private var store = PreferencesStore.shared

    var body: some View {
        SettingsPage(.diagnostics) {
            VStack(alignment: .leading, spacing: 12) {
                SettingsSection("分层获取诊断日志") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("按 provider 分组、按检查层（Provider 获取 → 额度获取 → 过期日获取 → 档位与费用获取）与实际执行顺序记录每个方案的结果，用于排查「为什么这个 provider 没数据」。")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: 8) {
                            // 此前这个按钮只是重新读一遍已经落盘的日志文件——如果
                            // 后台没有恰好在点击前跑完一轮真实刷新，点了跟没点一样，
                            // 看起来像坏了（2026-07-08 用户反馈）。改成触发一次真正
                            // 的额度刷新；日志本身会随刷新过程逐条实时写入并自动
                            // 展示（见下方 `.providerCheckLogDidChange` 订阅），不需要
                            // 这个按钮自己再手动重读。
                            Button("立即刷新") { requestRefresh() }
                            Button("复制全部") { copyAll() }
                            Button("清空") { clearAll() }
                            Spacer()
                            Picker("", selection: bindingLogRetention) {
                                ForEach(LogRetentionOption.allCases) { option in
                                    Text("保留 \(option.displayName)").tag(option)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(.menu)
                            .fixedSize()
                            .controlSize(.small)
                            Text("\(lines.count) 行")
                                .font(.system(size: 11))
                                .foregroundStyle(.secondary)
                        }

                        logView
                    }
                    .padding(12)
                }
            }
        }
        .onAppear { reload() }
        .onReceive(NotificationCenter.default.publisher(for: .providerCheckLogDidChange)) { _ in
            reload()
        }
    }

    private var logView: some View {
        ScrollView {
            // `LazyVStack`（不是 `VStack`）：日志最多可以有 2000 行（`readRecentLines`
            // 默认 limit），`VStack` 会把全部 2000 个 `Text` 行立即创建/布局，不管当前
            // 视口（360pt 高，实际只显示约 25 行）能不能看到——每次 `.providerCheckLogDidChange`
            // 通知触发 `reload()`（一次刷新周期里最多 7 个 provider 各触发一次）都要重新
            // 铺满这 2000 个视图，是"日志页特别卡"的真正原因（2026-07-08 用户反馈，机器
            // 配置很高、其余页面都不卡，明确指向这个页面自己的渲染开销）。`LazyVStack`
            // 只创建实际进入视口的行，滚动/刷新开销跟总行数基本无关。
            LazyVStack(alignment: .leading, spacing: 1) {
                if lines.isEmpty {
                    Text("暂无日志——刷新一次额度后回到这里查看。")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(Self.rows(from: lines)) { row in
                        // 刷新轮次分隔头（`[刷新额度] … - 时间戳`）单独加大上下 padding、
                        // 加粗——存储层没有保真字面空行（见 `ProviderCheckLogStore.
                        // beginCycle` 顶部说明），视觉上的"换行 + 换行"间隔在这里实现。
                        // 同一轮内不同 provider 之间也补一段上间距，便于分组阅读
                        // （2026-07-11 用户反馈：provider 之间要有换行便于阅读）。
                        Self.styledText(for: row)
                            .font(.system(size: 10.5, weight: row.isHeader ? .semibold : .regular, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(.top, row.topGap)
                            .padding(.bottom, row.isHeader ? 4 : 0)
                    }
                }
            }
            // 不管有没有内容都强制撑满宽度——清空后如果只剩一行短提示文字，
            // 没有这个约束的话 VStack/ScrollView 会收缩到刚好包住那行字的宽度，
            // 让整个设置页突然变窄、很难看。
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .frame(height: 360)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    private func reload() {
        lines = ProviderCheckLogStore.shared.readRecentLines()
    }

    /// 一条可渲染的日志行。`id` 用序号保证 `ForEach` 稳定（同一行内容可能重复出现，
    /// 不能拿文本当 id）；`kind` 决定配色与字重。
    private struct LogRow: Identifiable {
        enum Kind {
            /// `[刷新额度] …` 轮次分隔头。
            case cycleHeader
            /// 展示层合成的 provider 分隔行（日志文件里没有这一行）。
            case providerHeader
            case entry
        }

        let id: Int
        let text: String
        let kind: Kind
        let topGap: CGFloat

        var isHeader: Bool { kind != .entry }
    }

    /// 把纯文本日志行转成带分组结构的 `LogRow`：
    /// - 轮次分隔头（`[刷新额度]` 开头）上方留 10pt（除第一行外）；
    /// - 同一轮内每当 provider 切换，**插入一条合成的 provider 分隔行**，其下才是
    ///   该 provider 的检查明细。
    ///
    /// **分隔行只在展示层合成，不写进日志文件**：这样「复制全部」导出的仍然是干净的
    /// 原始数据（不掺渲染用的装饰行），历史日志文件也能直接享受这个分组，不需要迁移。
    ///
    /// provider 名从行内 ` - <ProviderName> | …` 结构里解析；解析不出来（异常行）
    /// 时既不插分隔行也不额外留白，安全降级。
    private static func rows(from lines: [String]) -> [LogRow] {
        var result: [LogRow] = []
        result.reserveCapacity(lines.count)
        var previousProvider: String? = nil
        // 合成行会让下标跟原始行号错开，用独立自增计数器保证 id 唯一且稳定。
        var nextID = 0
        func append(_ text: String, _ kind: LogRow.Kind, _ topGap: CGFloat) {
            result.append(LogRow(id: nextID, text: text, kind: kind, topGap: topGap))
            nextID += 1
        }

        for (index, line) in lines.enumerated() {
            if line.hasPrefix("[刷新额度]") {
                append(line, .cycleHeader, index > 0 ? 10 : 0)
                // 新一轮开始，重置 provider 追踪：否则跨轮时同名 provider 会被当成
                // "没换人"，新一轮的第一个分隔行就丢了。
                previousProvider = nil
                continue
            }
            if let provider = providerName(from: line) {
                if provider != previousProvider {
                    append("▸ \(provider)", .providerHeader, previousProvider == nil ? 4 : 8)
                    previousProvider = provider
                }
                append(line, .entry, 0)
                continue
            }
            append(line, .entry, 0)
        }
        return result
    }

    /// 行配色（2026-07-27 用户反馈，07-30 按澄清改版）。
    ///
    /// - 轮次分隔头：accentColor（蓝），跟原来一致；
    /// - provider 分隔行：紫色加粗。刻意避开 accentColor——系统强调色对大多数人就是
    ///   蓝色，同色的话"这是新一轮"和"这是新 provider"两类锚点扫读时会糊成一片；
    /// - 明细行：primary，保持原样。第一版曾把每行里的 provider 名单独染成紫色，
    ///   用户指出那不是想要的效果——需要的是一条独立的分隔行，而不是满屏彩色词。
    @ViewBuilder
    private static func styledText(for row: LogRow) -> some View {
        switch row.kind {
        case .cycleHeader:
            Text(row.text).foregroundStyle(Color.accentColor)
        case .providerHeader:
            Text(row.text).foregroundStyle(Color.purple)
        case .entry:
            Text(row.text).foregroundStyle(Color.primary)
        }
    }

    /// 从 `<时间戳> - <ProviderName> | <CheckStep> | …` 里取出 `<ProviderName>`。
    private static func providerName(from line: String) -> String? {
        guard let dashRange = line.range(of: " - ") else { return nil }
        let afterDash = line[dashRange.upperBound...]
        guard let pipeRange = afterDash.range(of: " | ") else { return nil }
        return String(afterDash[..<pipeRange.lowerBound]).trimmingCharacters(in: .whitespaces)
    }

    private var bindingLogRetention: Binding<LogRetentionOption> {
        Binding(
            get: { store.currentLogRetentionOption },
            set: { store.setLogRetentionCycles($0) }
        )
    }

    private func requestRefresh() {
        NotificationCenter.default.post(name: .manualRefreshRequested, object: nil)
    }

    private func copyAll() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(lines.joined(separator: "\n"), forType: .string)
    }

    private func clearAll() {
        ProviderCheckLogStore.shared.clear()
        lines = []
    }
}

#Preview("Preferences - Diagnostics") {
    DiagnosticsSettingsView()
        .frame(width: 700, height: 560)
}
