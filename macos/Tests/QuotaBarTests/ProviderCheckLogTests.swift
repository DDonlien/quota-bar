import Foundation
import Testing
@testable import QuotaBar

/// `ProviderCheckLog` 排序规则（用户指定）：
/// 1. 同一个 ProviderName 的内容总是连续输出；
/// 2. Check step 按实际执行顺序输出；
/// 3. 同一个 check step 里的 method name 按实际执行顺序连续输出。
///
/// 用两个 kind 交替 record（模拟 provider 间并发时可能发生的调用交错），验证
/// `flush(kind:)` 落盘后每个 kind 的行仍然完整连续、内部顺序不被打乱。
@Suite("ProviderCheckLog", .serialized)
struct ProviderCheckLogTests {

    @Test("交错 record 的两个 provider，flush 后各自连续且内部顺序不变")
    func interleavedProvidersStayGroupedAndOrdered() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-check-log-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileURL = dir.appendingPathComponent("provider-check.log")
        let store = ProviderCheckLogStore(fileURL: fileURL, maxLines: 4000)
        let log = ProviderCheckLog(store: store)

        // 模拟 provider 间并发：codex 和 claude 的 record 调用交替发生。
        await log.record(kind: .codex, step: .provider, method: "cli:codex", outcome: .success, detail: "命中")
        await log.record(kind: .claude, step: .provider, method: "App Bundle", outcome: .failure, detail: "未命中")
        await log.record(kind: .codex, step: .quota, method: "codex-auth", outcome: .success, detail: "获取到 2 条额度窗口")
        await log.record(kind: .claude, step: .provider, method: "cli:claude", outcome: .success, detail: "命中：/opt/homebrew/bin/claude")
        await log.record(kind: .codex, step: .plan, method: "codex-auth", outcome: .success, detail: "档位=Plus，价格=$20/月")
        await log.record(kind: .claude, step: .quota, method: "claude-statusline", outcome: .failure, detail: "sourceUnavailable")
        await log.record(kind: .claude, step: .quota, method: "claude-oauth", outcome: .success, detail: "获取到 2 条额度窗口")

        await log.flush(kind: .codex)
        await log.flush(kind: .claude)

        let lines = store.readRecentLines()
        #expect(lines.count == 7)

        let codexLines = Array(lines.prefix(3))
        let claudeLines = Array(lines.suffix(4))

        // Codex 的 3 行必须连续出现在前面（先 flush 先落盘），且内部顺序是
        // provider → quota → plan（真实调用顺序）。
        #expect(codexLines.allSatisfy { $0.contains("- Codex |") })
        #expect(codexLines[0].contains("Provider 获取"))
        #expect(codexLines[1].contains("额度获取"))
        #expect(codexLines[2].contains("档位与费用获取"))

        // Claude 的 4 行连续出现在后面，内部顺序按真实调用顺序：
        // provider（App Bundle 未命中）→ provider（cli:claude 命中）→
        // quota（statusline 失败）→ quota（oauth 成功）。
        #expect(claudeLines.allSatisfy { $0.contains("- Claude |") })
        #expect(claudeLines[0].contains("App Bundle"))
        #expect(claudeLines[1].contains("cli:claude"))
        #expect(claudeLines[2].contains("claude-statusline"))
        #expect(claudeLines[3].contains("claude-oauth"))
    }

    @Test("flush 空缓冲区不写入任何内容")
    func flushingEmptyBufferWritesNothing() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-check-log-empty-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileURL = dir.appendingPathComponent("provider-check.log")
        let store = ProviderCheckLogStore(fileURL: fileURL)
        let log = ProviderCheckLog(store: store)

        let lines = await log.flush(kind: .kimi)
        #expect(lines.isEmpty)
        #expect(!FileManager.default.fileExists(atPath: fileURL.path))
    }

    @Test("行格式匹配 <timestamp> - <Provider> | <Step> | <Method> | <成功/失败/跳过> | <详细内容>")
    func lineFormatMatchesSpec() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-check-log-format-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileURL = dir.appendingPathComponent("provider-check.log")
        let store = ProviderCheckLogStore(fileURL: fileURL)
        let log = ProviderCheckLog(store: store)

        await log.record(kind: .kimi, step: .quota, method: "配置/凭证 → API", outcome: .success, detail: "来源 kimi-desktop-token：获取到 3 条额度窗口")
        await log.flush(kind: .kimi)

        let line = try #require(store.readRecentLines().first)
        let pattern = #"^\d{4}\.\d{2}\.\d{2}_\d{2}\.\d{2}\.\d{2} - Kimi \| 额度获取 \| 配置/凭证 → API \| 成功 \| 来源 kimi-desktop-token：获取到 3 条额度窗口$"#
        #expect(line.range(of: pattern, options: .regularExpression) != nil)
    }

    @Test("outcome 独立于 detail 自由文本，跳过态也能正确落盘")
    func skippedOutcomeRoundTrips() async throws {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-check-log-skip-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: dir) }
        let fileURL = dir.appendingPathComponent("provider-check.log")
        let store = ProviderCheckLogStore(fileURL: fileURL)
        let log = ProviderCheckLog(store: store)

        await log.record(kind: .zcode, step: .expiration, method: "-", outcome: .skipped, detail: "该 provider 未配置独立过期日来源")
        await log.flush(kind: .zcode)

        let line = try #require(store.readRecentLines().first)
        #expect(line.contains("| 跳过 |"))
    }
}
