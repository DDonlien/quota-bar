import Foundation
import Testing
@testable import QuotaBar

@Suite("ProviderPipelines.quotaChannels")
struct ProviderChannelDescriptorTests {
    @Test("Kimi exposes desktop-token/auth/webview as quota channels, keychain excluded")
    @MainActor
    func kimiQuotaChannels() {
        let channels = ProviderPipelines.quotaChannels(for: .kimi)
        let ids = Set(channels.map(\.id))
        #expect(ids == ["kimi-desktop-token", "kimi-auth", "kimi-webview"])

        // `QuotaProviderStrategy.sourceKind`（Strategies.swift）按 id 子串匹配、
        // "webview" 判断优先于 "cookie"——desktop-token 没命中任何特判条件，
        // 落到最后的 `.api` 默认分支；这里断言的是它实际的分类结果，不是分类
        // 规则本身，`.configFile`/`.api` 在 `checkLogLabel` 里本来就是同一句文案
        // （"配置/凭证 → API"），对本功能的"channel 是否需要展示"判断没有影响。
        let byId = Dictionary(uniqueKeysWithValues: channels.map { ($0.id, $0) })
        #expect(byId["kimi-desktop-token"]?.sourceKind == .api)
        #expect(byId["kimi-auth"]?.sourceKind == .configFile)
        #expect(byId["kimi-webview"]?.sourceKind == .webViewSession)
    }

    @Test("unknown/unpipelined provider kind returns no channels")
    @MainActor
    func unpipelinedKindReturnsEmpty() {
        // `.trae` 的 pipeline 只有一个 keychain strategy（`supportedLayers == [.provider]`），
        // 对「额度渠道」这个概念来说等价于没有——过滤后应该是空的，不是漏了什么。
        #expect(ProviderPipelines.quotaChannels(for: .trae).isEmpty)
    }
}
