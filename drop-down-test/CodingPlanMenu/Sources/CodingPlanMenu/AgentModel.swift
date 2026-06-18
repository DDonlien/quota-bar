import Foundation

// MARK: - Provider 定义

enum AgentProvider: String, CaseIterable, Identifiable, Sendable {
    case codex = "Codex"
    case claude = "Claude"
    case cursor = "Cursor"
    case gemini = "Gemini"
    case kimi = "Kimi"
    case minimax = "MiniMax"
    case openai = "OpenAI"
    case deepseek = "DeepSeek"
    case copilot = "Copilot"
    case openrouter = "OpenRouter"
    case perplexity = "Perplexity"
    case warp = "Warp"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var iconSymbol: String {
        switch self {
        case .codex: return "terminal"
        case .claude: return "message"
        case .cursor: return "cursorarrow"
        case .gemini: return "sparkles"
        case .kimi: return "moon"
        case .minimax: return "bolt"
        case .openai: return "brain"
        case .deepseek: return "magnifyingglass"
        case .copilot: return "airplane"
        case .openrouter: return "network"
        case .perplexity: return "questionmark.circle"
        case .warp: return "arrow.right.circle"
        }
    }

    var cliCommand: String? {
        switch self {
        case .codex: return "codex"
        case .claude: return "claude"
        case .gemini: return "gemini"
        default: return nil
        }
    }

    var bundleIdentifier: String? {
        switch self {
        case .cursor: return "com.todesktop.230313mzl4w4u92"
        case .warp: return "dev.warp.Warp-Stable"
        default: return nil
        }
    }

    var envVarNames: [String] {
        switch self {
        case .openai: return ["OPENAI_API_KEY"]
        case .claude: return ["ANTHROPIC_API_KEY"]
        case .deepseek: return ["DEEPSEEK_API_KEY"]
        case .openrouter: return ["OPENROUTER_API_KEY"]
        case .copilot: return ["GITHUB_TOKEN", "GITHUB_COPILOT_TOKEN"]
        default: return []
        }
    }

    var cookieDomains: [String] {
        switch self {
        case .codex: return ["openai.com", "chat.openai.com", "platform.openai.com"]
        case .claude: return ["anthropic.com", "claude.ai"]
        case .cursor: return ["cursor.com", "cursor.sh"]
        case .gemini: return ["google.com", "gemini.google.com"]
        case .kimi: return ["kimi.moonshot.cn", "moonshot.cn"]
        case .minimax: return ["minimax.chat"]
        case .openai: return ["openai.com", "platform.openai.com"]
        case .deepseek: return ["deepseek.com", "chat.deepseek.com"]
        case .copilot: return ["github.com", "copilot.github.com"]
        case .openrouter: return ["openrouter.ai"]
        case .perplexity: return ["perplexity.ai"]
        case .warp: return []
        }
    }
}

// MARK: - 认证方式

enum AuthMethod: String, Sendable {
    case cli = "CLI"
    case browserCookie = "浏览器 Cookie"
    case apiKey = "API Key"
    case oauth = "OAuth"
    case appBundle = "应用"
    case unknown = "未知"
}

// MARK: - Agent 状态

enum AgentStatus: String, Sendable {
    case available = "available"
    case needsAuth = "needsAuth"
    case notInstalled = "notInstalled"
    case unknown = "unknown"

    var displayName: String {
        switch self {
        case .available: return "可用"
        case .needsAuth: return "待配置"
        case .notInstalled: return "未安装"
        case .unknown: return "未知"
        }
    }

    var priority: Int {
        switch self {
        case .available: return 3
        case .needsAuth: return 2
        case .unknown: return 1
        case .notInstalled: return 0
        }
    }
}

// MARK: - Agent 信息

struct AgentInfo: Identifiable, Sendable {
    let id = UUID()
    let provider: AgentProvider
    let status: AgentStatus
    let authMethod: AuthMethod?
    let installPath: String?
    let configPath: String?
    let lastDetected: Date
    let errorMessage: String?
}

// MARK: - 探测结果汇总

struct DetectionResult: Sendable {
    let agents: [AgentInfo]
    let timestamp: Date

    var availableAgents: [AgentInfo] {
        agents.filter { $0.status == .available }
    }

    var needsAuthAgents: [AgentInfo] {
        agents.filter { $0.status == .needsAuth }
    }

    var notInstalledAgents: [AgentInfo] {
        agents.filter { $0.status == .notInstalled }
    }

    var unknownAgents: [AgentInfo] {
        agents.filter { $0.status == .unknown }
    }

    var totalAvailableCount: Int {
        availableAgents.count
    }

    var totalDetectedCount: Int {
        agents.filter { $0.status != .notInstalled }.count
    }
}
