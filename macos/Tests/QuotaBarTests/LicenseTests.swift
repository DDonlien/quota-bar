import Foundation
import Testing
@testable import QuotaBar

/// v0.15.0：7 天试用 + Creem 授权。
///
/// `LicenseEvaluator` 是纯函数（时间从参数进），所以边界可以直接写死日期断言，
/// 不需要改系统时钟或等待真实时间流逝。
@Suite("LicenseEvaluator 试用期边界")
struct LicenseEvaluatorTests {
    private static let start = Date(timeIntervalSince1970: 1_800_000_000)

    private static func stateAfter(days: Double, license: StoredLicense? = nil) -> LicenseState {
        LicenseEvaluator.state(
            firstLaunchAt: start,
            license: license,
            now: start.addingTimeInterval(days * 86_400)
        )
    }

    @Test("首次启动当天：完整 7 天")
    func dayZero() {
        #expect(Self.stateAfter(days: 0.01) == .trial(daysRemaining: 7))
    }

    @Test("第 6 天仍在试用期内")
    func daySix() {
        #expect(Self.stateAfter(days: 6) == .trial(daysRemaining: 1))
    }

    /// 边界本身：整整 7 天时试用**已经结束**（剩余时间为 0，不是"还剩最后一刻"）。
    @Test("满 7 天即结束")
    func daySevenExpires() {
        #expect(Self.stateAfter(days: 7) == .trialExpired)
        #expect(Self.stateAfter(days: 8) == .trialExpired)
    }

    /// 不显示"剩 0 天"——自然语言里那等同于"已经没了"，会让用户以为功能已停。
    @Test("剩不到一天时向上取整为 1 天，不显示 0 天")
    func roundsUpToAtLeastOneDay() {
        #expect(Self.stateAfter(days: 6.9) == .trial(daysRemaining: 1))
    }

    @Test("没有首次启动记录时按完整试用期算")
    func missingFirstLaunch() {
        let state = LicenseEvaluator.state(firstLaunchAt: nil, license: nil, now: Self.start)
        #expect(state == .trial(daysRemaining: 7))
    }

    /// 时钟被往前调（elapsed 为负）时按"刚开始"处理而不是判定异常——
    /// 更可能是换机/时区问题而不是作弊，不该惩罚。
    @Test("系统时钟往前调不会判定为过期")
    func clockSkewDoesNotExpire() {
        let state = LicenseEvaluator.state(
            firstLaunchAt: Self.start,
            license: nil,
            now: Self.start.addingTimeInterval(-86_400)
        )
        #expect(state == .trial(daysRemaining: 7))
    }

    // MARK: 授权优先于试用期

    private static func license(
        status: String = StoredLicense.activeStatus,
        expiresAt: Date? = nil
    ) -> StoredLicense {
        StoredLicense(
            key: "TEST-KEY-0001",
            instanceId: "inst_1",
            status: status,
            activatedAt: start,
            lastValidatedAt: start,
            expiresAt: expiresAt
        )
    }

    /// 已付费用户不该因为"装了很久"被降级——试用期走没走完都无所谓。
    @Test("已激活时忽略试用期是否已过")
    func licensedIgnoresTrialExpiry() {
        let state = Self.stateAfter(days: 999, license: Self.license())
        #expect(state == .licensed(expiresAt: nil))
        #expect(state.allowsAutomaticUpdates)
        #expect(state.isLicensed)
    }

    @Test("非 active 状态降级为 licenseInvalid")
    func nonActiveStatusIsInvalid() {
        let state = Self.stateAfter(days: 1, license: Self.license(status: "disabled"))
        guard case .licenseInvalid = state else {
            Issue.record("expected licenseInvalid, got \(state)")
            return
        }
        #expect(!state.allowsAutomaticUpdates)
    }

    @Test("授权已过期时降级")
    func expiredLicenseIsInvalid() {
        let state = Self.stateAfter(
            days: 10,
            license: Self.license(expiresAt: Self.start.addingTimeInterval(86_400))
        )
        guard case .licenseInvalid = state else {
            Issue.record("expected licenseInvalid, got \(state)")
            return
        }
    }

    /// 状态和到期日同时不满足时，报 Creem 给的状态原因（更准确）。
    @Test("状态与到期日同时无效时优先报状态原因")
    func statusReasonWinsOverExpiry() {
        let state = Self.stateAfter(
            days: 10,
            license: Self.license(status: "disabled", expiresAt: Self.start)
        )
        guard case .licenseInvalid(let reason) = state else {
            Issue.record("expected licenseInvalid, got \(state)")
            return
        }
        #expect(reason.contains("停用"))
    }

    // MARK: 门禁语义

    /// 本 phase 唯一的门禁点就是自动更新——核心功能在任何状态下都不受影响。
    @Test("只有试用结束/授权无效会关闭自动更新")
    func onlyExpiredStatesBlockUpdates() {
        #expect(LicenseState.trial(daysRemaining: 1).allowsAutomaticUpdates)
        #expect(LicenseState.licensed(expiresAt: nil).allowsAutomaticUpdates)
        #expect(!LicenseState.trialExpired.allowsAutomaticUpdates)
        #expect(!LicenseState.licenseInvalid(reason: "x").allowsAutomaticUpdates)
    }
}

// MARK: - LicenseManager

@MainActor
@Suite("LicenseManager 激活与复验", .serialized)
struct LicenseManagerTests {
    private static let activateURL = URL(string: "https://test.local/api/activate")!
    private static let validateURL = URL(string: "https://test.local/api/validate")!

