import Foundation
import Testing
@testable import QuotaBar

@Suite("SubscriptionExpirySources — 独立过期日 source pipeline", .serialized)
@MainActor
struct SubscriptionExpirySourcesTests {

    private static func session(statusCode: Int = 200, data: Data) -> URLSession {
        SubscriptionExpiryMockURLProtocol.responseHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [SubscriptionExpiryMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func chatGPTCookie() -> HTTPCookie {
        HTTPCookie(properties: [
            .domain: ".chatgpt.com",
            .path: "/",
            .name: "session",
            .value: "test-only",
            .secure: "TRUE",
        ])!
    }

    private static func codexAPISourceOnly(_ kind: ProviderKind) -> [SubscriptionExpirySource] {
        Array(SubscriptionExpirySources.sources(for: kind).prefix(1))
    }

    @Test("Kimi source：membership 页 headless 兜底")
    func kimiSourceOrder() {
        let sources = SubscriptionExpirySources.sources(for: .kimi)
        #expect(sources.count == 1)
        #expect(sources[0].kind == .headlessDOM)
        #expect(sources[0].dateMeaning == .nextRenewalDate)
        #expect(sources[0].harvester is KimiHarvester)
        #expect(sources[0].pageURL?.absoluteString == "https://www.kimi.com/membership/subscription?tab=quota")
    }

    @Test("Kimi membership 页日期是下一次续费日，UI 展示最后有效日")
    func kimiRenewalDateConvertedToLastValidDate() {
        let source = SubscriptionExpirySources.sources(for: .kimi)[0]
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Shanghai")!
        let renewalDate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 10, hour: 12))!

        let lastValidDate = source.lastValidDate(from: renewalDate, calendar: calendar)
        let comps = calendar.dateComponents([.year, .month, .day, .hour], from: lastValidDate)

        #expect(comps.year == 2026)
        #expect(comps.month == 7)
        #expect(comps.day == 9)
        #expect(comps.hour == 0)
    }

    @Test("用户确认的 headless billing URL 已注册")
    func confirmedBillingURLs() {
        #expect(SubscriptionExpirySources.sources(for: .claude).first?.pageURL?.absoluteString == "https://claude.ai/new#settings/billing")
        // Codex 的首选改为 accounts/check browserAPI（JSON，稳定），headless 账单页降为兜底。
        let codexSources = SubscriptionExpirySources.sources(for: .codex)
        #expect(codexSources.first?.id == "codex-accounts-check")
        #expect(codexSources.first?.kind == .browserAPI)
        #expect(codexSources.first?.apiRequest != nil)
        #expect(codexSources.contains { $0.pageURL?.absoluteString == "https://chatgpt.com/#settings/Billing" })
        #expect(SubscriptionExpirySources.sources(for: .minimax).first?.pageURL?.absoluteString == "https://platform.minimaxi.com/console/plan")
    }

    @Test("已有带 source metadata 的 API 日期时 resolver 直接返回，不需要 headless cookies")
    func existingSourceMetadataTakesPrecedence() async {
        let expiresAt = Date(timeIntervalSince1970: 1_800_000_000)
        let snapshot = ProviderSnapshot(
            kind: .kimi,
            availability: .available,
            quotas: [
                QuotaWindow(title: "免费额度", remainingFraction: 0.8, refreshDescription: "无订阅")
            ],
            monthlyPrice: nil,
            subscriptionExpiresAt: expiresAt,
            subscriptionExpiresAtSource: .api,
            subscriptionExpiresAtConfidence: .high,
            fetchedAt: Date()
        )
        let resolver = SubscriptionExpiryResolver(timeout: 0.1)
        let result = await resolver.resolve(for: snapshot)
        #expect(result?.expiresAt == expiresAt)
        #expect(result?.source.kind == .api)
        #expect(result?.source.confidence == .high)
    }

    @Test("Codex 已过去的 snapshot 日期不短路，accounts/check 返回当前续费边界")
    func staleCodexSnapshotFallsThroughToAccountsCheck() async {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let staleDate = now.addingTimeInterval(-30 * 86400)
        let renewsAt = now.addingTimeInterval(14 * 86400)
        let renewalISO = ISO8601DateFormatter().string(from: renewsAt)
        let data = try! JSONSerialization.data(withJSONObject: [
            "accounts": [
                "default": [
                    "entitlement": [
                        "has_active_subscription": true,
                        "subscription_plan": "chatgptproplan",
                        "expires_at": renewalISO,
                    ],
                ],
            ],
        ])
        let snapshot = ProviderSnapshot(
            kind: .codex,
            subscriptionTier: "Pro",
            availability: .available,
            quotas: [QuotaWindow(title: "周额度", remainingFraction: 0.94, refreshDescription: "6d")],
            monthlyPrice: "¥1347/月",
            subscriptionExpiresAt: staleDate,
            subscriptionExpiresAtSource: .appCache,
            subscriptionExpiresAtConfidence: .medium,
            fetchedAt: now
        )
        let resolver = SubscriptionExpiryResolver(
            timeout: 1,
            session: Self.session(data: data),
            cookiesProvider: { _ in [Self.chatGPTCookie()] },
            sourcesProvider: Self.codexAPISourceOnly
        )

        let result = await resolver.resolve(for: snapshot)
        #expect(result?.expiresAt.timeIntervalSince1970 == renewsAt.timeIntervalSince1970)
        #expect(result?.source.id == "codex-accounts-check")
        #expect(result?.source.confidence == .high)
    }

    @Test("Codex 当前周期查询无日期时返回 nil，不制造或复用历史日期")
    func unresolvedCodexRenewalDateStaysHidden() async {
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let data = try! JSONSerialization.data(withJSONObject: [
            "accounts": [
                "default": [
                    "entitlement": ["has_active_subscription": true],
                ],
            ],
        ])
        let snapshot = ProviderSnapshot(
            kind: .codex,
            subscriptionTier: "Pro",
            availability: .available,
            quotas: [QuotaWindow(title: "周额度", remainingFraction: 0.94, refreshDescription: "6d")],
            monthlyPrice: "¥1347/月",
            fetchedAt: now
        )
        let resolver = SubscriptionExpiryResolver(
            timeout: 1,
            session: Self.session(data: data),
            cookiesProvider: { _ in [Self.chatGPTCookie()] },
            sourcesProvider: Self.codexAPISourceOnly
        )

        let result = await resolver.resolve(for: snapshot)
        #expect(result == nil)
        #expect(snapshot.subscriptionExpiresAt == nil)
    }

    @Test("免费额度 snapshot 无过期日时仍保持 available，resolver 只返回 nil")
    func freeQuotaWithoutSubscriptionExpiryStaysAvailable() async {
        let snapshot = ProviderSnapshot(
            kind: .codex,
            availability: .available,
            quotas: [
                QuotaWindow(title: "免费额度", remainingFraction: 0.4, refreshDescription: "无订阅")
            ],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
        let resolver = SubscriptionExpiryResolver(
            timeout: 0.1,
            cookiesProvider: { _ in [] },
            sourcesProvider: Self.codexAPISourceOnly
        )
        let result = await resolver.resolve(for: snapshot)
        #expect(result == nil)
        if case .available = snapshot.availability {
            // 期望：日期 resolver 失败不改变额度可用状态
        } else {
            Issue.record("免费额度 snapshot 应保持 available")
        }
        #expect(snapshot.subscriptionExpiresAt == nil)
        #expect(snapshot.quotas.count == 1)
    }
}

private final class SubscriptionExpiryMockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var responseHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.responseHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
