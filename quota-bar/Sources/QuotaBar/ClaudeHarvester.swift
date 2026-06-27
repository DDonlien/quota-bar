import Foundation

/// Claude (claude.ai / anthropic.com) 订阅管理页 harvester。
///
/// 目标页：`https://claude.ai/settings/plan`
///
/// 已知 DOM 文本模式（按优先级）：
/// 1. `Next billing on July 25, 2026`
/// 2. `Renews on Jul 25, 2026`
/// 3. `Subscription renewal: 2026-07-25`
///
/// 备选路径：`https://claude.ai/account/billing`（如果 settings/plan 没有续费日）。
/// 当前实现只抓 settings/plan，因为 Anthropic 把续费日主要放在 settings/plan。
struct ClaudeHarvester: SubscriptionDateHarvester {
    let identifier = "claude-harvester"
    let pageURL = URL(string: "https://claude.ai/settings/plan")!

    private let keywords = [
        "Next billing",
        "Renews on",
        "Subscription renews",
        "Subscription renewal",
        "Next charge",
    ]

    private let dateCandidates = [
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