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

    /// 新一轮刷新周期开始时调用一次（`RefreshCoordinator.runRefreshCycle()` 最开头，
    /// 早于任何 provider 的 `record`/`flush`）：写入一条
    /// `[刷新额度] <手动刷新/自动刷新> - 时间戳` 分隔头，保证这一轮所有 provider 的
    /// 日志行都紧跟在这条头的后面；同时按 `retainCycles` 裁掉最旧的整轮记录
    /// （2026-07-10 用户反馈：日志应该按刷新轮次分隔展示、且可配置保留最近几轮；
    /// 2026-07-11 追加：分隔头要标明这轮是手动触发还是自动周期触发）。
    func beginCycle(triggerLabel: String, retainCycles: Int) {
        store.beginCycle(triggerLabel: triggerLabel, retainCycles: retainCycles)
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
                // 单轮里正常不会有几千行，这只是防御性兜底（比如某个 provider 意外
                // 死循环狂写日志），真正的保留策略是 `beginCycle` 里按轮次裁剪。
                Self.truncateIfNeeded(fileURL: fileURL, maxLines: maxLines)
            } catch {
                NSLog("QuotaBar: provider check log write failed: \(error.localizedDescription)")
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .providerCheckLogDidChange, object: nil)
        }
    }

    /// 新一轮刷新周期开始：写入 `[刷新额度] <手动刷新/自动刷新> - <时间戳>` 分隔头，
    /// 并按 `retainCycles` 把最旧的整轮记录从磁盘裁掉。分隔头始终以 `cycleHeaderPrefix`
    /// （`[刷新额度]`）开头，`triggerLabel` 只是紧跟其后的可读补充，不影响
    /// `splitIntoCycles` 等基于前缀的切块逻辑。
    ///
    /// 头的前后没有写字面意义上的空行——`readRecentLines`/`truncateIfNeeded` 等
    /// 全部基于 `omittingEmptySubsequences: true` 的 `split`，字面空行在这条流水线
    /// 上会被直接吃掉，写了也白写。视觉上的"换行 + 换行"间隔改在
    /// `DiagnosticsSettingsView` 展示层对 header 行单独加大上下 padding 实现，
    /// 不依赖存储层保真空行这种脆弱的往返路径。
    func beginCycle(at date: Date = Date(), triggerLabel: String, retainCycles: Int) {
        let trimmedLabel = triggerLabel.trimmingCharacters(in: .whitespaces)
        let labelPart = trimmedLabel.isEmpty ? "" : " \(trimmedLabel)"
        let header = "\(Self.cycleHeaderPrefix)\(labelPart) - \(Self.headerFormatter.string(from: date))\n"
        queue.sync { [fileURL] in
            do {
                try QuotaBarDataDirectory.ensureExists(fileURL.deletingLastPathComponent())
                if FileManager.default.fileExists(atPath: fileURL.path),
                   let handle = try? FileHandle(forWritingTo: fileURL) {
                    try handle.seekToEnd()
                    if let data = header.data(using: .utf8) {
                        try handle.write(contentsOf: data)
                    }
                    try handle.close()
                } else {
                    try header.write(to: fileURL, atomically: true, encoding: .utf8)
                }
                Self.truncateToRecentCycles(fileURL: fileURL, retainCycles: retainCycles)
            } catch {
                NSLog("QuotaBar: provider check log begin cycle failed: \(error.localizedDescription)")
            }
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .providerCheckLogDidChange, object: nil)
        }
    }

    /// 读取最近 `limit` 行（默认全部），用于 Preferences 展示。
    ///
    /// 按 `[刷新额度]` 分隔头把文件切成一轮一轮的区块，轮次**内部**保持原有的
    /// "谁先完成谁先出现"顺序，轮次**之间**按"最新的轮次在最上面"重新排列——
    /// 物理文件仍然是自然追加顺序（旧轮次先写在前面），只在读出来展示时反转轮次
    /// 顺序，不需要改动写入逻辑（2026-07-10 用户反馈"确保新的在上面"）。
    func readRecentLines(limit: Int = 2000) -> [String] {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return [] }
        let allLines = content.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        let newestFirst = Self.splitIntoCycles(allLines).reversed().flatMap { $0 }
        guard newestFirst.count > limit else { return newestFirst }
        return Array(newestFirst.prefix(limit))
    }

    func clear() {
        queue.sync { [fileURL] in
            try? FileManager.default.removeItem(at: fileURL)
        }
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .providerCheckLogDidChange, object: nil)
        }
    }

    private static let cycleHeaderPrefix = "[刷新额度]"

    private static let headerFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone.current
        f.dateFormat = "yyyy.MM.dd_HH.mm.ss"
        return f
    }()

    /// 按 `[刷新额度]` 头切块；旧日志文件里第一条头之前遗留的行（没有头，来自这个
    /// 功能上线之前）会被归到最前面的一个无头区块里，不丢数据。
    private static func splitIntoCycles(_ lines: [String]) -> [[String]] {
        var cycles: [[String]] = []
        var current: [String] = []
        for line in lines {
            if line.hasPrefix(cycleHeaderPrefix) {
                if !current.isEmpty { cycles.append(current) }
                current = [line]
            } else {
                current.append(line)
            }
        }
        if !current.isEmpty { cycles.append(current) }
        return cycles
    }

    private static func truncateToRecentCycles(fileURL: URL, retainCycles: Int) {
        guard retainCycles > 0, let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        let cycles = splitIntoCycles(lines)
        guard cycles.count > retainCycles else { return }
        let trimmed = cycles.suffix(retainCycles).flatMap { $0 }
        let text = trimmed.joined(separator: "\n") + "\n"
        try? text.write(to: fileURL, atomically: true, encoding: .utf8)
    }

    private static func truncateIfNeeded(fileURL: URL, maxLines: Int) {
        guard let content = try? String(contentsOf: fileURL, encoding: .utf8) else { return }
        let lines = content.split(separator: "\n", omittingEmptySubsequences: true)
        guard lines.count > maxLines else { return }
        let trimmed = lines.suffix(maxLines).joined(separator: "\n") + "\n"
        try? trimmed.write(to: fileURL, atomically: true, encoding: .utf8)
    }
}
