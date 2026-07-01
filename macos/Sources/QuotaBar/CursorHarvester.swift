import Foundation

/// Cursor (cursor.com / cursor.sh) 订阅管理页 harvester。
///
/// 目标页：`https://cursor.com/dashboard`
///
/// 已知 DOM 文本模式（按优先级）：
/// 1. `Pro plan renews on July 25, 2026`（Cursor dashboard 顶部 Plan 卡片）
/// 2. `Renews on Jul 25, 2026`
/// 3. `Next billing date: 2026-07-25`
/// 4. `Subscription ends on 2026-07-25`
///
/// 注意：Cursor 页面是 React + Tailwind，文本可能被空格或换行切断（如
/// `<span>Pro plan renews on</span> <span>July 25, 2026</span>`）——大小写不敏感的
/// 关键词匹配 + 100 字符窗口能容忍这种情况。
struct CursorHarvester: SubscriptionDateHarvester {
    let identifier = "cursor-harvester"
    let pageURL = URL(string: "https://cursor.com/dashboard")!

    private let keywords = [
        "plan renews on",
        "Pro plan renews",
        "Business plan renews",
        "Enterprise plan renews",
        "Renews on",
        "Next billing",
        "Subscription ends on",
        "Subscription ends",
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