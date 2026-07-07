import Foundation
import Testing
@testable import QuotaBar

/// 2026-07 Kimi 服务端下线 GetSubscriptionStat 后，Work 额度迁移到
/// `GetSubscription.balances[]`。覆盖新 schema 的解析与 provider 行为。
@Suite("KimiSubscriptionParser balances", .serialized)
struct KimiSubscriptionParserBalancesTests {

    @Test("parses Work window from GetSubscription balances")
    func parsesWorkFromBalances() throws {
        let parser = KimiSubscriptionParser()
        let windows = try #require(parser.parse(data: Self.subscriptionWithBalances()))
        #expect(windows.count == 1)
        let work = try #require(windows.first)
        #expect(work.title == "Work")
        #expect(work.scope == "work")
        #expect(work.remainingFraction == 0)
        #expect(work.resetsAt == nil)
        #expect(work.subscriptionGroup == ProviderKind.kimi.rawValue)
    }

    @Test("ignores non-subscription balances and missing ratio")
    func ignoresIrrelevantBalances() {
        let parser = KimiSubscriptionParser()
        let json: [String: Any] = [
            "balances": [
                ["feature": "FEATURE_VIDEO", "type": "GIFT"],
                ["feature": "FEATURE_OMNI", "type": "SUBSCRIPTION"],
            ],
        ]
        let data = try! JSONSerialization.data(withJSONObject: json)
        #expect(parser.parse(data: data) == nil)
    }

    @Test("desktop token provider survives GetSubscriptionStat 404")
    func desktopProviderUsesGetSubscriptionWhenStatGone() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-kimi-balances-tests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let tokenPath = dir.appendingPathComponent("token-store.json").path
        try Data("""
        {"tokens": {"access_token": "desktop-access-token"}}
        """.utf8).write(to: URL(fileURLWithPath: tokenPath))

        KimiBalancesMockURLProtocol.responseHandler = { request in
            let url = request.url!.absoluteString
            if url.contains("GetSubscriptionStat") {
                return (
                    HTTPURLResponse(url: request.url!, statusCode: 404, httpVersion: nil, headerFields: nil)!,
                    Data("404 page not found".utf8)
                )
            }
            return (
                HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"])!,
                Self.subscriptionWithBalances()
            )
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [KimiBalancesMockURLProtocol.self]
        let session = URLSession(configuration: config)

        let provider = KimiDesktopTokenProvider(
            tokenStorePath: tokenPath,
            endpoint: URL(string: "https://kimi.test/GetSubscriptionStat")!,
            subscriptionEndpoint: URL(string: "https://kimi.test/GetSubscription")!,
            session: session,
            dateProvider: { Date(timeIntervalSince1970: 1_800_000_000) }
        )

        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.availability == .available)
        #expect(snapshot.subscriptionTier == "Andante")
        #expect(snapshot.monthlyPrice == "¥49/月")
        #expect(snapshot.quotas.contains { $0.scope == "work" })
        // 到期日 = nextBillingTime 的本地自然日减 1 天
        let expiresAt = try #require(snapshot.subscriptionExpiresAt)
        let renewal = ISO8601DateFormatter().date(from: "2026-07-09T14:33:09Z")!
        let expectedLastValid = Calendar.current.date(
            byAdding: .day,
            value: -1,
            to: Calendar.current.startOfDay(for: renewal)
        )!
        #expect(expiresAt == expectedLastValid)
        #expect(snapshot.subscriptionExpiresAtSource == .api)
        #expect(snapshot.subscriptionExpiresAtConfidence == .high)
    }

    private static func subscriptionWithBalances() -> Data {
        let json: [String: Any] = [
            "subscription": [
                "nextBillingTime": "2026-07-09T14:33:09.134631Z",
                "currentEndTime": "2026-07-10T00:00:00Z",
                "status": "SUBSCRIPTION_STATUS_ACTIVE",
                "goods": [
                    "title": "Andante",
                    "amounts": [["priceInCents": "4900"]],
                ],
            ],
            "balances": [
                [
                    "feature": "FEATURE_OMNI",
                    "type": "SUBSCRIPTION",
                    "unit": "UNIT_CREDIT",
                    "amountUsedRatio": 1,
                    "expireTime": "2026-07-10T00:00:00Z",
                ],
            ],
            "subscribed": true,
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
}

private final class KimiBalancesMockURLProtocol: URLProtocol, @unchecked Sendable {
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
