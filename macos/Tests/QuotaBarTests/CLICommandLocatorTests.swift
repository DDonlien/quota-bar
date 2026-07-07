import Foundation
import Testing
@testable import QuotaBar

/// `CLICommandLocator`：面向任意用户机器的命令路径解析（常见目录 → 登录 shell
/// 兜底），覆盖 Homebrew（两种架构）、MacPorts、用户级安装以外的自定义 PATH。
@Suite("CLICommandLocator", .serialized)
struct CLICommandLocatorTests {

    @Test("finds a well-known system binary via the fast common-directory path")
    func findsSystemBinary() async {
        await CLICommandLocator.resetCacheForTesting()
        // /bin/ls 在任意 macOS 上都存在，且 /bin 在候选目录列表里，
        // 命中走的是快路径，不需要触发登录 shell 解析。
        let path = await CLICommandLocator.locate("ls")
        #expect(path == "/bin/ls")
    }

    @Test("returns nil for a command that exists nowhere")
    func returnsNilForUnknownCommand() async {
        await CLICommandLocator.resetCacheForTesting()
        let path = await CLICommandLocator.locate("quota-bar-definitely-not-a-real-command-xyz")
        #expect(path == nil)
    }

    @Test("caches the resolution so repeated calls are consistent")
    func cachesResolution() async {
        await CLICommandLocator.resetCacheForTesting()
        let first = await CLICommandLocator.locate("ls")
        let second = await CLICommandLocator.locate("ls")
        #expect(first == second)
        #expect(first == "/bin/ls")
    }

    @Test("rejects command names with shell metacharacters before ever spawning a shell")
    func rejectsShellMetacharacters() async {
        await CLICommandLocator.resetCacheForTesting()
        // 危险字符不在常见目录里也肯定不存在，同时验证不会因为拼接进 shell -lc
        // 字符串而被解释成命令注入；应直接返回 nil。
        let path = await CLICommandLocator.locate("ls; touch /tmp/quota-bar-injection-test")
        #expect(path == nil)
        #expect(!FileManager.default.fileExists(atPath: "/tmp/quota-bar-injection-test"))
    }

    @Test("resetCacheForTesting clears previously cached nil results")
    func resetClearsCache() async {
        await CLICommandLocator.resetCacheForTesting()
        _ = await CLICommandLocator.locate("quota-bar-definitely-not-a-real-command-xyz")
        await CLICommandLocator.resetCacheForTesting()
        // 重置后应该能重新解析（这里只验证不 crash、结果一致，不是缓存命中）。
        let path = await CLICommandLocator.locate("quota-bar-definitely-not-a-real-command-xyz")
        #expect(path == nil)
    }
}
