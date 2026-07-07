import Foundation

/// MethodName 统一分类标签——不用各个 strategy 自己的 id（如 `kimi-desktop-token`，
/// 单看名字猜不出它到底是配置文件、CLI 还是 API），而是映射到 README 五级来源排序
/// 里的同一套词汇。具体是哪个 strategy、走的什么路径，放在 `result` 里说清楚，
/// 不需要靠 MethodName 猜。
extension ProviderSourceKind {
    var checkLogLabel: String {
        switch self {
        case .appBundle: return "App Bundle"
        case .configFile, .api: return "配置/凭证 → API"
        case .cli: return "CLI 命令"
        case .rpc: return "本地 App / RPC"
        case .browserCookie: return "浏览器 Cookie"
        case .webViewSession: return "App WebView 会话"
        case .keychain: return "Keychain"
        case .localLog: return "本地日志估算"
        case .environment: return "环境变量"
        case .unknown: return "未知来源"
        }
    }
}

extension SubscriptionExpirySourceKind {
    /// 复用同一套分类词汇，跟额度/档位/安装层的 MethodName 保持一致的阅读体验。
    var checkLogLabel: String {
        switch self {
        case .api: return "配置/凭证 → API"
        case .appCache: return "本地 App / RPC"
        case .cli: return "CLI 命令"
        case .browserAPI: return "浏览器 Cookie / App WebView 会话"
        case .headlessDOM: return "浏览器 Cookie / App WebView 会话"
        }
    }
}

/// 分层获取诊断日志：记录每个 provider 在每一层（安装探测 / 额度获取 / 过期日获取 /
/// 档位与费用获取）里，每个具体方案（strategy）的执行结果。
///
/// 行格式（管道分隔，2026-07-07 按用户反馈从冒号/逗号混排改成这个更好扫读的版本）：
/// `<yyyy.mm.dd_hh.mm.ss> - <ProviderName> | <CheckStep> | <MethodName> | <成功/失败/跳过> | <详细内容>`
///
/// 排序规则：
/// 1. 同一个 ProviderName 的内容总是连续输出——由本 actor 按 kind 缓冲实现：
///    provider 之间在 `RefreshCoordinator` 里是并发跑的（`withTaskGroup`），如果每条
///    记录都立即落盘，不同 provider 的行会在物理上交错；这里改成每个 kind 一个内存
///    缓冲区，调用方在该 provider 本轮工作完全结束时调用 `flush(kind:)` 才整段落盘。
/// 2. Check step 按实际执行顺序输出、3. 同一 check step 里的 method name 按实际执行
///    顺序连续输出——这两条由调用方保证「按真实发生顺序调用 `record`」自然满足，
///    本 actor 只负责追加、不重排。
/// 4. 成败判断是独立的 `outcome` 字段（成功/失败/跳过），不用从自由文本里猜；
///    缓存命中/失效、抓取到的信息、失败原因等细节都在 `detail` 里明示。
actor ProviderCheckLog {
    static let shared = ProviderCheckLog()

    /// 对应 README「四层获取矩阵」：Provider 获取（安装探测）/ 额度获取 / 过期日获取 / 档位与费用获取。
    enum CheckStep: String {
        case provider = "Provider 获取"
        case quota = "额度获取"
        case expiration = "过期日获取"
        case plan = "档位与费用获取"
    }

    /// 独立的"结果"字段——跟自由文本的 `detail` 分开，方便一眼扫过去看成败，
    /// 不用从长句子里找"成功"/"失败"字样（2026-07-07 用户反馈原格式不好读）。
    enum Outcome: String {
        case success = "成功"
        case failure = "失败"
        /// 明确没有尝试（已经命中同类候选、该层无来源可配置等），不算成败。
        case skipped = "跳过"
    }

    private var buffers: [ProviderKind: [String]] = [:]
    private let store: ProviderCheckLogStore

    init(store: ProviderCheckLogStore = .shared) {
        self.store = store
    }

    /// 格式：`<时间戳> - <ProviderName> | <CheckStep> | <MethodName> | <成功/失败/跳过> | <详细内容>`。
    func record(kind: ProviderKind, step: CheckStep, method: String, outcome: Outcome, detail: String) {
        let timestamp = Self.formatter.string(from: Date())
        let line = "\(timestamp) - \(kind.displayName) | \(step.rawValue) | \(method) | \(outcome.rawValue) | \(detail)"
        buffers[kind, default: []].append(line)
    }

    /// 把该 provider 本轮缓冲的全部行一次性落盘（保持内部追加顺序），并清空缓冲区。
    @discardableResult
    func flush(kind: ProviderKind) -> [String] {
        let lines = buffers.removeValue(forKey: kind) ?? []
        guard !lines.isEmpty else { return [] }
        store.append(lines: lines)
        return lines
    }

    static func resetForTesting() async {
        await shared.reset()
    }

    private func reset() {
        buffers.removeAll()
    }

    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy.MM.dd_HH.mm.ss"
        return f
    }()
}

