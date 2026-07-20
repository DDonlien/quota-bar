import Foundation
import Testing
@testable import QuotaBar

/// v0.14.0：GitHub 直连失败时自动改用 Vercel 同源 endpoint 兜底——覆盖检查更新和
/// 下载两条路径。用同一个 mock session 区分 primary（GitHub 形状）URL 和 fallback
/// （Vercel）URL。
@MainActor
@Suite("UpdateChecker GitHub → Vercel fallback", .serialized)
struct UpdateCheckerFallbackTests {
    private static let primaryURL = URL(string: "https://api.test/primary/releases")!
    private static let fallbackURL = URL(string: "https://vercel.test/api/latest-release")!
    private static let fallbackDownloadURL = URL(string: "https://vercel.test/api/download-latest")!

    @Test("primary succeeds: fallback is never called")
    func primarySuccessSkipsFallback() async throws {
        var fallbackCalled = false
        UpdateFallbackMockURLProtocol.responseHandler = { request in
            if request.url == Self.primaryURL {
                let data = Self.releasesJSON([Self.release(tag: "v9.9.9", asset: "n.dmg")])
                return (Self.http(request, status: 200), data)
            }
            fallbackCalled = true
            return (Self.http(request, status: 200), Data("[]".utf8))
        }

        let checker = UpdateChecker(
            releasesURL: Self.primaryURL,
            fallbackReleasesURL: Self.fallbackURL,
            fallbackDownloadURL: Self.fallbackDownloadURL,
            session: Self.mockSession(),
            preferences: Self.ephemeralPreferences(),
            checkLogStore: Self.ephemeralCheckLogStore()
        )
        checker.check(userInitiated: true)
        let state = await Self.waitUntilSettled(checker)

        guard case .updateAvailable(let candidate) = state else {
            Issue.record("expected updateAvailable, got \(state)")
            return
        }
        #expect(candidate.tag == "v9.9.9")
        #expect(!fallbackCalled)
    }

    @Test("primary fails: falls back to Vercel endpoint and succeeds")
    func primaryFailureFallsBackToVercel() async throws {
        UpdateFallbackMockURLProtocol.responseHandler = { request in
            if request.url == Self.primaryURL {
                throw URLError(.notConnectedToInternet)
            }
            #expect(request.url == Self.fallbackURL)
            let data = Self.releasesJSON([Self.release(tag: "v9.9.9", asset: "n.dmg")])
            return (Self.http(request, status: 200), data)
        }

        let checker = UpdateChecker(
            releasesURL: Self.primaryURL,
            fallbackReleasesURL: Self.fallbackURL,
            fallbackDownloadURL: Self.fallbackDownloadURL,
            session: Self.mockSession(),
            preferences: Self.ephemeralPreferences(),
            checkLogStore: Self.ephemeralCheckLogStore()
        )
        checker.check(userInitiated: true)
        let state = await Self.waitUntilSettled(checker)

        guard case .updateAvailable(let candidate) = state else {
            Issue.record("expected updateAvailable via fallback, got \(state)")
            return
        }
        #expect(candidate.tag == "v9.9.9")
    }

    @Test("both primary and fallback fail: generic error, no platform named")
    func bothFailYieldsGenericError() async throws {
        UpdateFallbackMockURLProtocol.responseHandler = { request in
            throw URLError(.notConnectedToInternet)
        }

        let checker = UpdateChecker(
            releasesURL: Self.primaryURL,
            fallbackReleasesURL: Self.fallbackURL,
            fallbackDownloadURL: Self.fallbackDownloadURL,
            session: Self.mockSession(),
            preferences: Self.ephemeralPreferences(),
            checkLogStore: Self.ephemeralCheckLogStore()
        )
        checker.check(userInitiated: true)
        let state = await Self.waitUntilSettled(checker)

        guard case .error(let message) = state else {
            Issue.record("expected error, got \(state)")
            return
        }
        #expect(!message.contains("GitHub"))
        #expect(!message.contains("Vercel"))
    }

    @Test("primary rate-limited: reports rate-limit message without trying fallback")
    func rateLimitSkipsFallback() async throws {
        var fallbackCalled = false
        UpdateFallbackMockURLProtocol.responseHandler = { request in
            if request.url == Self.primaryURL {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 403,
                    httpVersion: nil,
                    headerFields: ["X-RateLimit-Remaining": "0"]
                )!
                return (response, Data())
            }
            fallbackCalled = true
            return (Self.http(request, status: 200), Data("[]".utf8))
        }

        let checker = UpdateChecker(
            releasesURL: Self.primaryURL,
            fallbackReleasesURL: Self.fallbackURL,
            fallbackDownloadURL: Self.fallbackDownloadURL,
            session: Self.mockSession(),
            preferences: Self.ephemeralPreferences(),
            checkLogStore: Self.ephemeralCheckLogStore()
        )
        checker.check(userInitiated: true)
        let state = await Self.waitUntilSettled(checker)

        guard case .error(let message) = state else {
            Issue.record("expected error, got \(state)")
            return
        }
        #expect(message.contains("频繁"))
        #expect(!fallbackCalled)
    }

    // MARK: - helpers

    private static func waitUntilSettled(_ checker: UpdateChecker, timeout: TimeInterval = 2) async -> UpdateChecker.State {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if case .checking = checker.state {
                try? await Task.sleep(nanoseconds: 10_000_000)
                continue
            }
            return checker.state
        }
        return checker.state
    }

    private static func http(_ request: URLRequest, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(url: request.url!, statusCode: status, httpVersion: nil, headerFields: [:])!
    }

    private static func release(tag: String, asset: String) -> [String: Any] {
        [
            "tag_name": tag,
            "html_url": "https://github.com/DDonlien/quota-bar/releases/tag/\(tag)",
            "body": "notes",
            "draft": false,
            "prerelease": false,
            "published_at": "2026-07-18T00:00:00Z",
            "assets": [[
                "name": asset,
                "browser_download_url": "https://github.com/DDonlien/quota-bar/releases/download/\(tag)/\(asset)",
            ]],
        ]
    }

    private static func releasesJSON(_ releases: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: releases)
    }

    private static func mockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [UpdateFallbackMockURLProtocol.self]
        return URLSession(configuration: config)
    }

    /// 临时文件路径的 `PreferencesStore`，不碰真实用户的 `preferences.json`。
    private static func ephemeralPreferences() -> PreferencesStore {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-update-checker-tests-\(UUID().uuidString)", isDirectory: true)
        return PreferencesStore(fileURL: dir.appendingPathComponent("preferences.json"))
    }

    /// 临时文件路径的 `ProviderCheckLogStore`，不碰真实用户的「获取日志」文件
    /// （`UpdateCheckLog` 写日志用的就是这个 store）。
    private static func ephemeralCheckLogStore() -> ProviderCheckLogStore {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-update-checker-tests-\(UUID().uuidString)", isDirectory: true)
        return ProviderCheckLogStore(fileURL: dir.appendingPathComponent("provider-check.log"))
    }
}

private final class UpdateFallbackMockURLProtocol: URLProtocol, @unchecked Sendable {
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
