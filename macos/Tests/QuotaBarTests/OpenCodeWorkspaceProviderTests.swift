import Foundation
import Testing
@testable import QuotaBar

@Suite("OpenCodeWorkspaceProvider 解析")
struct OpenCodeWorkspaceProviderTests {

    /// 2026-07-09 从真实登录会话抓到的 Go 页片段（原样保留，只做了缩进整理）——
    /// 不是照 JSX 源码猜的，是加了 `debugDumpHTML` 后从用户真机上落盘的实际渲染
    /// 结果里摘出来的。关键点：SolidStart 的 SSR hydration 会在每段动态文本前后插
    /// `<!--$-->`/`<!--/-->` 注释标记（`usage-value`/`reset-time` 两处都有），第一版
    /// 解析器完全没考虑这层，上线后第一次真实运行就 0 结果（`parseUsageItems` 的
    /// 修复记录见该函数注释）。
    private static let goPageHTML = """
    <div data-slot="sections"><section class="_root_9awwr_1"><div data-slot="section-title"><div data-slot="title-row"><p>您已订阅 OpenCode Go。</p><button data-color="primary">管理订阅</button></div></div><div data-slot="usage"><div data-hk="1" data-slot="usage-item"><div data-slot="usage-header"><span data-slot="usage-label">滚动用量</span><span data-slot="usage-value"><!--$-->0<!--/-->%</span></div><div data-slot="progress"><div data-slot="progress-bar" style="width:0%"></div></div><span data-slot="reset-time"><!--$-->重置于<!--/--> <!--$-->5 小时 0 分钟<!--/--></span></div><div data-hk="2" data-slot="usage-item"><div data-slot="usage-header"><span data-slot="usage-label">每周用量</span><span data-slot="usage-value"><!--$-->57<!--/-->%</span></div><div data-slot="progress"><div data-slot="progress-bar" style="width:57%"></div></div><span data-slot="reset-time"><!--$-->重置于<!--/--> <!--$-->3 天 22 小时<!--/--></span></div><div data-hk="3" data-slot="usage-item"><div data-slot="usage-header"><span data-slot="usage-label">每月用量</span><span data-slot="usage-value"><!--$-->28<!--/-->%</span></div><div data-slot="progress"><div data-slot="progress-bar" style="width:28%"></div></div><span data-slot="reset-time"><!--$-->重置于<!--/--> <!--$-->29 天 15 小时<!--/--></span></div></div></section></div>
    """

    @Test("从 workspace 页面 HTML 提取第一个 wrk_ id")
    func extractsWorkspaceID() {
        let html = #"<a href="/workspace/wrk_01KWTQ01HPDHJCFGAMGYMG1T3D/go">Go</a> <a href="/workspace/wrk_ZZZZ/keys">Keys</a>"#
        #expect(OpenCodeWorkspaceProvider.extractWorkspaceID(from: html) == "wrk_01KWTQ01HPDHJCFGAMGYMG1T3D")
        #expect(OpenCodeWorkspaceProvider.extractWorkspaceID(from: "<html>登录页，没有 workspace 链接</html>") == nil)
    }

    @Test("按结构顺序解析三条用量（已用百分比 + reset 文案），SSR hydration 注释不干扰解析")
    func parsesUsageItemsInOrder() {
        let items = OpenCodeWorkspaceProvider.parseUsageItems(from: Self.goPageHTML)
        #expect(items.count == 3)
        #expect(items[0] == .init(percentUsed: 0, resetText: "重置于 5 小时 0 分钟"))
        #expect(items[1] == .init(percentUsed: 57, resetText: "重置于 3 天 22 小时"))
        #expect(items[2] == .init(percentUsed: 28, resetText: "重置于 29 天 15 小时"))
    }

    @Test("未订阅的推广页解析出零条用量")
    func promoPageYieldsNoItems() {
        let promo = #"<section><p data-slot="promo-description">Get access for <strong>$10</strong></p></section>"#
        #expect(OpenCodeWorkspaceProvider.parseUsageItems(from: promo).isEmpty)
    }

    @Test("SolidJS hydration 注释标记会被剥离，只留纯文本")
    func stripsHydrationComments() {
        #expect(OpenCodeWorkspaceProvider.stripHydrationComments("<!--$-->0<!--/-->%") == "0%")
        #expect(OpenCodeWorkspaceProvider.stripHydrationComments("<!--$-->重置于<!--/--> <!--$-->5 小时 0 分钟<!--/-->") == "重置于 5 小时 0 分钟")
        #expect(OpenCodeWorkspaceProvider.stripHydrationComments("没有注释的纯文本") == "没有注释的纯文本")
    }

    @Test("reset 文案解析成秒（英文/中文/无数字兜底/无法识别）")
    func parsesResetSeconds() {
        #expect(OpenCodeWorkspaceProvider.parseResetSeconds("Resets in 3 hours 25 minutes") == TimeInterval(3 * 3600 + 25 * 60))
        #expect(OpenCodeWorkspaceProvider.parseResetSeconds("Resets in 2 days 5 hours") == TimeInterval(2 * 86400 + 5 * 3600))
        #expect(OpenCodeWorkspaceProvider.parseResetSeconds("45 minutes") == TimeInterval(45 * 60))
        #expect(OpenCodeWorkspaceProvider.parseResetSeconds("重置于 2 天 5 小时") == TimeInterval(2 * 86400 + 5 * 3600))
        #expect(OpenCodeWorkspaceProvider.parseResetSeconds("a few seconds") == TimeInterval(30))
        #expect(OpenCodeWorkspaceProvider.parseResetSeconds("完全无关的文字") == nil)
    }
}
