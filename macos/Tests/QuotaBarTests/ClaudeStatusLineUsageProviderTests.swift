import Foundation
import Testing
@testable import QuotaBar

/// Claude Code `statusLine` hook 额度捕获——数据形状经开源项目 ping-island
/// （`ClaudeUsageLoaderTests.swift`）交叉验证：`rate_limits.{five_hour,seven_day}`，
/// `used_percentage`/`utilization` 是同义字段，`resets_at` 可能是 epoch 数字、
/// ISO8601 字符串或缺失。
@Suite("ClaudeStatusLineUsageProvider", .serialized)
struct ClaudeStatusLineUsageProviderTests {

    @Test("parses used_percentage with epoch resets_at")
    func parsesUsedPercentageEpoch() throws {
        let json: [String: Any] = [
            "rate_limits": [
                "five_hour": ["used_percentage": 42, "resets_at": 1_760_000_000],
                "seven_day": ["used_percentage": 17.5, "resets_at": 1_760_500_000],
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let windows = try #require(ClaudeStatusLineUsageProvider.parseRateLimits(data))
        #expect(windows.count == 2)
        let session = try #require(windows.first { $0.periodSeconds == 5 * 3600 })
        #expect(abs(session.remainingFraction - 0.58) < 0.001)
        #expect(session.resetsAt == Date(timeIntervalSince1970: 1_760_000_000))
    }

    @Test("parses utilization alias with ISO8601 resets_at and nil resets_at")
    func parsesUtilizationAliasISO8601() throws {
        let json: [String: Any] = [
            "rate_limits": [
                "five_hour": ["utilization": 0, "resets_at": NSNull()],
                "seven_day": ["utilization": 23, "resets_at": "2026-02-09T12:00:00.462679+00:00"],
            ],
        ]
        let data = try JSONSerialization.data(withJSONObject: json)
        let windows = try #require(ClaudeStatusLineUsageProvider.parseRateLimits(data))
        let session = try #require(windows.first { $0.periodSeconds == 5 * 3600 })
        #expect(session.remainingFraction == 1.0)
        #expect(session.resetsAt == nil)
        let weekly = try #require(windows.first { $0.periodSeconds == 7 * 86400 })
        #expect(abs(weekly.remainingFraction - 0.77) < 0.001)
        #expect(weekly.resetsAt != nil)
    }

    @Test("returns nil when rate_limits key is absent")
    func returnsNilWithoutRateLimits() {
        let data = try! JSONSerialization.data(withJSONObject: ["model": ["display_name": "Claude"]] as [String: Any])
        #expect(ClaudeStatusLineUsageProvider.parseRateLimits(data) == nil)
    }

    @Test("throws sourceUnavailable when cache file is missing")
    func missingCacheFile() async {
        let provider = ClaudeStatusLineUsageProvider(cachePath: "/nonexistent/claude-statusline-cache.json")
        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .sourceUnavailable = error else {
                Issue.record("期望 sourceUnavailable，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }

    @Test("throws sourceUnavailable when cache is stale beyond maxAge")
    func staleCache() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-statusline-stale-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let cacheURL = dir.appendingPathComponent("cache.json")
        let json: [String: Any] = ["rate_limits": ["five_hour": ["used_percentage": 10]]]
        try JSONSerialization.data(withJSONObject: json).write(to: cacheURL)
        // 把 mtime 改到 10 小时前，超过默认 6 小时新鲜度窗口。
        let oldDate = Date(timeIntervalSinceNow: -10 * 3600)
        try FileManager.default.setAttributes([.modificationDate: oldDate], ofItemAtPath: cacheURL.path)

        let provider = ClaudeStatusLineUsageProvider(cachePath: cacheURL.path, maxAge: 6 * 3600)
        do {
            _ = try await provider.fetchSnapshot(timeout: 1)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .sourceUnavailable = error else {
                Issue.record("期望 sourceUnavailable，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }

    @Test("succeeds when cache is fresh and contains rate_limits")
    func freshCacheSucceeds() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-statusline-fresh-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let cacheURL = dir.appendingPathComponent("cache.json")
        let json: [String: Any] = [
            "rate_limits": ["five_hour": ["used_percentage": 10], "seven_day": ["used_percentage": 5]],
        ]
        try JSONSerialization.data(withJSONObject: json).write(to: cacheURL)

        let provider = ClaudeStatusLineUsageProvider(cachePath: cacheURL.path)
        let snapshot = try await provider.fetchSnapshot(timeout: 1)
        #expect(snapshot.availability == .available)
        #expect(snapshot.quotas.count == 2)
    }
}

/// hook 安装器：全部指向临时目录，不触碰真实 `~/.claude/settings.json`。
@Suite("ClaudeStatusLineHookInstaller", .serialized)
struct ClaudeStatusLineHookInstallerTests {

    @Test("installs statusLine into empty settings.json and writes an executable script")
    func installsIntoEmptySettings() throws {
        let (installer, root) = try Self.makeInstaller()
        defer { try? FileManager.default.removeItem(at: root) }

        let result = installer.install()
        #expect(result == .installed)

        let settingsData = try Data(contentsOf: URL(fileURLWithPath: installer.settingsPath))
        let json = try JSONSerialization.jsonObject(with: settingsData) as? [String: Any]
        let statusLine = json?["statusLine"] as? [String: Any]
        #expect(statusLine?["command"] as? String == installer.scriptPath)
        #expect(FileManager.default.isExecutableFile(atPath: installer.scriptPath))
    }

    @Test("does not overwrite an existing unmanaged statusLine")
    func preservesExistingUnmanagedStatusLine() throws {
        let (installer, root) = try Self.makeInstaller()
        defer { try? FileManager.default.removeItem(at: root) }

        // 用户已有自己的 statusLine 配置（不是我们写的）。
        let existing: [String: Any] = ["statusLine": ["type": "command", "command": "/usr/local/bin/my-custom-statusline"]]
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: installer.settingsPath).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONSerialization.data(withJSONObject: existing).write(to: URL(fileURLWithPath: installer.settingsPath))

        let result = installer.install()
        #expect(result == .skippedExistingStatusLine)

        let settingsData = try Data(contentsOf: URL(fileURLWithPath: installer.settingsPath))
        let json = try JSONSerialization.jsonObject(with: settingsData) as? [String: Any]
        let statusLine = json?["statusLine"] as? [String: Any]
        #expect(statusLine?["command"] as? String == "/usr/local/bin/my-custom-statusline", "不应该覆盖用户已有配置")
    }

    @Test("re-installing over our own managed statusLine is idempotent")
    func reinstallOverOwnConfigIsIdempotent() throws {
        let (installer, root) = try Self.makeInstaller()
        defer { try? FileManager.default.removeItem(at: root) }

        #expect(installer.install() == .installed)
        #expect(installer.install() == .installed, "第二次安装应该识别出是自己的配置，正常覆盖/刷新")
    }

    @Test("uninstall removes only our own managed statusLine, not user's custom one")
    func uninstallRemovesOnlyOwnConfig() throws {
        let (installer, root) = try Self.makeInstaller()
        defer { try? FileManager.default.removeItem(at: root) }

        _ = installer.install()
        installer.uninstall()
        let settingsData = try Data(contentsOf: URL(fileURLWithPath: installer.settingsPath))
        let json = try JSONSerialization.jsonObject(with: settingsData) as? [String: Any]
        #expect(json?["statusLine"] == nil)
    }

    @Test("uninstall is a no-op when statusLine belongs to the user, not us")
    func uninstallNoOpForUnmanagedStatusLine() throws {
        let (installer, root) = try Self.makeInstaller()
        defer { try? FileManager.default.removeItem(at: root) }

        let existing: [String: Any] = ["statusLine": ["type": "command", "command": "/usr/local/bin/my-custom-statusline"]]
        try FileManager.default.createDirectory(
            at: URL(fileURLWithPath: installer.settingsPath).deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try JSONSerialization.data(withJSONObject: existing).write(to: URL(fileURLWithPath: installer.settingsPath))

        installer.uninstall()
        let settingsData = try Data(contentsOf: URL(fileURLWithPath: installer.settingsPath))
        let json = try JSONSerialization.jsonObject(with: settingsData) as? [String: Any]
        let statusLine = json?["statusLine"] as? [String: Any]
        #expect(statusLine?["command"] as? String == "/usr/local/bin/my-custom-statusline")
    }

    private static func makeInstaller() throws -> (ClaudeStatusLineHookInstaller, URL) {
        let root = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-statusline-installer-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        let installer = ClaudeStatusLineHookInstaller(
            settingsPath: root.appendingPathComponent("claude-settings.json").path,
            scriptDirectory: root.appendingPathComponent("hooks").path,
            cacheDirectory: root.appendingPathComponent("cache").path
        )
        return (installer, root)
    }
}
