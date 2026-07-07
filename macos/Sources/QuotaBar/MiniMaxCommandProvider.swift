import Foundation

/// MiniMax 真实 CLI 命令数据源：执行 `mmx quota show --output json` 并解析 stdout。
///
/// 与 `MiniMaxCLIProvider`（读 `~/.mmx/config.json` 后直调 HTTP API）的区别：
/// 本 provider 是**真正的 CLI 层**——让 mmx 自己处理鉴权、region、token 刷新，
/// Quota Bar 只消费结构化输出。实测 `mmx` 在非 TTY 下配 `--output json` 可用：
/// - 订阅有效：输出 coding_plan/remains 形状的 JSON（`model_remains` 等）；
/// - 订阅到期：输出 `{"error":{"code":1,"message":"API error: no active token plan subscription (HTTP 200)"}}`。
///
/// GUI app 不继承用户 shell PATH（launchd 的 PATH 没有 Homebrew / nvm / asdf
/// 等自定义安装目录），路径解析交给 `CLICommandLocator`（常见目录 + 登录 shell
/// 兜底，覆盖任意安装方式，而不是猜几个固定路径）。
final class MiniMaxCommandProvider: QuotaProvider, @unchecked Sendable {

    let id = "minimax-mmx-cli"
    let kind: ProviderKind = .minimax
    var displayName: String { kind.displayName }

    /// 命令执行器：输入（可执行路径, 参数），返回 stdout。测试可注入。
    typealias CommandExecutor = @Sendable (String, [String], TimeInterval) async throws -> Data

    /// `nil` = 生产默认，交给 `CLICommandLocator` 动态解析；
    /// 非 nil = 测试专用，只在这些候选路径里找，不走 locator（保证测试确定性）。
    private let explicitCandidates: [String]?
    private let executor: CommandExecutor
    private let dateProvider: () -> Date

    init(
        executablePathCandidates: [String]? = nil,
        executor: CommandExecutor? = nil,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.explicitCandidates = executablePathCandidates
        self.executor = executor ?? Self.runProcess
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let fetchedAt = dateProvider()
        let mmxPath: String
        if let explicitCandidates {
            guard let found = explicitCandidates.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                throw QuotaFetchError.sourceUnavailable(detail: "未找到 mmx CLI（已检查候选路径）")
            }
            mmxPath = found
        } else {
            guard let found = await CLICommandLocator.locate("mmx") else {
                throw QuotaFetchError.sourceUnavailable(detail: "未找到 mmx CLI（已检查常见安装目录及登录 shell PATH）")
            }
            mmxPath = found
        }

        let stdout = try await executor(mmxPath, ["quota", "show", "--output", "json"], timeout)
        return try await Self.parseCommandOutput(stdout, fetchedAt: fetchedAt)
    }

    /// 解析 CLI stdout：错误包裹 → notSubscribed / transient；否则走共享 remains 解析。
    static func parseCommandOutput(_ data: Data, fetchedAt: Date) async throws -> ProviderSnapshot {
        // 输出可能带非 JSON 前后缀（进度条清屏符等），截取首个 { 到末个 }。
        let jsonData = extractJSONObject(from: data) ?? data
        if let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
           let error = json["error"] as? [String: Any] {
            let message = (error["message"] as? String) ?? "未知错误"
            if MiniMaxCLIProvider.indicatesNoActiveSubscription(message) {
                throw QuotaFetchError.notSubscribed(detail: "MiniMax Coding Plan 订阅已到期或未订阅")
            }
            throw QuotaFetchError.transient(detail: "mmx quota 错误：\(message)")
        }
        return try await MiniMaxQuotaResponseParser.parse(data: jsonData, fetchedAt: fetchedAt)
    }

    private static func extractJSONObject(from data: Data) -> Data? {
        guard let text = String(data: data, encoding: .utf8),
              let first = text.firstIndex(of: "{"),
              let last = text.lastIndex(of: "}")
        else { return nil }
        return Data(text[first...last].utf8)
    }

    /// 默认执行器：Process 跑命令，带超时强杀。
    private static let runProcess: CommandExecutor = { path, arguments, timeout in
        try await withThrowingTaskGroup(of: Data.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data, Error>) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        let process = Process()
                        process.executableURL = URL(fileURLWithPath: path)
                        process.arguments = arguments
                        // 继承完整父进程环境，只覆盖 TERM 抑制交互式 TUI 输出——
                        // 不能整体替换成只有 HOME 的精简环境：CLI 自身的鉴权/Keychain
                        // 读取可能依赖 USER 等变量识别当前用户身份，替换掉会导致
                        // 明明本机已登录却读成未登录（同类 bug 在 Claude CLI provider
                        // 上已实测复现并修复）。
                        var environment = ProcessInfo.processInfo.environment
                        environment["TERM"] = "dumb"
                        process.environment = environment
                        let stdoutPipe = Pipe()
                        process.standardOutput = stdoutPipe
                        process.standardError = FileHandle.nullDevice
                        do {
                            try process.run()
                        } catch {
                            continuation.resume(throwing: QuotaFetchError.sourceUnavailable(
                                detail: "mmx 启动失败：\(error.localizedDescription)"
                            ))
                            return
                        }
                        let output = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                        process.waitUntilExit()
                        continuation.resume(returning: output)
                    }
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                throw QuotaFetchError.transient(detail: "mmx quota 执行超时（\(Int(timeout))s）")
            }
            guard let first = try await group.next() else {
                throw QuotaFetchError.sourceUnavailable(detail: "mmx quota 无输出")
            }
            group.cancelAll()
            return first
        }
    }
}
