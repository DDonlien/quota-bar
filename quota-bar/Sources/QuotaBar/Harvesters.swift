import Foundation

// MARK: - Provider → Harvester 注册表

/// 把每个 ProviderKind 映射到对应的 `SubscriptionDateHarvester`。
///
/// v0.6.0 第二批：5 个 provider harvester（Codex / Claude / Cursor / MiniMax / Antigravity）
/// 加上已有的 Kimi `parseSubscriptionExpiresAt` API 路径，覆盖了所有需要真实订阅到期日
/// 的 provider。
///
/// 调用方约定：
/// 1. `harvester(for: kind)` 拿到对应 harvester（nil 表示该 provider 没有 headless 路径）；
/// 2. 用 `WKWebViewHeadlessLoader` 加载 `harvester.pageURL`（注入 cookie）；
/// 3. 拿到的 outerHTML 调 `harvester.extract(from:)` 得到 `Date?`。
enum Harvesters {

    /// 给定 `ProviderKind` 返回对应 harvester。
    ///
    /// 返回 nil 表示：
    /// - 该 provider 已有 API 路径（如 Kimi 用 `parseSubscriptionExpiresAt`），不走 headless；
    /// - 或者该 provider 暂未接入订阅到期日抓取（如 Trae Work 等 deferred 项）。
    static func harvester(for kind: ProviderKind) -> SubscriptionDateHarvester? {
        switch kind {
        case .codex, .openai: return CodexHarvester()
        case .claude: return ClaudeHarvester()
        case .cursor: return CursorHarvester()
        case .minimax: return MiniMaxHarvester()
        case .antigravity: return AntigravityHarvester()
        // Kimi：API 路径返回 expireTime（KimiSubscriptionStatParser.parseSubscriptionExpiresAt），
        // 不走 headless。
        case .kimi: return nil
        // 其它 provider：暂未接入订阅到期日抓取。
        default: return nil
        }
    }

    /// 当前所有已注册 harvester 的 ProviderKind（测试和 UI 调试用）。
    static var supportedKinds: [ProviderKind] {
        ProviderKind.allCases.filter { harvester(for: $0) != nil }
    }
}