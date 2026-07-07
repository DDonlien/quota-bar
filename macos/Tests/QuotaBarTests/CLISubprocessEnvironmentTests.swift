import Foundation
import Testing
@testable import QuotaBar

/// 回归测试：CLI provider 生成子进程时必须继承完整父进程环境（只覆盖必要的
/// 个别变量），不能整体替换成精简环境。
///
/// 根因复现：`claude auth status --json` 在只给 `HOME` 的精简环境下会报
/// `loggedIn: false`（即便本机真实已登录），补上 `USER` 后恢复正常——
/// 说明该 CLI 读取自身登录态/Keychain 时依赖 `USER` 之类的变量识别当前用户，
/// 而不仅仅是 `HOME`。`ClaudeAuthStatusCLIProvider` / `MiniMaxCommandProvider`
/// 此前都整体替换成 `["HOME": ...]`（或加 `TERM`），导致这两个 CLI 数据源
/// 在真实用户机器上系统性失效，跟浏览器/WebView 授权毫无关系。
///
/// 这里不依赖真实 `mmx`/`claude` 二进制：生成一个打印 `$USER` 的可执行脚本，
/// 顶替候选路径，用 provider 的**默认执行器**（真实 `Process` 调用路径，
/// 不注入 mock executor）来验证环境变量确实被继承。
@Suite("CLI subprocess environment inheritance", .serialized)
struct CLISubprocessEnvironmentTests {

    @Test("MiniMaxCommandProvider's real process executor inherits USER from parent environment")
    func miniMaxInheritsUser() async throws {
        let scriptPath = try Self.makeEchoUserScript(errorField: true)
        defer { try? FileManager.default.removeItem(atPath: scriptPath) }

        let provider = MiniMaxCommandProvider(executablePathCandidates: [scriptPath])
        do {
            _ = try await provider.fetchSnapshot(timeout: 5)
            Issue.record("脚本总是输出 error 包裹，应该走到 notSubscribed/transient 分支")
        } catch let error as QuotaFetchError {
            let description = String(describing: error)
            let expectedUser = ProcessInfo.processInfo.environment["USER"] ?? ""
            #expect(!expectedUser.isEmpty, "测试环境本身没有 USER，无法验证")
            #expect(description.contains("USER=\(expectedUser)"), "期望子进程环境里带真实 USER，实际: \(description)")
            #expect(!description.contains("USER=<unset>"))
        }
    }

    @Test("ClaudeAuthStatusCLIProvider's real process executor inherits USER from parent environment")
    func claudeAuthStatusInheritsUser() async throws {
        let scriptPath = try Self.makeEchoUserScript(errorField: false)
        defer { try? FileManager.default.removeItem(atPath: scriptPath) }

        let provider = ClaudeAuthStatusCLIProvider(executablePathCandidates: [scriptPath])
        let snapshot = try await provider.fetchSnapshot(timeout: 5)
        // 脚本按 USER 是否存在决定 loggedIn；USER 有传进来时脚本报 loggedIn=true
        // 并把 subscriptionType 设成 USER 的值，用它间接验证环境确实被继承。
        let expectedUser = ProcessInfo.processInfo.environment["USER"] ?? ""
        #expect(!expectedUser.isEmpty, "测试环境本身没有 USER，无法验证")
        #expect(snapshot.subscriptionTier != nil)
    }

    /// 生成一个打印 `$USER` 的可执行脚本。
    /// - Parameter errorField: true 时输出 MiniMax 的 `{"error":{"message":...}}` 包裹形状；
    ///   false 时输出 Claude 的 `{"loggedIn":...,"subscriptionType":...}` 形状。
    private static func makeEchoUserScript(errorField: Bool) throws -> String {
        let dir = URL(fileURLWithPath: NSTemporaryDirectory())
            .appendingPathComponent("quota-bar-env-test-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let scriptURL = dir.appendingPathComponent("fake-cli.sh")
        let script: String
        if errorField {
            script = """
            #!/bin/bash
            echo "{\\"error\\":{\\"message\\":\\"USER=${USER:-<unset>}\\"}}"
            """
        } else {
            script = """
            #!/bin/bash
            if [ -n "$USER" ]; then
              echo "{\\"loggedIn\\": true, \\"subscriptionType\\": \\"$USER\\"}"
            else
              echo "{\\"loggedIn\\": false}"
            fi
            """
        }
        try script.write(to: scriptURL, atomically: true, encoding: .utf8)
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: scriptURL.path)
        return scriptURL.path
    }
}
