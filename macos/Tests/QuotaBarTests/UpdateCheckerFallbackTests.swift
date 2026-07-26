import Foundation
import Testing
@testable import QuotaBar

/// 两源查询的降级行为。
///
/// v0.14.0 引入时是「GitHub 优先 → Vercel 兜底」；v0.15.0 安装包迁到 Vercel Blob 后
/// **调换成「官网优先 → GitHub 降级」**（原因见 `UpdateChecker.primaryReleasesURL`
/// 的说明：继续先问 GitHub 会永久判定"已是最新"）。这里的 `primaryURL` 因此代表
/// 官网 endpoint、`legacyURL` 代表 GitHub。
@MainActor
@Suite("UpdateChecker primary → legacy fallback", .serialized)
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
            primaryReleasesURL: Self.primaryURL,
            legacyReleasesURL: Self.fallbackURL,
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
            primaryReleasesURL: Self.primaryURL,
            legacyReleasesURL: Self.fallbackURL,
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
            primaryReleasesURL: Self.primaryURL,
            legacyReleasesURL: Self.fallbackURL,
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

    /// 限流是 GitHub 特有的失败形态，v0.15.0 调换顺序后它落在**降级源**那一侧：
    /// 官网先失败、再问 GitHub 又撞上限流时，要给出"过于频繁"这个具体原因，
    /// 而不是笼统的"暂时无法检查更新"——两者的用户动作不同（等一会 vs 查网络）。
    @Test("legacy source rate-limited: reports the rate-limit message specifically")
    func legacyRateLimitReportsRateLimitMessage() async throws {
        UpdateFallbackMockURLProtocol.responseHandler = { request in
            if request.url == Self.primaryURL {
                throw URLError(.notConnectedToInternet)
            }
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 403,
                httpVersion: nil,
                headerFields: ["X-RateLimit-Remaining": "0"]
            )!
            return (response, Data())
        }

        let checker = UpdateChecker(
            primaryReleasesURL: Self.primaryURL,
            legacyReleasesURL: Self.fallbackURL,
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
