import Foundation
import AppKit

struct AgentDetector {
    // MARK: - 主探测入口

    static func detectAll() async -> DetectionResult {
        var providerMap: [AgentProvider: AgentInfo] = [:]

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
        for provider in AgentProvider.allCases where !detectedProviders.contains(provider) {
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

        for provider in AgentProvider.allCases {
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

        for provider in AgentProvider.allCases {
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

        for provider in AgentProvider.allCases {
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

        for provider in AgentProvider.allCases {
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

    private static func checkCLIAuthenticated(provider: AgentProvider, path: String) -> Bool {
        switch provider {
        case .claude:
            let configDir = "\(NSHomeDirectory())/.claude"
            return fileExists(atPath: configDir)
        case .codex:
            return fileExists(atPath: "\(NSHomeDirectory())/.config/openai")
        case .gemini:
            return fileExists(atPath: "\(NSHomeDirectory())/.gemini")
        default:
            return true
        }
    }

    private static func findApp(bundleID: String) -> String? {
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            return url.path
        }

        let appPaths = [
            "/Applications/\(bundleID.components(separatedBy: ".").last ?? "").app",
            "/Applications/Cursor.app",
            "/Applications/Warp.app",
            "\(NSHomeDirectory())/Applications/Cursor.app",
            "\(NSHomeDirectory())/Applications/Warp.app",
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

    private static func findAPIKeyInShellConfig(provider: AgentProvider, envVars: [String]) -> String? {
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
