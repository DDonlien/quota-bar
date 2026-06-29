import Foundation

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
    let provider: ProviderKind
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