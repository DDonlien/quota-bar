import Foundation

// MARK: - Dashboard 端点注册表

/// 每个 ProviderKind 对应的真实 dashboard 端点 + 解析器。
///
/// 端点来源：参考 CodexBar 的实现。
/// - Codex (chatgpt.com)：`https://chatgpt.com/backend-api/wham/usage`
/// - Claude (claude.ai)：先用 `/api/organizations` 拿 org_id，再 `/api/organizations/{orgId}/usage`
/// - Gemini：暂未对接（需要 Google Cloud 项目 ID + Vertex AI API key）
///
/// 当 endpoint 改变或被反爬时，解析器返回 nil，由 BrowserCookieProvider 走降级路径。
enum DashboardEndpoints {

    struct Endpoint {
        let url: URL
        let parser: DashboardParser
    }

    static func endpoint(for kind: ProviderKind) -> Endpoint? {
        switch kind {
        case .codex, .openai:
            return Endpoint(
                url: URL(string: "https://chatgpt.com/backend-api/wham/usage")!,
                parser: CodexDashboardParser()
            )
        case .claude:
            // Claude dashboard 需要先拿 org_id；fallback 走 `/api/organizations`，
            // 由 ClaudeDashboardParser 内部再 GET `/api/organizations/{id}/usage`。
            return Endpoint(
                url: URL(string: "https://claude.ai/api/organizations")!,
                parser: ClaudeDashboardParser()
            )
        case .minimax:
            // MiniMax Coding Plan dashboard（与 MiniMaxConfigProvider 调同一个 endpoint，
            // 但用浏览器 cookie 替代 API key）。当用户在浏览器已登录 minimax.chat 时，
            // 此路径无需 API key 即可拿数据。注意：Cloudflare 可能拦截简单 curl 调用，
            // 真实成功率依赖浏览器 cookie 是否包含正确的 cf_clearance / session。
            return Endpoint(
                url: URL(string: "https://api.minimaxi.com/v1/coding_plan/remains")!,
                parser: MiniMaxDashboardParser()
            )
        case .gemini:
            return nil
        default:
            return nil
        }
    }
}

// MARK: - 解析器协议

protocol DashboardParser: Sendable {
    /// 从响应数据解析出 quota 窗口；解析失败返回 nil（让上层降级）。
    func parse(data: Data) -> [QuotaWindow]?
}

// MARK: - Codex / OpenAI Wham Usage 解析

/// 解析 `https://chatgpt.com/backend-api/wham/usage` 返回的 JSON：
/// ```json
/// {
///   "plan_type": "plus",
///   "rate_limit": {
///     "primary_window":   { "used_percent": 25, "reset_at": 1735689600, "limit_window_seconds": 18000 },
///     "secondary_window": { "used_percent": 60, "reset_at": 1736294400, "limit_window_seconds": 604800 }
///   }
/// }
/// ```
struct CodexDashboardParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }
        let rateLimit = (json["rate_limit"] as? [String: Any]) ?? json
        var windows: [QuotaWindow] = []

        if let primary = pickWindow(in: rateLimit, names: ["five_hour", "primary_window", "five_hour_limit"]),
           let window = makeWindow(from: primary, title: "5小时额度") {
            windows.append(window)
        }
        if let secondary = pickWindow(in: rateLimit, names: ["weekly", "secondary_window", "weekly_limit"]),
           let window = makeWindow(from: secondary, title: "周额度") {
            windows.append(window)
        }

        // 按"最短订阅周期优先"排序（5小时 < 周），UI 层会再 sort 一遍保证一致性。
        windows.sort { ($0.periodSeconds ?? .greatestFiniteMagnitude) < ($1.periodSeconds ?? .greatestFiniteMagnitude) }

        return windows.isEmpty ? nil : windows
    }

    private func pickWindow(in rateLimit: [String: Any], names: [String]) -> [String: Any]? {
        for name in names {
            if let dict = rateLimit[name] as? [String: Any] {
                return dict
            }
        }
        return nil
    }

    private func makeWindow(from dict: [String: Any], title: String) -> QuotaWindow? {
        let usedPercent = (dict["used_percent"] as? NSNumber)?.doubleValue
            ?? (dict["percent_used"] as? NSNumber)?.doubleValue
            ?? (dict["usage_percent"] as? NSNumber)?.doubleValue
            ?? (dict["usage"] as? NSNumber)?.doubleValue
        guard let usedPercent else { return nil }
        let remainingFraction = max(0, min(1, 1.0 - usedPercent / 100.0))

        let periodSeconds: TimeInterval? = {
            if let raw = (dict["limit_window_seconds"] as? NSNumber)?.doubleValue
                ?? (dict["window_seconds"] as? NSNumber)?.doubleValue {
                return raw
            }
            // 从标题推断兜底（"5小时额度" / "周额度"）
            if title.contains("5小时") { return 5 * 3600 }
            if title.contains("周") { return 7 * 86400 }
            if title.contains("天") { return 86400 }
            return nil
        }()

        let resetAt: Date? = {
            if let raw = (dict["reset_at"] as? NSNumber)?.doubleValue {
                return Date(timeIntervalSince1970: raw)
            }
            if let str = dict["reset_at"] as? String,
               let raw = TimeInterval(str) {
                return Date(timeIntervalSince1970: raw)
            }
            return nil
        }()

        let refreshText: String = {
            guard let resetAt else { return "刷新时间未知" }
            return QuotaResetText.description(for: resetAt)
        }()

        return QuotaWindow(
            title: title,
            remainingFraction: remainingFraction,
            refreshDescription: refreshText,
            resetsAt: resetAt,
            periodSeconds: periodSeconds
        )
    }
}

