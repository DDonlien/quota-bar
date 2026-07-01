import Foundation

/// Codex (chatgpt.com / openai.com) 订阅管理页 harvester。
///
/// 目标页：`https://chatgpt.com/#settings/Billing`
///
/// 已知 DOM 文本模式（按优先级）：
/// 1. `Next billing on July 25, 2026`（ChatGPT Plus/Pro 订阅管理页主标题）
/// 2. `Renews on Jul 25, 2026`（次常见变体）
/// 3. `Billing date: 2026-07-25`（设置页内嵌）
///
/// 设计参考：React 应用，多语言字符串以 i18next 注入，HTML 可能含 emoji 或全角
/// 标点——所以 `extractNear` 用了大小写不敏感的关键词匹配 + 100 字符窗口。
///
/// 找不到时返回 nil（UI hide），不 throw，不 fallback 到无关日期。
struct CodexHarvester: SubscriptionDateHarvester {
    let identifier = "codex-harvester"
    let pageURL = URL(string: "https://chatgpt.com/#settings/Billing")!

    /// 续费相关关键词（按优先级）。
    private let keywords = [
        "Next billing",
        "Renews on",
        "Subscription renews",
        "Billing date",
        "Next charge",
    ]

    /// 日期 regex 列表（按优先级）。
    private let dateCandidates = [
        // ISO 8601: 2026-07-25 / 2026-07-25T10:30:00Z
        "\\d{4}-\\d{2}-\\d{2}(?:T\\d{2}:\\d{2}:\\d{2}(?:\\.\\d+)?Z?)?",
        // 美式全称: July 25, 2026
        "\\b(?:January|February|March|April|May|June|July|August|September|October|November|December)\\s+\\d{1,2},\\s+\\d{4}\\b",
        // 美式简写: Jul 25, 2026
        "\\b(?:Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\\s+\\d{1,2},\\s+\\d{4}\\b",
        // 中文: 2026年7月25日
        "\\d{4}年\\d{1,2}月\\d{1,2}日",
    ]

    func extract(from pageSource: String) -> Date? {
        extractNear(keywords: keywords, candidates: dateCandidates, in: pageSource)
    }
}