    @Test("激活成功后写入本地授权并进入 licensed")
    func activateSuccess() async {
        LicenseMockURLProtocol.handler = { _ in
            (200, #"{"ok":true,"status":"active","instanceId":"inst_9","expiresAt":null}"#)
        }
        let (manager, prefs) = Self.makeManager()
        await manager.activate(key: "VALID-KEY-123456")

        #expect(manager.state.isLicensed)
        #expect(manager.lastError == nil)
        #expect(prefs.preferences.license?.instanceId == "inst_9")
        #expect(prefs.preferences.license?.key == "VALID-KEY-123456")
    }

    @Test("服务端返回 ok:false 时展示原因且不写入授权")
    func activateRejected() async {
        LicenseMockURLProtocol.handler = { _ in
            (404, #"{"ok":false,"error":"许可证密钥无效"}"#)
        }
        let (manager, prefs) = Self.makeManager()
        await manager.activate(key: "BAD-KEY-1234567")

        #expect(!manager.state.isLicensed)
        #expect(manager.lastError == "许可证密钥无效")
        #expect(prefs.preferences.license == nil)
    }

    @Test("空密钥不发请求")
    func activateEmptyKey() async {
        var called = false
        LicenseMockURLProtocol.handler = { _ in
            called = true
            return (200, #"{"ok":true}"#)
        }
        let (manager, _) = Self.makeManager()
        await manager.activate(key: "   ")

        #expect(!called)
        #expect(manager.lastError != nil)
    }

    /// **fail open 的核心保证**：服务端 5xx 不能吊销一个已经付过钱的授权。
    /// 误判的代价完全不对等——错误保留最多让人多用几天更新，错误吊销会让付费
    /// 用户在服务端抽风时突然被降级。
    @Test("复验遇到服务端 5xx 时保持已激活状态")
    func revalidateFailsOpenOnServerError() async {
        LicenseMockURLProtocol.handler = { _ in (503, #"{"ok":false,"error":"boom"}"#) }
        let (manager, prefs) = Self.makeManager(license: Self.activeLicense(validatedDaysAgo: 30))

        await manager.revalidateIfDue()

        #expect(manager.state.isLicensed)
        #expect(prefs.preferences.license?.status == StoredLicense.activeStatus)
    }

    @Test("复验遇到网络错误时保持已激活状态")
    func revalidateFailsOpenOnNetworkError() async {
        LicenseMockURLProtocol.handler = { _ in throw URLError(.notConnectedToInternet) }
        let (manager, _) = Self.makeManager(license: Self.activeLicense(validatedDaysAgo: 30))

        await manager.revalidateIfDue()

        #expect(manager.state.isLicensed)
    }

    /// 只有 Creem **明确**说不 active 才降级。
    @Test("复验拿到明确的 expired 状态才降级")
    func revalidateDowngradesOnExplicitExpiry() async {
        LicenseMockURLProtocol.handler = { _ in
            (200, #"{"ok":true,"status":"expired","instanceId":"inst_9","expiresAt":null}"#)
        }
        let (manager, prefs) = Self.makeManager(license: Self.activeLicense(validatedDaysAgo: 30))

        await manager.revalidateIfDue()

        #expect(!manager.state.isLicensed)
        #expect(prefs.preferences.license?.status == "expired")
    }

    /// 距离上次复验不到间隔时不该打扰服务端。
    @Test("未到复验间隔时不发请求")
    func revalidateRespectsInterval() async {
        var called = false
        LicenseMockURLProtocol.handler = { _ in
            called = true
            return (200, #"{"ok":true,"status":"active"}"#)
        }
        let (manager, _) = Self.makeManager(license: Self.activeLicense(validatedDaysAgo: 0))

        await manager.revalidateIfDue()

        #expect(!called)
    }

    @Test("移除激活后回到试用期判定")
    func removeActivation() async {
        LicenseMockURLProtocol.handler = { _ in
            (200, #"{"ok":true,"status":"active","instanceId":"inst_9"}"#)
        }
        let (manager, prefs) = Self.makeManager()
        await manager.activate(key: "VALID-KEY-123456")
        #expect(manager.state.isLicensed)

        manager.removeActivation()

        #expect(!manager.state.isLicensed)
        #expect(prefs.preferences.license == nil)
    }

    // MARK: helpers

    private static func activeLicense(validatedDaysAgo: Double) -> StoredLicense {
        StoredLicense(
            key: "VALID-KEY-123456",
            instanceId: "inst_9",
            status: StoredLicense.activeStatus,
            activatedAt: Date().addingTimeInterval(-validatedDaysAgo * 86_400),
            lastValidatedAt: Date().addingTimeInterval(-validatedDaysAgo * 86_400),
            expiresAt: nil
        )
    }

    /// 每个用例一套独立的临时 `preferences.json`，绝不碰真实用户状态。
    private static func makeManager(license: StoredLicense? = nil) -> (LicenseManager, PreferencesStore) {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-license-tests-\(UUID().uuidString)", isDirectory: true)
        let prefs = PreferencesStore(fileURL: dir.appendingPathComponent("preferences.json"))
        if let license { prefs.setLicense(license) }

        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [LicenseMockURLProtocol.self]
        let manager = LicenseManager(
            activateURL: activateURL,
            validateURL: validateURL,
            session: URLSession(configuration: config),
            preferences: prefs
        )
        return (manager, prefs)
    }
}

private final class LicenseMockURLProtocol: URLProtocol, @unchecked Sendable {
    nonisolated(unsafe) static var handler: ((URLRequest) throws -> (Int, String))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        do {
            let (status, body) = try handler(request)
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: status,
                httpVersion: nil,
                headerFields: ["Content-Type": "application/json"]
            )!
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}