// MARK: - Claude Dashboard 解析（两步式，目前仅第一步）

/// Claude dashboard 需要两个步骤：
/// 1. `GET /api/organizations` → `[{uuid, name, capabilities, ...}]`
/// 2. `GET /api/organizations/{uuid}/usage` → `[{utilization, resets_at}, ...]`
///
/// 第一步确认账号已登录；第二步拿真实 quota 数据。
///
/// 当前实现：第一步 parser 检测到账号 → 返回 nil 让上层 fallback；
/// 真实两步调度需要 BrowserCookieProvider 支持双 endpoint，等下次迭代。
/// 现在 Claude 的状态会显示「已检测到 Claude 账号，dashboard 待接入」。
struct ClaudeDashboardParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        // 第一步只验证账号存在即可；quota 数据需要二次请求，所以这里返回 nil。
        return nil
    }
}

// MARK: - MiniMax Coding Plan 解析

/// 解析 `https://api.minimaxi.com/v1/coding_plan/remains` 响应：
/// ```json
/// {
///   "model_remains": [{"model_name": "MiniMax-M2", "remains": 500}, ...],
///   "current_package_name": "Plus",
///   "current_package_id": 1,
///   "remains": ["unlimited" | 500],
///   "tool_remains": [...],
///   "base_resp": {"status_code": 0, "status_msg": "success"}
/// }
/// ```
///
/// 注意：MiniMax 响应里**没有传统意义的 5h/周额度**，而是按 model 维度给出剩余
/// 调用次数。`remains` 数组（顶层）通常对应单一主套餐剩余；`model_remains[]`
/// 是各 model 的剩余配额。我们把每个 model 渲染成 1 个 QuotaWindow。
struct MiniMaxDashboardParser: DashboardParser {
    func parse(data: Data) -> [QuotaWindow]? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // status_code != 0 → API 失败（cloudflare 拦截 / cookie 过期等）
        if let baseResp = json["base_resp"] as? [String: Any],
           let statusCode = (baseResp["status_code"] as? NSNumber)?.intValue,
           statusCode != 0
        {
            return nil
        }

        var windows: [QuotaWindow] = []

        // 1. current_package_name 作为顶层"主套餐"剩余（如果有数字）
        if let mainRemains = json["remains"] as? [Any],
           let numeric = mainRemains.compactMap({ $0 as? NSNumber }).first
        {
            let fraction = max(0, min(1, numeric.doubleValue / 1000.0))  // 经验值
            windows.append(QuotaWindow(
                title: json["current_package_name"] as? String ?? "Coding Plan",
                remainingFraction: fraction,
                refreshDescription: "Coding Plan 主套餐",
                periodSeconds: 30 * 86400  // 月度
            ))
        }

        // 2. model_remains[] 每个 model 一个 QuotaWindow
        if let modelRemains = json["model_remains"] as? [[String: Any]] {
            for entry in modelRemains {
                guard let name = entry["model_name"] as? String,
                      let remains = (entry["remains"] as? NSNumber)?.doubleValue
                else { continue }
                // 经验阈值：每 model 单月可用 1000 次，超过 1.0 上限按 1.0 显示
                let fraction = max(0, min(1, remains / 1000.0))
                windows.append(QuotaWindow(
                    title: name,
                    remainingFraction: fraction,
                    refreshDescription: "Coding Plan",
                    periodSeconds: 30 * 86400
                ))
            }
        }

        return windows.isEmpty ? nil : windows
    }
}
