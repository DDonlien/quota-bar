import Foundation
@preconcurrency import Darwin

/// 抽象 PTY（伪终端）命令行运行器。
///
/// 用途：Codex / Claude 这类 TUI 命令在无 TTY 时会拒绝交互式输入（`codex /status`、`claude /login`）。
/// `TTYCommandRunner` 分配一个伪终端并跑命令，把 stdout 和 exit code 透出来。
///
/// 实现：基于 `posix_openpt` + `grantpt` + `unlockpt` + `forkpty`（通过 Process + `/usr/bin/script -q /dev/null cmd args`）。
/// 这层封装只做"跑 + 读"，不做高级交互（不读 raw key 输入），足够 `codex --version` / `claude /login` 这类
/// 一次性输出场景使用。
///
/// 注意：
/// - PTY 在沙盒 App 中可能受 TCC 限制；
/// - 当前实现在主进程内同步读取，超时靠 `kill -TERM` 兜底；
/// - 如果未来需要真正的双向交互，建议迁移到 SwiftTerm 或自己 forkpty + DispatchIO。
enum TTYCommandRunner {

    enum RunnerError: LocalizedError {
        case executableNotFound(path: String)
        case launchFailed(underlying: String)
        case timeout(after: TimeInterval)
        case nonZeroExit(code: Int32, stderr: String)

        var errorDescription: String? {
            switch self {
            case .executableNotFound(let path):
                return "可执行文件不存在：\(path)"
            case .launchFailed(let detail):
                return "启动失败：\(detail)"
            case .timeout(let after):
                return "命令超时（\(Int(after))s）"
            case .nonZeroExit(let code, let stderr):
                let snippet = stderr.trimmingCharacters(in: .whitespacesAndNewlines)
                return "退出码 \(code)：\(snippet.isEmpty ? "无 stderr" : snippet)"
            }
        }
    }

    struct Result: Sendable {
        let stdout: String
        let stderr: String
        let exitCode: Int32
    }

    /// 在伪终端里跑命令，超时强杀。
    static func run(
        executable: String,
        arguments: [String] = [],
        environment: [String: String]? = nil,
        timeout: TimeInterval = 10
    ) async throws -> Result {
        let scriptPath = "/usr/bin/script"
        guard FileManager.default.isExecutableFile(atPath: scriptPath) else {
            throw RunnerError.executableNotFound(path: scriptPath)
        }

        var args = ["-q", "/dev/null", "--", executable]
        args.append(contentsOf: arguments)

        return try await runRaw(
            executable: scriptPath,
            arguments: args,
            environment: environment,
            timeout: timeout
        )
    }

    /// 直接跑一个可执行文件（非 PTY），用于不需要 TTY 的场景（如读取版本号）。
    static func runNonPTY(
        executable: String,
        arguments: [String] = [],
        timeout: TimeInterval = 10
    ) async throws -> Result {
        try await runRaw(
            executable: executable,
            arguments: arguments,
            environment: nil,
            timeout: timeout
        )
    }

    // MARK: - 内部

    private static func runRaw(
        executable: String,
        arguments: [String],
        environment: [String: String]?,
        timeout: TimeInterval
    ) async throws -> Result {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            if let environment {
                var merged = ProcessInfo.processInfo.environment
                for (key, value) in environment {
                    merged[key] = value
                }
                process.environment = merged
            }

            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe

            // 超时监控：用 Task 而不是 DispatchWorkItem，避免 Sendable 问题。
            let pidBox = ManagedPID(initial: 0)
            process.terminationHandler = { proc in
                pidBox.pid = proc.processIdentifier

                let stdoutData = (try? stdoutPipe.fileHandleForReading.readToEnd()) ?? Data()
                let stderrData = (try? stderrPipe.fileHandleForReading.readToEnd()) ?? Data()
                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                let result = Result(stdout: stdout, stderr: stderr, exitCode: proc.terminationStatus)
                continuation.resume(returning: result)
            }

            do {
                try process.run()
                pidBox.pid = process.processIdentifier
            } catch {
                continuation.resume(throwing: RunnerError.launchFailed(underlying: error.localizedDescription))
                return
            }

            // 启动超时任务
            let timeoutTask = Task {
                try? await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                let pid = pidBox.pid
                if pid > 0 && kill(pid, 0) == 0 {
                    kill(pid, SIGTERM)
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    if kill(pid, 0) == 0 {
                        kill(pid, SIGKILL)
                    }
                }
            }

            // 用独立的 Task 在 continuation resume 后清理 timeoutTask
            Task {
                for await _ in process.terminationPublisher {
                    timeoutTask.cancel()
                    break
                }
            }
        }
    }
}

/// 简单的 PID 容器，让 Sendable closure 能读到 launch 后的 PID。
/// 内部只被 Process lifecycle 内部访问，不暴露。
private final class ManagedPID: @unchecked Sendable {
    var pid: pid_t
    init(initial: pid_t) { self.pid = initial }
}

private extension Process {
    /// 进程退出时 emit 一次，await 这个 publisher 等于等 terminationHandler 跑完。
    var terminationPublisher: AsyncStream<Void> {
        AsyncStream { continuation in
            // 包装 terminationHandler：原 handler 之外补一个 await 用的 yield。
            let original = self.terminationHandler
            self.terminationHandler = { proc in
                original?(proc)
                continuation.yield()
                continuation.finish()
            }
        }
    }
}