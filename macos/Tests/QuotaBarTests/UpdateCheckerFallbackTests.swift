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
            checkLogStore: Self.ephemeralCheckLogStore(),
            // 门禁 2026-07-31 收紧后覆盖了 userInitiated: true 的路径——不注入的话
            // 这些测试会读 LicenseManager.shared.state，也就是跑测试这台机器当下
            // 真实的试用/激活状态，结果随开发机的试用期是否已过而漂移。
            licenseStateProvider: { .trial(daysRemaining: 7) }
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
            checkLogStore: Self.ephemeralCheckLogStore(),
            // 门禁 2026-07-31 收紧后覆盖了 userInitiated: true 的路径——不注入的话
            // 这些测试会读 LicenseManager.shared.state，也就是跑测试这台机器当下
            // 真实的试用/激活状态，结果随开发机的试用期是否已过而漂移。
            licenseStateProvider: { .trial(daysRemaining: 7) }
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
            checkLogStore: Self.ephemeralCheckLogStore(),
            // 门禁 2026-07-31 收紧后覆盖了 userInitiated: true 的路径——不注入的话
            // 这些测试会读 LicenseManager.shared.state，也就是跑测试这台机器当下
            // 真实的试用/激活状态，结果随开发机的试用期是否已过而漂移。
            licenseStateProvider: { .trial(daysRemaining: 7) }
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
            checkLogStore: Self.ephemeralCheckLogStore(),
            // 门禁 2026-07-31 收紧后覆盖了 userInitiated: true 的路径——不注入的话
            // 这些测试会读 LicenseManager.shared.state，也就是跑测试这台机器当下
            // 真实的试用/激活状态，结果随开发机的试用期是否已过而漂移。
            licenseStateProvider: { .trial(daysRemaining: 7) }
        )
        checker.check(userInitiated: true)
        let state = await Self.waitUntilSettled(checker)

        guard case .error(let message) = state else {
            Issue.record("expected error, got \(state)")
            return
        }
        #expect(message.contains("频繁"))
    }

    // MARK: - 授权门禁（2026-07-31）
    //
    // 用户反馈：试用过期后唯一该有的限制是"不能检查更新"，但当时手动点「检查更新」
    // 仍会绕过门禁、照常查到并展示真实的新版本——门禁只挡了 `userInitiated == false`
    // 那一条路径。下面两个测试锁住修正后的行为：手动/自动都被挡，且都不发起真实请求
    // （`requestMade` 断言的是网络层——如果门禁形同虚设，mock handler 会被调用到）。

    @Test("manual check while unlicensed: blocked with a visible, actionable message, no request made")
    func manualCheckBlockedWhenUnlicensed() async throws {
        var requestMade = false
        UpdateFallbackMockURLProtocol.responseHandler = { _ in
            requestMade = true
            return (Self.http(URLRequest(url: Self.primaryURL), status: 200), Data("[]".utf8))
        }

        let checker = UpdateChecker(
            primaryReleasesURL: Self.primaryURL,
            legacyReleasesURL: Self.fallbackURL,
            fallbackDownloadURL: Self.fallbackDownloadURL,
            session: Self.mockSession(),
            preferences: Self.ephemeralPreferences(),
            checkLogStore: Self.ephemeralCheckLogStore(),
            licenseStateProvider: { .trialExpired }
        )
        checker.check(userInitiated: true)
        // 门禁在 check() 内同步返回，不经过网络往返，不需要等待。
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(!requestMade, "试用过期时手动检查不该真的发请求")
        guard case .error(let message) = checker.state else {
            Issue.record("expected error, got \(checker.state)")
            return
        }
        #expect(message.contains("激活"), "必须明确告诉用户为什么、怎么恢复，不能是空泛的失败提示")
    }

    @Test("automatic check while unlicensed: silently skipped, existing state untouched")
    func automaticCheckSkippedWhenUnlicensedStaysQuiet() async throws {
        var requestMade = false
        UpdateFallbackMockURLProtocol.responseHandler = { _ in
            requestMade = true
            return (Self.http(URLRequest(url: Self.primaryURL), status: 200), Data("[]".utf8))
        }

        let checker = UpdateChecker(
            primaryReleasesURL: Self.primaryURL,
            legacyReleasesURL: Self.fallbackURL,
            fallbackDownloadURL: Self.fallbackDownloadURL,
            session: Self.mockSession(),
            preferences: Self.ephemeralPreferences(),
            checkLogStore: Self.ephemeralCheckLogStore(),
            licenseStateProvider: { .trialExpired }
        )
        checker.check(userInitiated: false)
        try await Task.sleep(nanoseconds: 20_000_000)

        #expect(!requestMade)
        // 后台/自动触发（打开关于页、定时轮询）不该每次都弹一条错误——保持 .idle，
        // 跟"什么都没发生"一致，不打扰用户。
        #expect(checker.state == .idle, "自动触发被门禁挡住时不该改变可见状态")
    }

    /// 2026-07-31：`updatesRequireLicense` 是「检查更新」按钮 `.disabled` 绑定的那个
    /// 属性——按用户要求，试用过期后按钮要直接置灰（能看见、点不了），而不是能点、
    /// 点了才用 `.error` 状态告诉你不行。这里直接锁定该属性本身的极性，防止以后
    /// 重命名/重构时不小心把 `!` 丢了或者接反，那样会让按钮的可用性和真实授权状态
    /// 完全颠倒却编译通过、不被任何一个"点击行为"测试发现。
    @Test("updatesRequireLicense reflects license state, driving the button's disabled binding")
    func updatesRequireLicenseTracksLicenseState() {
        func checker(_ state: LicenseState) -> UpdateChecker {
            UpdateChecker(
                primaryReleasesURL: Self.primaryURL,
                legacyReleasesURL: Self.fallbackURL,
                fallbackDownloadURL: Self.fallbackDownloadURL,
                session: Self.mockSession(),
                preferences: Self.ephemeralPreferences(),
                checkLogStore: Self.ephemeralCheckLogStore(),
                licenseStateProvider: { state }
            )
        }
        #expect(checker(.trialExpired).updatesRequireLicense)
        #expect(checker(.licenseInvalid(reason: "x")).updatesRequireLicense)
        #expect(!checker(.trial(daysRemaining: 3)).updatesRequireLicense)
        #expect(!checker(.licensed(expiresAt: nil)).updatesRequireLicense)
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