extension Notification.Name {
    /// 日志文件内容发生变化（追加或清空）——Preferences 的「日志」页订阅它才能在
    /// 停留在该页面时也实时刷新，不用切一次 tab 才看到新内容。
    static let providerCheckLogDidChange = Notification.Name("com.quotabar.providerCheckLogDidChange")
}

/// 落盘 + 读取，供 Preferences 里的「获取日志」页面展示。
/// 单独的类（而不是塞进 `ProviderCheckLog` actor）方便测试时注入临时目录。
final class ProviderCheckLogStore: @unchecked Sendable {
    static let shared = ProviderCheckLogStore()

    private let fileURL: URL
    private let queue = DispatchQueue(label: "quota-bar.provider-check-log")
    /// 超过这个行数就从头截断，避免长期挂机日志文件无限增长。
    private let maxLines: Int

    init(
        fileURL: URL = ProviderCheckLogStore.defaultURL,
        maxLines: Int = 4000
    ) {
        self.fileURL = fileURL
        self.maxLines = maxLines
    }

    static var defaultURL: URL {
        QuotaBarDataDirectory.defaultURL()
            .appendingPathComponent("provider-check.log")
    }

    func append(lines: [String]) {
        guard !lines.isEmpty else { return }
        // 同步落盘（而不是 `queue.async`）：调用方（`ProviderCheckLog` actor 的
        // `flush`）本身已经在后台 Task 里，没有必要再引入一层异步——同步写入让
        // "flush 完成后立刻能读到" 这件事可验证、可测试，避免测试和真实使用中
        // 出现"日志还没写完就去读"的竞态。
        queue.sync { [fileURL, maxLines] in
            do {
                try QuotaBarDataDirectory.ensureExists(fileURL.deletingLastPathComponent())
                let text = lines.joined(separator: "\n") + "\n"
                if FileManager.default.fileExists(atPath: fileURL.path),
                   let handle = try? FileHandle(forWritingTo: fileURL) {
                    try handle.seekToEnd()
                    if let data = text.data(using: .utf8) {
                        try handle.write(contentsOf: data)
                    }
                    try handle.close()
                } else {
                    try text.write(to: fileURL, atomically: true, encoding: .utf8)
                }
                Self.truncateIfNeeded(fileURL: fileURL, maxLines: maxLines)
            } catch {
                NSLog("QuotaBar: provider check log write failed: \(error.localizedDescription)")
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .providerCheckLogDidChange, object: nil)
        }
    }

    /// 读取最近 `limit` 行（默认全部），用于 Preferences 展示。
    func readRecentLines(limit: Int = 2000) -> [String] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        guard lines.count > limit else { return lines }
        return Array(lines.suffix(limit))
    }

    func clear() {
        queue.sync { [fileURL] in
            try? FileManager.default.removeItem(at: fileURL)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .providerCheckLogDidChange, object: nil)
        }
    }

    private static func truncateIfNeeded(fileURL: URL, maxLines: Int) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        guard lines.count > maxLines else { return }
        let trimmed = lines.suffix(maxLines).joined(separator: "\n") + "\n"
        try? trimmed.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
