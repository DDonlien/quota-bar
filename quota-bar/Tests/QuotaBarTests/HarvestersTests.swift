import Foundation
import Testing
@testable import QuotaBar

// MARK: - Harvesters registry 测试
//
// 验证 ProviderKind → SubscriptionDateHarvester 映射正确：
// 1. 5 个 provider（Codex / Claude / Cursor / MiniMax / Antigravity）有对应 harvester；
// 2. Kimi 保留 membership 页 headless 兜底；
// 3. 其它 provider（Gemini / DeepSeek 等）暂未接入，返回 nil；
// 4. supportedKinds 包含全部已注册 provider。

@Suite("Harvesters registry")
struct HarvestersTests {

    @Test("Codex → CodexHarvester")
    func codexHarvester() {
        let harvester = Harvesters.harvester(for: .codex)
        #expect(harvester is CodexHarvester)
        #expect(harvester?.identifier == "codex-harvester")
    }

    @Test("openai 共享 Codex harvester")
    func openaiShared() {
        let harvester = Harvesters.harvester(for: .openai)
        #expect(harvester is CodexHarvester)
    }

    @Test("Claude → ClaudeHarvester")
    func claudeHarvester() {
        let harvester = Harvesters.harvester(for: .claude)
        #expect(harvester is ClaudeHarvester)
        #expect(harvester?.identifier == "claude-harvester")
    }

    @Test("Cursor → CursorHarvester")
    func cursorHarvester() {
        let harvester = Harvesters.harvester(for: .cursor)
        #expect(harvester is CursorHarvester)
        #expect(harvester?.identifier == "cursor-harvester")
    }

    @Test("MiniMax → MiniMaxHarvester")
    func minimaxHarvester() {
        let harvester = Harvesters.harvester(for: .minimax)
        #expect(harvester is MiniMaxHarvester)
        #expect(harvester?.identifier == "minimax-harvester")
    }

    @Test("Antigravity → AntigravityHarvester")
    func antigravityHarvester() {
        let harvester = Harvesters.harvester(for: .antigravity)
        #expect(harvester is AntigravityHarvester)
        #expect(harvester?.identifier == "antigravity-harvester")
    }

    @Test("Kimi → KimiHarvester（membership 页 headless 兜底）")
    func kimiHarvesterFallback() {
        let harvester = Harvesters.harvester(for: .kimi)
        #expect(harvester is KimiHarvester)
        #expect(harvester?.identifier == "kimi-harvester")
    }

    @Test("暂未接入的 provider 返回 nil")
    func unsupportedKinds() {
        #expect(Harvesters.harvester(for: .gemini) == nil)
        #expect(Harvesters.harvester(for: .deepseek) == nil)
        #expect(Harvesters.harvester(for: .copilot) == nil)
        #expect(Harvesters.harvester(for: .openrouter) == nil)
        #expect(Harvesters.harvester(for: .perplexity) == nil)
        #expect(Harvesters.harvester(for: .warp) == nil)
        #expect(Harvesters.harvester(for: .trae) == nil)
    }

    @Test("supportedKinds 包含 7 个过期日 headless provider（含 openai 共享和 Kimi）")
    func supportedKinds() {
        let kinds = Set(Harvesters.supportedKinds)
        #expect(kinds.contains(.codex))
        #expect(kinds.contains(.openai))  // 与 codex 共享 CodexHarvester
        #expect(kinds.contains(.claude))
        #expect(kinds.contains(.cursor))
        #expect(kinds.contains(.minimax))
        #expect(kinds.contains(.antigravity))
        #expect(kinds.contains(.kimi))
        #expect(kinds.count == 7)
    }

    @Test("每个 harvester 的 pageURL 是 https URL")
    func allHarvestersHTTPS() {
        for kind in Harvesters.supportedKinds {
            guard let harvester = Harvesters.harvester(for: kind) else {
                Issue.record("\(kind.rawValue) 应有 harvester")
                continue
            }
            #expect(harvester.pageURL.scheme == "https", "\(kind.rawValue) 的 pageURL 应是 https")
            #expect(!harvester.identifier.isEmpty, "\(kind.rawValue) identifier 不能为空")
        }
    }
}
