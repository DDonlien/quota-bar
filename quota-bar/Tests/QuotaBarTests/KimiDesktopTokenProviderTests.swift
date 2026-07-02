import Foundation
import Testing
@testable import QuotaBar

@Suite("KimiDesktopTokenProvider", .serialized)
struct KimiDesktopTokenProviderTests {
    @Test("desktop token calls membership API and parses Work plus Code quotas")
    func parsesDesktopMembershipStat() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let tokenPath = dir.appendingPathComponent("token-store.json").path
        try Data("""
        {
          "tokens": {
            "access_token": "desktop-access-token"
          }
        }
        """.utf8).write(to: URL(fileURLWithPath: tokenPath))

        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let session = Self.makeSession(statusCode: 200, data: Self.fixtureData())
        let provider = KimiDesktopTokenProvider(
            tokenStorePath: tokenPath,
            endpoint: URL(string: "https://kimi.test/GetSubscriptionStat")!,
            session: session,
            dateProvider: { now }
        )

        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.availability == .available)
        #expect(snapshot.quotas.contains { $0.title == "Work" && $0.scope == "work" })
        #expect(snapshot.quotas.contains { $0.title == "Code" && $0.periodSeconds == 5 * 60 * 60 })
        #expect(snapshot.quotas.contains { $0.title == "Code" && $0.periodSeconds == 7 * 24 * 60 * 60 })
        #expect(snapshot.subscriptionExpiresAt != nil)
    }

    private static func fixtureData() -> Data {
        let json: [String: Any] = [
            "ratelimitCode5h": [
                "enabled": true,
                "resetTime": "2027-01-15T18:00:00Z",
                "ratio": 0.25,
            ],
            "ratelimitCode7d": [
                "enabled": true,
                "resetTime": "2027-01-20T12:00:00Z",
                "ratio": 0.50,
            ],
            "subscriptionBalance": [
                "amountUsedRatio": 0.20,
                "kimiCodeUsedRatio": 0.10,
                "expireTime": "2027-02-01T00:00:00.000Z",
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private static func makeSession(statusCode: Int, data: Data) -> URLSession {
        KimiDesktopMockURLProtocol.responseHandler = { request in
            #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer desktop-access-token")
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [KimiDesktopMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func makeTempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-kimi-desktop-tests-\(UUID().uuidString)", isDirectory: true)
    }
}

private final class KimiDesktopMockURLProtocol: URLProtocol, @unchecked Sendable {
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
