import Foundation
import Testing
@testable import QuotaBar

@Suite("KimiAuthProvider", .serialized)
struct KimiAuthProviderTests {
    @Test("refreshing an expired access token does not modify the credentials file on disk")
    func refreshDoesNotPersistBackToCredentialsFile() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let credentialsPath = dir.appendingPathComponent("kimi-code.json").path

        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let originalContents = """
        {"access_token":"old-access","refresh_token":"old-refresh","expires_at":\(now.timeIntervalSince1970 - 3600)}
        """
        try Data(originalContents.utf8).write(to: URL(fileURLWithPath: credentialsPath))

        let session = Self.makeSession(
            tokenResponse: ["access_token": "new-access", "refresh_token": "new-refresh", "expires_in": 3600],
            usageData: Self.fixtureUsageData()
        )
        let provider = KimiAuthProvider(
            credentialsPath: credentialsPath,
            session: session,
            dateProvider: { now }
        )

        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.availability == .available)
        #expect(!snapshot.quotas.isEmpty)

        let contentsAfter = try String(contentsOfFile: credentialsPath, encoding: .utf8)
        #expect(contentsAfter == originalContents)
    }

    @Test("valid access token skips refresh entirely and never touches the credentials file")
    func freshTokenSkipsRefresh() async throws {
        let dir = Self.makeTempDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let credentialsPath = dir.appendingPathComponent("kimi-code.json").path

        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let originalContents = """
        {"access_token":"still-valid","refresh_token":"unused-refresh","expires_at":\(now.timeIntervalSince1970 + 3600)}
        """
        try Data(originalContents.utf8).write(to: URL(fileURLWithPath: credentialsPath))

        let session = Self.makeSession(
            tokenResponse: nil,
            usageData: Self.fixtureUsageData()
        )
        let provider = KimiAuthProvider(
            credentialsPath: credentialsPath,
            session: session,
            dateProvider: { now }
        )

        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.availability == .available)

        let contentsAfter = try String(contentsOfFile: credentialsPath, encoding: .utf8)
        #expect(contentsAfter == originalContents)
    }

    private static func fixtureUsageData() -> Data {
        let json: [String: Any] = [
            "user": ["membership": ["level": "LEVEL_PAID"]],
            "usage": [
                "limit": "100", "used": "20", "remaining": "80",
                "resetTime": "2027-01-20T12:00:00Z",
            ],
            "limits": [
                [
                    "window": ["duration": 300, "timeUnit": "TIME_UNIT_MINUTE"],
                    "detail": ["limit": "10", "used": "2", "resetTime": "2027-01-15T18:00:00Z"],
                ],
            ],
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }

    private static func makeSession(tokenResponse: [String: Any]?, usageData: Data) -> URLSession {
        KimiAuthMockURLProtocol.responseHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            if request.url?.absoluteString.contains("oauth/token") == true {
                guard let tokenResponse else {
                    Issue.record("token endpoint should not be called when access token is still fresh")
                    return (response, Data())
                }
                return (response, try! JSONSerialization.data(withJSONObject: tokenResponse))
            }
            return (response, usageData)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [KimiAuthMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private static func makeTempDirectory() -> URL {
        URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-kimi-auth-tests-\(UUID().uuidString)", isDirectory: true)
    }
}

private final class KimiAuthMockURLProtocol: URLProtocol, @unchecked Sendable {
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
