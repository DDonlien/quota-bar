import Foundation

// MARK: - 订阅日期抓取协议

/// 单个 provider 实现的「从订阅管理页提取续费日期」协议。
///
/// v0.6.0 起：headless 抓取订阅页拿真实订阅到期日（chatgpt.com/account、
/// claude.ai/settings、cursor.com/dashboard 等），取代之前从
/// `QuotaWindow.resetsAt.max()` 推断的乱写 fallback。
///
/// 工作流：
/// 1. `WKWebViewHeadlessLoader` 加载 `pageURL`（注入 cookie）
/// 2. 等 `WKNavigationDelegate.didFinish` 回调后 `evaluateJavaScript` 拿
///    `document.documentElement.outerHTML`
/// 3. 调用 `extract(from: pageSource)` 从 DOM 文本解析续费日期
///
/// 实现约束：
/// - `pageSource` 是 headless 渲染后的 outerHTML，包含 JavaScript 注入修改后的 DOM；
///   不能假设是 server-side HTML。
/// - 找不到日期返回 nil（UI hide），不要 throw。
/// - 抛 `QuotaFetchError.transient` 表示抓取阶段失败（不是解析失败）。
///
/// Kimi 这种 API 响应里直接有 `subscriptionBalance.expireTime` 的不走 headless，
/// 只在 `KimiSubscriptionStatParser.parseSubscriptionExpiresAt` 里取即可。
protocol SubscriptionDateHarvester: Sendable {
    /// 日志 / Debug 用的标识符，例如 "codex-harvester"。
    var identifier: String { get }

    /// 目标订阅管理页 URL。
    var pageURL: URL { get }

    /// 从 loader 抓到的页面 source（headless 渲染后的 outerHTML）提取续费日期。
    /// 找不到或无法解析时返回 nil（**不 throw**）。
    func extract(from pageSource: String) -> Date?
}

// MARK: - 默认实现辅助

extension SubscriptionDateHarvester {
    /// 在 pageSource 中查找第一个匹配 regex 的日期字符串，按 `candidates` 顺序尝试。
    ///
    /// `candidates` 形如：
    /// - ISO 8601：`"\\d{4}-\\d{2}-\\d{2}T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z?"`
    /// - 美式：`"\\b(?:Jan|Feb|...)\\s+\\d{1,2},\\s+\\d{4}\\b"`
    /// - 中文：`"\\d{4}年\\d{1,2}月\\d{1,2}日"`
    ///
    /// 返回第一个能 parse 成功的 `Date`；都失败返回 nil。
    func firstDate(in pageSource: String, candidates: [String]) -> Date? {
        let lower = pageSource.prefix(1_000_000)  // 限大页面避免卡
        for pattern in candidates {
            guard let regex = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(lower.startIndex..., in: lower)
            guard let match = regex.firstMatch(in: String(lower), range: range),
                  let r = Range(match.range, in: lower) else { continue }
            let raw = String(lower[r])
            if let date = parseLooseDate(raw) {
                return date
            }
        }
        return nil
    }

    /// 上下文敏感提取：在 pageSource 里找任一 `keyword`（大小写不敏感）后 `window` 字符内
    /// 第一个匹配的日期。
    ///
    /// 用法：避免页面上的"账号创建日 / 首次登录日 / 优惠到期"等无关日期被误识别为
    /// 「续费日」。每个 harvester 列出"真正表示续费"的关键词（"Next billing"、
    /// "Renews on" 等），只有匹配关键词附近的日期才会被采纳。
    ///
    /// 找完所有 keyword 都失败 → 返回 nil（**不** fallback 到无关键词的 `firstDate`，
    /// 否则可能抓到错误日期；harvester 的核心契约是"找不到就 nil"）。
    ///
    /// - Parameters:
    ///   - keywords: 大小写不敏感的关键词列表，按优先级排序。
    ///   - candidates: 日期 regex 列表，按优先级排序。
    ///   - window: 关键词后多少字符内查找（默认 100）。
    ///   - pageSource: headless 渲染后的 outerHTML。
    func extractNear(
        keywords: [String],
        candidates: [String],
        window: Int = 100,
        in pageSource: String
    ) -> Date? {
        for keyword in keywords {
            guard let range = pageSource.range(of: keyword, options: .caseInsensitive) else { continue }
            let after = pageSource[range.upperBound...]
            let windowed = String(after.prefix(window))
            if let date = firstDate(in: windowed, candidates: candidates) {
                return date
            }
        }
        return nil
    }

    /// 尝试用 `ISO8601DateFormatter` / `DateFormatter` 多种 format 解析日期字符串。
    private func parseLooseDate(_ raw: String) -> Date? {
        // ISO 8601 with full datetime
        let isoFractional = ISO8601DateFormatter()
        isoFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = isoFractional.date(from: raw) { return d }
        let iso = ISO8601DateFormatter()
        if let d = iso.date(from: raw) { return d }
        // ISO 8601 date-only: "2026-12-15"（很多订阅管理页只渲染日期不带时间）。
        // 用 UTC 时区解析，避免本地时区导致日期偏移一天。
        let isoDateOnly = DateFormatter()
        isoDateOnly.locale = Locale(identifier: "en_US_POSIX")
        isoDateOnly.dateFormat = "yyyy-MM-dd"
        isoDateOnly.timeZone = TimeZone(identifier: "UTC")
        if let d = isoDateOnly.date(from: raw) { return d }
        // 美式 "July 25, 2026" / "Jul 25, 2026" / "25 Jul 2026"
        let englishFormats = [
            "MMMM d, yyyy",
            "MMM d, yyyy",
            "d MMMM yyyy",
            "d MMM yyyy",
        ]
        for fmt in englishFormats {
            let f = DateFormatter()
            f.locale = Locale(identifier: "en_US_POSIX")
            f.dateFormat = fmt
            if let d = f.date(from: raw) { return d }
        }
        // 中文 "2026年7月25日"
        let chineseFormat = DateFormatter()
        chineseFormat.locale = Locale(identifier: "zh_CN")
        chineseFormat.dateFormat = "yyyy年M月d日"
        if let d = chineseFormat.date(from: raw) { return d }
        return nil
    }
}
