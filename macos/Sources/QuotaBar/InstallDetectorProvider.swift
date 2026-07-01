import Foundation
import AppKit

/// 「已安装」探测 Provider。
///
/// 作为 pipeline 的第一步：先确认本机**至少有 App/CLI/env 凭证**之一，
/// 否则直接 `sourceUnavailable` → `.notInstalled` → UI 过滤掉。
///
/// 解决的核心问题：
/// - 本机**完全没装**的服务（比如 Claude，没 App 没 CLI 也没 web 登录）
///   不应该出现在 dashboard 里。
/// - 但只要检测到任何一种存在方式，就以 `needsConfiguration` 显示，
///   让用户知道「我装了/有凭证，但 dashboard 数据没拿到」。
///
/// 检测项：
/// 1. **App Bundle**：用 `NSWorkspace` + 候选 App 名探测（沿用 `AppBundleProvider` 思路）；
/// 2. **CLI 命令**：`kind.cliCommands` 指定的可执行命令候选是否在 PATH；
/// 3. **环境变量凭证**：`kind.envVarNames` 列出的环境变量是否有值。
final class InstallDetectorProvider: QuotaProvider, @unchecked Sendable {

    let id: String
    let kind: ProviderKind
    var displayName: String { kind.displayName }

    /// App 在文件系统的可能名字（不含 `.app` 后缀），用于 fallback 探测。
    private let candidateAppNames: [String]

    init(id: String, kind: ProviderKind, candidateAppNames: [String] = []) {
        self.id = id
        self.kind = kind
        self.candidateAppNames = candidateAppNames
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        var reasons: [String] = []

        if let appPath = findAppPath() {
            reasons.append("App 已装（\(appPath)）")
        }

        for command in kind.cliCommands {
            if let path = findCommand(command) {
                reasons.append("CLI 已装（\(path)）")
                break
            }
        }

        for envName in kind.envVarNames {
            if let value = ProcessInfo.processInfo.environment[envName], !value.isEmpty {
                reasons.append("\(envName) 已配置")
            }
        }

        for path in kind.credentialFiles {
            let expanded = (path as NSString).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expanded) {
                reasons.append("凭证文件存在（\(path)）")
            }
        }

        guard !reasons.isEmpty else {
            throw QuotaFetchError.sourceUnavailable(
                detail: "未检测到 \(kind.displayName) 的 App/CLI/凭证"
            )
        }

        return ProviderSnapshot(
            kind: kind,
            availability: .needsConfiguration(reason: reasons.joined(separator: "；")),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: Date()
        )
    }

    // MARK: - App 路径搜索

    private func findAppPath() -> String? {
        let home = NSHomeDirectory()
        let searchDirs = [
            "/Applications",
            "/Applications/Utilities",
            "\(home)/Applications",
            "\(home)/Applications/Utilities",
        ]

        if let bundleID = kind.bundleIdentifier,
           let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url.path
        }

        for name in candidateAppNames {
            for dir in searchDirs {
                let candidate = "\(dir)/\(name).app"
                if FileManager.default.fileExists(atPath: candidate) {
                    return candidate
                }
            }
        }

        return nil
    }

    // MARK: - CLI 探测

    private func findCommand(_ command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()

        do {
            try task.run()
            task.waitUntilExit()
            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if let path, !path.isEmpty {
                    return path
                }
            }
        } catch {
            return nil
        }
        return nil
    }
}
