import Foundation

/// Kimi 订阅额度页 harvester。
///
/// Kimi 首选 Cookie API：`GetSubscriptionStat.subscriptionBalance.expireTime` 作为
/// 原始续费日，按「下一次续费日」语义换算为最后有效日。
/// 本 harvester 只是后备浏览器订阅页，目标页由用户确认：
/// `https://www.kimi.com/membership/subscription?tab=quota`。
///
/// 注意：该页面展示的是「下一次续费日」，source registry 会把它换算为最后有效日。
struct KimiHarvester: SubscriptionDateHarvester {
    let identifier = "kimi-harvester"
    let pageURL = URL(string: "https://www.kimi.com/membership/subscription?tab=quota")!

    private let keywords = [
        "到期日",
        "有效期至",
        "会员到期",
        "订阅到期",
        "续费日期",
        "下次扣费",
        "Next billing",
        "Renews on",
        "Subscription renews",
        "Next charge",
    ]

    private let dateCandidates = [
        "\\d{4}年\\d{1,2}月\\d{1,2}日",
        "\\d{4}-\\d{2}-\\d{2}(?:T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z?)?",
        "\\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d{1,2},\\s+\\d{4}\\b",
        "\\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2},\\s+\\d{4}\\b",
    ]

    func extract(from pageSource: String) -> Date? {
        extractNear(keywords: keywords, candidates: dateCandidates, in: pageSource)
    }
}
