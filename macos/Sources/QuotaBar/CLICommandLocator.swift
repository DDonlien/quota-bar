import Foundation

/// 命令行工具路径解析——面向任意用户机器设计，不假设固定安装方式。
///
/// **背景**：GUI app 的进程环境来自 launchd，PATH 只有系统默认目录，不包含用户
/// shell 配置文件（`.zshrc` / `.zprofile` / `.bash_profile` 等）里追加的路径。
/// 这意味着通过 Homebrew、nvm、asdf、pnpm、MacPorts、pipx 或任何自定义方式安装的
/// CLI 工具，单纯查 `ProcessInfo.processInfo.environment["PATH"]` 或直接调
/// `which` 都可能找不到——因为子进程继承的还是 launchd 那份精简 PATH。
///
/// **策略（两级）**：
/// 1. 先查一批公开发行版最常见的固定目录（免开销，覆盖 Homebrew 两种架构前缀、
///    MacPorts、用户级 `~/.local/bin` 等）；
/// 2. 命中失败再退化到「登录 shell 解析」：`$SHELL -lc 'command -v <cmd>'`，
///    这样会 source 用户实际的 shell 配置文件，能覆盖 nvm/asdf/pnpm 等任意自定义
///    PATH 追加方式——只要用户在终端里能跑通这个命令，这里就能解析到。
///    代价是较慢（可能触发 nvm/conda 等初始化脚本），因此设超时，并按命令名做
///    进程内缓存（一次 App 生命周期只解析一次，5 分钟自动刷新不会重复触发）。
enum CLICommandLocator {
    private actor Cache {
        var storage: [String: String?] = [:]

        func get(_ key: String) -> String?? {
            storage[key]
        }

        func set(_ key: String, _ value: String?) {
            storage[key] = value
        }

        func reset() {
            storage.removeAll()
        }
    }

    private static let cache = Cache()

    /// 常见非 PATH 默认安装目录（按检出概率排序）。仅覆盖固定路径的安装方式；
    /// nvm / asdf / pnpm 等版本管理器的路径本质上是用户自定义且不固定，
    /// 必须靠下面的登录 shell 解析兜底，不能穷举。
    private static func commonCandidateDirectories() -> [String] {
        let home = NSHomeDirectory()
        return [
            "/opt/homebrew/bin",       // Homebrew · Apple Silicon
            "/opt/homebrew/sbin",
            "/usr/local/bin",          // Homebrew · Intel Mac / 传统 Unix 惯例
            "/usr/local/sbin",
            "/opt/local/bin",          // MacPorts
            "\(home)/.local/bin",      // pipx / 多数官方安装脚本的用户级惯例
            "\(home)/bin",
            "/usr/bin",
            "/bin",
        ]
    }

    /// 解析命令的可执行文件路径；找不到返回 nil。
    ///
    /// 结果按命令名缓存在内存里（含「找不到」的 nil 结果），避免每轮刷新
    /// 重复触发较慢的登录 shell 解析。缓存只在当前 App 进程生命周期内有效。
    static func locate(_ command: String, shellTimeout: TimeInterval = 3) async -> String? {
        if let cached = await cache.get(command) {
            return cached
        }

        let resolved = await locateUncached(command, shellTimeout: shellTimeout)
        await cache.set(command, resolved)
        return resolved
    }

    /// 仅测试使用：清空缓存，避免不同测试用例之间互相污染。
    static func resetCacheForTesting() async {
        await cache.reset()
    }

    private static func locateUncached(_ command: String, shellTimeout: TimeInterval) async -> String? {
        for dir in commonCandidateDirectories() {
            let candidate = "\(dir)/\(command)"
            if FileManager.default.isExecutableFile(atPath: candidate) {
                return candidate
            }
        }
        return await resolveViaLoginShell(command, timeout: shellTimeout)
    }

    /// 用登录 shell 解析：`$SHELL -lc 'command -v <cmd>'`。
    /// 用 POSIX 内建 `command -v` 而不是外部程序 `which`，减少一次进程依赖；
    /// `-l`（login）确保 profile 文件真正被 source，覆盖用户任意自定义 PATH。
    private static func resolveViaLoginShell(_ command: String, timeout: TimeInterval) async -> String? {
        // 避免 shell 元字符注入：命令名只允许常见可执行文件名字符。
        guard command.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "-" || $0 == "_" || $0 == "." }) else {
            return nil
        }
        let shell = ProcessInfo.processInfo.environment["SHELL"] ?? "/bin/zsh"
        guard FileManager.default.isExecutableFile(atPath: shell) else { return nil }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: shell)
        process.arguments = ["-lc", "command -v \(command)"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        let output: String? = try? await withThrowingTaskGroup(of: String?.self) { group in
            group.addTask {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<String?, Error>) in
                    DispatchQueue.global(qos: .userInitiated).async {
                        do {
                            try process.run()
                        } catch {
                            continuation.resume(returning: nil)
                            return
                        }
                        let data = pipe.fileHandleForReading.readDataToEndOfFile()
                        process.waitUntilExit()
                        guard process.terminationStatus == 0 else {
                            continuation.resume(returning: nil)
                            return
                        }
                        let text = String(data: data, encoding: .utf8)?
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        continuation.resume(returning: text)
                    }
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
                // 超时：主动终止挂起的登录 shell，避免僵尸进程堆积。
                if process.isRunning { process.terminate() }
                return nil
            }
            guard let first = try await group.next() else { return nil }
            group.cancelAll()
            return first
        }

        guard let output, !output.isEmpty, FileManager.default.isExecutableFile(atPath: output) else {
            return nil
        }
        return output
    }
}
