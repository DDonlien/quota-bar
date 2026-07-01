import Foundation

/// Antigravity 订阅管理页 harvester。
///
/// Antigravity IDE 的"订阅"实际上是 Google AI 订阅（Plus/Pro/Ultra），订阅管理页
/// 跟随 Google 账号体系。当前已知路径：
/// - `https://antigravity.google/settings`（首选，Antigravity 域名内）
/// - `https://one.google.com/storage/management`（备选，Google One 管理页）
///
/// 当前实现优先抓 antigravity.google；该路径可能要求 Google 账号登录，
/// WKWebView 注入 google.com / antigravity.google 的 cookie 后能访问。
///
/// 已知 DOM 文本模式（Google One / Cloud 控制台常见格式）：
/// 1. `Next billing on Mon, Jul 25, 2026`（Google One 风格）
/// 2. `Renews on July 25, 2026`
/// 3. `Plan renews on 2026-07-25`
///
/// 注意：Google 页面常用 Material Design，文本片段可能被 `<span>` 分隔，
/// 100 字符窗口足以跨越这些 span 边界。
struct AntigravityHarvester: SubscriptionDateHarvester {
    let identifier = "antigravity-harvester"
    let pageURL = URL(string: "https://antigravity.google/settings")!

    private let keywords = [
        "Next billing",
        "Renews on",
        "Plan renews",
        "Subscription renews",
        "Next charge",
    ]

    private let dateCandidates = [
        // Google 风格：Mon, Jul 25, 2026 / Monday, July 25, 2026
        "\\b(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun),?\\s+(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2},\\s+\\d{4}\\b",
        "\\b(?:Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),?\\s+(?:January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d{1,2},\\s+\\d{4}\\b",
        // ISO 8601
        "\\d{4}-\\d{2}-\\d{2}(?:T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z?)?",
        // 美式全称
        "\\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d{1,2},\\s+\\d{4}\\b",
        // 美式简写
        "\\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2},\\s+\\d{4}\\b",
        // 中文
        "\\d{4}年\\d{1,2}月\\d{1,2}日",
    ]

    func extract(from pageSource: String) -> Date? {
        extractNear(keywords: keywords, candidates: dateCandidates, in: pageSource)
    }
}