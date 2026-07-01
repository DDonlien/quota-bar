import Foundation

/// MiniMax (minimaxi.com) 订阅管理页 harvester。
///
/// 目标页：`https://platform.minimaxi.com/console/plan`
///
/// 已知 DOM 文本模式（按优先级）：
/// 1. `到期日：2026年7月25日`（中文管理页主标签）
/// 2. `续费日期：2026-07-25`
/// 3. `下次扣费：Jul 25, 2026`
/// 4. `Next billing on July 25, 2026`（英文 i18n 切换时）
///
/// 注意：用户确认的订阅入口在 `platform.minimaxi.com`；额度 API 仍可能来自
/// `minimax.chat` / `minimax.com`。
struct MiniMaxHarvester: SubscriptionDateHarvester {
    let identifier = "minimax-harvester"
    let pageURL = URL(string: "https://platform.minimaxi.com/console/plan")!

    private let keywords = [
        "到期日",
        "续费日期",
        "下次扣费",
        "到期时间",
        "续费时间",
        "Next billing",
        "Renews on",
        "Subscription renews",
        "Next charge",
    ]

    private let dateCandidates = [
        // 中文优先（MiniMax 主体面向中文用户）
        "\\d{4}年\\d{1,2}月\\d{1,2}日",
        // ISO 8601
        "\\d{4}-\\d{2}-\\d{2}(?:T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z?)?",
        // 美式全称
        "\\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d{1,2},\\s+\\d{4}\\b",
        // 美式简写
        "\\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2},\\s+\\d{4}\\b",
    ]

    func extract(from pageSource: String) -> Date? {
        extractNear(keywords: keywords, candidates: dateCandidates, in: pageSource)
    }
}
