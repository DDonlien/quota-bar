import Foundation

/// opencode WebView 会话额度层：headless 加载 opencode.ai console 的 workspace Go 页，
/// 从渲染后的 DOM 解析三条用量（Rolling / Weekly / Monthly）。
///
/// 为什么是 headlessDOM 而不是 JSON API：console 是 SolidStart 应用，数据全部走
/// `"use server"` 的框架内部 RPC（`query(..., "lite.subscription.get")`），没有公开的
/// JSON endpoint，逆向那套序列化协议远比解析 SSR 出来的 DOM 脆弱。DOM 侧有稳定的
/// `data-slot` 锚点（`usage-item`/`usage-value`/`reset-time`，见
/// `packages/console/app/src/routes/workspace/[id]/go/lite-section.tsx`），文字标签是
/// i18n 的（随站点语言变化），所以解析**只认结构和顺序**（rolling → weekly →
/// monthly），不认标签文字。
///
/// 页面路径 `https://opencode.ai/workspace/{wrk_...}/go` 带用户专属 workspace id，
/// 发现方式：先加载 `https://opencode.ai/auth`——已登录时该路由 302 到
/// `/workspace/{lastSeenWorkspaceID}`（`routes/auth/index.ts`），从渲染结果里正则出
/// 第一个 `wrk_` id，再加载 Go 页。
///
/// 订阅续费日：console 里点 "Manage Subscription" 走 Stripe 客户门户（服务端动态生成
/// 的短期 session URL，无法预先构造）；但 Go 的**月用量窗口锚定在订阅日**
/// （`analyzeMonthlyUsage(timeSubscribed:)`），月窗口的重置时刻就是下一个月度账单日
/// ——这里把解析出的 monthly reset 时间作为续费日代理（confidence `.medium`）。
final class OpenCodeWorkspaceProvider: QuotaProvider, @unchecked Sendable {
    let id = "opencode-webview"
    let kind: ProviderKind = .opencode
    var displayName: String { kind.displayName }

    private let dateProvider: () -> Date

    init(dateProvider: @escaping () -> Date = Date.init) {
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let domains = ["opencode.ai"]
        guard await WKWebViewHeadlessLoader.appSessionHasCookies(for: domains) else {
            throw QuotaFetchError.missingCredentials(detail: "未登录")
        }

        let loader = await WKWebViewHeadlessLoader()
        // 两次页面加载分摊总超时：入口页（/auth 302 → workspace 首页）通常很快，
        // Go 页是 SPA 渲染大头，给它留更多余量。
        let entryTimeout = max(5, min(10, timeout * 0.4))
        let goTimeout = max(5, timeout - entryTimeout)

        let entryHTML = try await loader.loadUsingAppSession(
            url: URL(string: "https://opencode.ai/auth")!,
            cookieDomains: domains,
            timeout: entryTimeout,
            identifier: "opencode-webview-entry"
        )
        guard let workspaceID = Self.extractWorkspaceID(from: entryHTML) else {
            // Cookie 在但页面里找不到任何 wrk_ id：大概率被 302 去了登录页
            //（会话已失效），也可能是账号还没有任何 workspace。
            throw QuotaFetchError.missingCredentials(
                detail: "WebView 会话已失效或账号无 workspace，请重新登录 opencode.ai"
            )
        }

        let goHTML = try await loader.loadUsingAppSession(
            url: URL(string: "https://opencode.ai/workspace/\(workspaceID)/go")!,
            cookieDomains: domains,
            timeout: goTimeout,
            identifier: "opencode-webview-go"
        )

        let items = Self.parseUsageItems(from: goHTML)
        guard !items.isEmpty else {
            if goHTML.contains("data-slot=\"promo-description\"") {
                // Go 页渲染的是订阅推广文案 → 这个 workspace 没有 Go 订阅。
                throw QuotaFetchError.notSubscribed(detail: "workspace 未订阅 opencode Go")
            }
            throw QuotaFetchError.transient(detail: "Go 页面已加载但未解析出额度条")
        }

        let now = dateProvider()
        // 页面固定按 rolling → weekly → monthly 顺序渲染（lite-section.tsx）；
        // rolling 窗口时长来自服务端配置（ZEN_LIMITS，代码里读不到具体值），按目前
        // 产品实际的 5 小时窗口标注——如果 opencode 未来调整窗口，这里的周期标签
        // 会跟着不准，需要同步改。
        let periodByIndex: [TimeInterval] = [5 * 3600, 7 * 86400, 30 * 86400]
        var windows: [QuotaWindow] = []
        var monthlyResetsAt: Date?
        for (index, item) in items.enumerated() {
            let resetsAt = Self.parseResetSeconds(item.resetText).map { now.addingTimeInterval($0) }
            if index == 2 { monthlyResetsAt = resetsAt }
            // `refreshDescription` 统一走 `QuotaResetText`（跟 MiniMax/Z Code 等其余
            // provider 一致的 "XdXXh"/"XhXXm" 格式），不能直接用页面原文
            // （"重置于 5 小时 0 分钟"）——2026-07-09 用户反馈 dropdown 里 opencode
            // 这一栏跟其他 provider 格式不统一。
            let refreshDescription = resetsAt.map { QuotaResetText.description(for: $0, relativeTo: now) } ?? item.resetText
            windows.append(QuotaWindow(
                title: "",
                remainingFraction: 1.0 - Double(item.percentUsed) / 100.0,
                refreshDescription: refreshDescription,
                resetsAt: resetsAt,
                periodSeconds: index < periodByIndex.count ? periodByIndex[index] : nil,
                scope: "go"
            ))
        }

        let monthlyPrice = await ProviderPricing.localizedMonthlyPrice(kind: .opencode, tier: "Go")
        return ProviderSnapshot(
            kind: .opencode,
            subscriptionTier: "Go",
            availability: .available,
            quotas: windows,
            monthlyPrice: monthlyPrice,
            subscriptionExpiresAt: monthlyResetsAt,
            subscriptionExpiresAtSource: monthlyResetsAt != nil ? .headlessDOM : nil,
            subscriptionExpiresAtConfidence: monthlyResetsAt != nil ? .medium : nil,
            fetchedAt: now
        )
    }

