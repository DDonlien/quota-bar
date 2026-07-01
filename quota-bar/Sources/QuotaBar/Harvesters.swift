import Foundation

// MARK: - Provider → Harvester 注册表

/// 把每个 ProviderKind 映射到对应的 `SubscriptionDateHarvester`。
///
/// 新代码使用 `SubscriptionExpirySources` 作为真正的 source registry。本类型保留为
/// 测试和调试用 facade，只返回每个 provider 已注册的 headless DOM harvester。
///
/// 调用方约定：
/// 1. `harvester(for: kind)` 拿到对应 harvester（nil 表示该 provider 没有 headless 路径）；
/// 2. 用 `WKWebViewHeadlessLoader` 加载 `harvester.pageURL`（注入 cookie）；
/// 3. 拿到的 outerHTML 调 `harvester.extract(from:)` 得到 `Date?`。
enum Harvesters {

    /// 给定 `ProviderKind` 返回对应 headless DOM harvester。
    static func harvester(for kind: ProviderKind) -> SubscriptionDateHarvester? {
        SubscriptionExpirySources.sources(for: kind)
            .first { $0.kind == .headlessDOM }?
            .harvester
    }

    /// 当前所有已注册 harvester 的 ProviderKind（测试和 UI 调试用）。
    static var supportedKinds: [ProviderKind] {
        SubscriptionExpirySources.headlessKinds
    }
}
