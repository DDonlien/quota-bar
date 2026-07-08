import Foundation
import AppKit

/// 预扫描：本机上「已安装/已登录」的 provider 检测器。
///
/// 设计：
/// - **轻量探测**：每条 strategy 只跑「检查是否安装 + 是否登录」，不抓真实数据；
/// - **结果驱动**：探测出的 AgentInfo 列表可注入到 UI（菜单/状态栏）做引导；
/// - **不替代 FetchPipeline**：真实额度由 RefreshCoordinator + FetchPipeline 拉取。
///
/// 这里把历史上独立的 AgentProvider 折进了 ProviderKind（同一枚举），避免两套体系并存。
struct AgentDetector {

    /// 主探测入口：并发跑 4 条路径（CLI / App / Browser / API Key），合并去重。
    static func detectAll() async -> DetectionResult {
        var providerMap: [ProviderKind: AgentInfo] = [:]

        async let cliResults = detectCLIProviders()
        async let appResults = detectAppProviders()
        async let browserResults = detectBrowserProviders()
        async let apiKeyResults = detectAPIKeyProviders()

        let results = await [cliResults, appResults, browserResults, apiKeyResults]

        for agents in results {
            for agent in agents {
                if let existing = providerMap[agent.provider] {
                    if agent.status.priority > existing.status.priority {
                        providerMap[agent.provider] = agent
                    }
                } else {
                    providerMap[agent.provider] = agent
                }
            }
        }

        var allAgents = Array(providerMap.values)

        let detectedProviders = Set(allAgents.map(\.provider))
        for provider in ProviderKind.allCases where !detectedProviders.contains(provider) {
            allAgents.append(AgentInfo(
                provider: provider,
                status: .notInstalled,
                authMethod: nil,
                installPath: nil,
                configPath: nil,
                lastDetected: Date(),
                errorMessage: nil
            ))
        }

        return DetectionResult(
            agents: allAgents.sorted { $0.provider.rawValue < $1.provider.rawValue },
            timestamp: Date()
        )
    }

    // MARK: - CLI 探测

    private static func detectCLIProviders() -> [AgentInfo] {
        var results: [AgentInfo] = []

        for provider in ProviderKind.allCases {
            guard let command = provider.cliCommand else { continue }

            if let path = findCommandInPath(command) {
                let isAuthenticated = checkCLIAuthenticated(provider: provider, path: path)

                results.append(AgentInfo(
                    provider: provider,
                    status: isAuthenticated ? .available : .needsAuth,
                    authMethod: .cli,
                    installPath: path,
                    configPath: nil,
                    lastDetected: Date(),
                    errorMessage: nil
                ))
            }
        }

        return results
    }

    // MARK: - 应用探测

    private static func detectAppProviders() -> [AgentInfo] {
        var results: [AgentInfo] = []

        for provider in ProviderKind.allCases {
            guard let bundleID = provider.bundleIdentifier else { continue }

            if let appPath = findApp(bundleID: bundleID) {
                results.append(AgentInfo(
                    provider: provider,
                    status: .available,
                    authMethod: .appBundle,
                    installPath: appPath,
                    configPath: nil,
                    lastDetected: Date(),
                    errorMessage: nil
                ))
            }
        }

        return results
    }

    // MARK: - 浏览器 Cookie 探测

    private static func detectBrowserProviders() -> [AgentInfo] {
        var results: [AgentInfo] = []
        let home = NSHomeDirectory()

        for provider in ProviderKind.allCases {
            let domains = provider.cookieDomains
            guard !domains.isEmpty else { continue }

            if checkSafariCookies(home: home) {
                results.append(AgentInfo(
                    provider: provider,
                    status: .available,
                    authMethod: .browserCookie,
                    installPath: nil,
                    configPath: nil,
                    lastDetected: Date(),
                    errorMessage: nil
                ))
                continue
            }

            if checkChromeCookies(home: home) {
                results.append(AgentInfo(
                    provider: provider,
                    status: .available,
                    authMethod: .browserCookie,
                    installPath: nil,
                    configPath: nil,
                    lastDetected: Date(),
                    errorMessage: nil
                ))
                continue
            }

            if checkFirefoxCookies(home: home) {
                results.append(AgentInfo(
                    provider: provider,
                    status: .available,
                    authMethod: .browserCookie,
                    installPath: nil,
                    configPath: nil,
                    lastDetected: Date(),
                    errorMessage: nil
                ))
                continue
            }
        }

        return results
    }

    // MARK: - API Key 探测