    // MARK: - 纯解析（可单测，不碰网络）

    /// 从任意 console 页面 HTML 里提取第一个 workspace id（`wrk_` 前缀）。
    static func extractWorkspaceID(from html: String) -> String? {
        guard let range = html.range(of: #"wrk_[A-Za-z0-9]+"#, options: .regularExpression) else {
            return nil
        }
        return String(html[range])
    }

    struct UsageItem: Equatable {
        let percentUsed: Int
        let resetText: String
    }

    /// 解析 Go 页的用量条。按 `data-slot="usage-item"` 分块，每块取
    /// `data-slot="usage-value"` 的百分比（**已用**比例）和 `data-slot="reset-time"`
    /// 的文字（i18n 文案，仅原样保留 + 尽力解析成秒，不参与结构判断）。
    ///
    /// 2026-07-09 修订：真实抓到的渲染结果显示 SolidStart 的 SSR hydration 会在每段
    /// 动态文本前后插入 `<!--$-->`/`<!--/-->` 注释标记（例如
    /// `<span data-slot="usage-value"><!--$-->0<!--/-->%</span>`、
    /// `<span data-slot="reset-time"><!--$-->重置于<!--/--> <!--$-->5 小时 0 分钟<!--/--></span>`）
    /// ——最初照着仓库里的原始 JSX 源码写的正则完全没考虑这层注释，数字和 `%`/文字之间
    /// 被注释隔开，`\d+\s*%` 和 `[^<]*` 两种写法都直接匹配失败，导致这个 provider
    /// 上线后第一次真实运行就 0 结果。改成先用非贪婪匹配拿到 `<span>...</span>` 之间
    /// 的完整内容，再统一剥掉里面所有 HTML 注释，只留纯文本解析。
    static func parseUsageItems(from html: String) -> [UsageItem] {
        guard
            let valueRegex = try? NSRegularExpression(pattern: #"data-slot="usage-value"[^>]*>(.*?)</span>"#),
            let resetRegex = try? NSRegularExpression(pattern: #"data-slot="reset-time"[^>]*>(.*?)</span>"#)
        else { return [] }

        let chunks = html.components(separatedBy: "data-slot=\"usage-item\"").dropFirst()
        var items: [UsageItem] = []
        for chunk in chunks {
            let nsChunk = chunk as NSString
            let fullRange = NSRange(location: 0, length: nsChunk.length)
            guard let valueMatch = valueRegex.firstMatch(in: chunk, range: fullRange) else { continue }
            let percentText = Self.stripHydrationComments(nsChunk.substring(with: valueMatch.range(at: 1)))
            guard let digitsRange = percentText.range(of: #"\d+"#, options: .regularExpression),
                  let percent = Int(percentText[digitsRange])
            else { continue }

            var resetText = ""
            if let resetMatch = resetRegex.firstMatch(in: chunk, range: fullRange) {
                resetText = Self.stripHydrationComments(nsChunk.substring(with: resetMatch.range(at: 1)))
            }
            items.append(UsageItem(percentUsed: min(100, max(0, percent)), resetText: resetText))
        }
        return items
    }

    /// 去掉 SolidJS SSR hydration 插入的 `<!--$-->`/`<!--/-->` 注释标记，只留纯文本。
    static func stripHydrationComments(_ fragment: String) -> String {
        fragment
            .replacingOccurrences(of: #"<!--.*?-->"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// 把 "Resets in 3 hours 25 minutes" / "重置于 2 天 5 小时" 这类 i18n 文案尽力
    /// 解析成秒数。格式来自 console 的 `formatResetTime`（数字 + 单位词的组合，最多
    /// 两段），单位词按前缀匹配覆盖英文和中文；"a few seconds" / "几秒" 这类无数字
    /// 文案按 30 秒计。解析不出来返回 nil——resetsAt 是锦上添花，不阻塞额度展示。
    static func parseResetSeconds(_ text: String) -> TimeInterval? {
        let lower = text.lowercased()
        var total: TimeInterval = 0
        var matched = false

        let pattern = #"(\d+)\s*([a-z一-鿿]+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let nsText = lower as NSString
        for match in regex.matches(in: lower, range: NSRange(location: 0, length: nsText.length)) {
            guard let value = Double(nsText.substring(with: match.range(at: 1))) else { continue }
            let unit = nsText.substring(with: match.range(at: 2))
            let seconds: TimeInterval?
            if unit.hasPrefix("day") || unit.hasPrefix("天") || unit.hasPrefix("日") {
                seconds = 86400
            } else if unit.hasPrefix("hour") || unit.hasPrefix("小时") || unit.hasPrefix("时") {
                seconds = 3600
            } else if unit.hasPrefix("min") || unit.hasPrefix("分") {
                seconds = 60
            } else if unit.hasPrefix("sec") || unit.hasPrefix("秒") {
                seconds = 1
            } else {
                seconds = nil
            }
            if let seconds {
                total += value * seconds
                matched = true
            }
        }
        if matched { return total }
        if lower.contains("second") || lower.contains("秒") { return 30 }
        return nil
    }
}