    private static func detectAPIKeyProviders() -> [AgentInfo] {
        var results: [AgentInfo] = []

        for provider in ProviderKind.allCases {
            let envVars = provider.envVarNames
            guard !envVars.isEmpty else { continue }

            for envVar in envVars {
                if let value = ProcessInfo.processInfo.environment[envVar], !value.isEmpty {
                    results.append(AgentInfo(
                        provider: provider,
                        status: .available,
                        authMethod: .apiKey,
                        installPath: nil,
                        configPath: nil,
                        lastDetected: Date(),
                        errorMessage: nil
                    ))
                    break
                }
            }

            if results.contains(where: { $0.provider == provider }) { continue }

            if let configPath = findAPIKeyInShellConfig(provider: provider, envVars: envVars) {
                results.append(AgentInfo(
                    provider: provider,
                    status: .available,
                    authMethod: .apiKey,
                    installPath: nil,
                    configPath: configPath,
                    lastDetected: Date(),
                    errorMessage: nil
                ))
            }
        }

        return results
    }

    // MARK: - 辅助方法

    private static func findCommandInPath(_ command: String) -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        task.arguments = [command]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe

        do {
            try task.run()
            task.waitUntilExit()

            if task.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let path = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
                return path?.isEmpty == false ? path : nil
            }
        } catch {
            return nil
        }

        return nil
    }

    private static func checkCLIAuthenticated(provider: ProviderKind, path: String) -> Bool {
        switch provider {
        case .claude:
            return fileExists(atPath: "\(NSHomeDirectory())/.claude")
        case .codex:
            let codexHome = ProcessInfo.processInfo.environment["CODEX_HOME"]
                ?? "\(NSHomeDirectory())/.codex"
            return fileExists(atPath: "\(codexHome)/auth.json")
        case .gemini:
            return fileExists(atPath: "\(NSHomeDirectory())/.gemini")
        case .opencode:
            return fileExists(atPath: "\(NSHomeDirectory())/.local/share/opencode/auth.json")
        default:
            return true
        }
    }

    private static func findApp(bundleID: String) -> String? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url.path
        }

        let lastComponent = bundleID.components(separatedBy: ".").last ?? ""
        let appPaths = [
            "/Applications/\(bundleID).app",
            "/Applications/\(lastComponent).app",
            "/Applications/Cursor.app",
            "/Applications/Warp.app",
            "/Applications/TRAE SOLO.app",
            "/Applications/Trae.app",
            "/Applications/Antigravity.app",
            "/Applications/Kimi.app",
            "/Applications/MiniMax Code.app",
            "\(NSHomeDirectory())/Applications/Cursor.app",
            "\(NSHomeDirectory())/Applications/Warp.app",
            "\(NSHomeDirectory())/Applications/TRAE SOLO.app",
            "\(NSHomeDirectory())/Applications/Antigravity.app",
            "\(NSHomeDirectory())/Applications/Kimi.app",
            "\(NSHomeDirectory())/Applications/MiniMax Code.app",
        ]

        for path in appPaths {
            if fileExists(atPath: path) {
                return path
            }
        }

        return nil
    }

    private static func checkSafariCookies(home: String) -> Bool {
        let safariPaths = [
            "\(home)/Library/Cookies/Cookies.binarycookies",
            "\(home)/Library/Containers/com.apple.Safari/Data/Library/Cookies/Cookies.binarycookies",
        ]
        return safariPaths.contains(where: fileExists)
    }

    private static func checkChromeCookies(home: String) -> Bool {
        let chromePaths = [
            "\(home)/Library/Application Support/Google/Chrome/Default/Cookies",
            "\(home)/Library/Application Support/Google/Chrome/Profile 1/Cookies",
        ]
        return chromePaths.contains(where: fileExists)
    }

    private static func checkFirefoxCookies(home: String) -> Bool {
        let firefoxProfiles = "\(home)/Library/Application Support/Firefox/Profiles"
        if let profiles = try? FileManager.default.contentsOfDirectory(atPath: firefoxProfiles) {
            for profile in profiles {
                if fileExists(atPath: "\(firefoxProfiles)/\(profile)/cookies.sqlite") {
                    return true
                }
            }
        }
        return false
    }

    private static func findAPIKeyInShellConfig(provider: ProviderKind, envVars: [String]) -> String? {
        let home = NSHomeDirectory()
        let configs = [
            "\(home)/.zshrc",
            "\(home)/.bashrc",
            "\(home)/.bash_profile",
            "\(home)/.zprofile",
            "\(home)/.profile",
        ]

        for configPath in configs {
            if let content = try? String(contentsOfFile: configPath, encoding: .utf8) {
                for envVar in envVars {
                    if content.contains(envVar) {
                        return configPath
                    }
                }
            }
        }

        return nil
    }

    private static func fileExists(atPath path: String) -> Bool {
        FileManager.default.fileExists(atPath: path)
    }
}
