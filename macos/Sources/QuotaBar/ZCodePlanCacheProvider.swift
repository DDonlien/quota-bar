import Foundation

/// Z Code 本地 coding plan 状态缓存。
///
/// Z Code 桌面端会维护 `~/.zcode/v2/coding-plan-cache.json`，其中记录 builtin
/// plan 的可用性。这个文件不包含可渲染 quota 数值，因此本 provider 不伪造额度；
/// 只在真实 quota API 失败后提供明确状态说明，避免 UI 只显示「App 已装」。
final class ZCodePlanCacheProvider: QuotaProvider, @unchecked Sendable {
    let id = "zcode-plan-cache"
    let kind: ProviderKind = .zcode
    var displayName: String { kind.displayName }

    private let cachePath: String
    private let dateProvider: () -> Date

    init(
        cachePath: String? = nil,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.cachePath = cachePath ?? NSHomeDirectory() + "/.zcode/v2/coding-plan-cache.json"
        self.dateProvider = dateProvider
    }

    func fetchSnapshot(timeout: TimeInterval) async throws -> ProviderSnapshot {
        let status = try readStatus()
        let activePlan = status.availablePlans.first
        let tier = activePlan.flatMap { ProviderPricing.normalizedTier($0) }
        let reason = status.userFacingReason

        return ProviderSnapshot(
            kind: .zcode,
            subscriptionTier: tier,
            availability: .needsConfiguration(reason: reason),
            quotas: [],
            monthlyPrice: nil,
            fetchedAt: dateProvider()
        )
    }

    private struct PlanStatus {
        let availablePlans: [String]
        let unavailableReasons: [String: String]

        var userFacingReason: String {
            if let plan = availablePlans.first {
                let unavailable = unavailableReasons
                    .sorted { $0.key < $1.key }
                    .map { "\($0.key): \($0.value)" }
                    .joined(separator: "；")
                if unavailable.isEmpty {
                    return "\(Self.displayName(for: plan)) 可用，但本地缓存没有额度数值"
                }
                return "\(Self.displayName(for: plan)) 可用，但未返回额度数值；\(unavailable)"
            }
            if unavailableReasons.isEmpty {
                return "未找到可用 Z Code plan"
            }
            return unavailableReasons
                .sorted { $0.key < $1.key }
                .map { "\(Self.displayName(for: $0.key)): \($0.value)" }
                .joined(separator: "；")
        }

        private static func displayName(for plan: String) -> String {
            ProviderPricing.normalizedTier(plan) ?? plan
        }
    }

    private func readStatus() throws -> PlanStatus {
        let url = URL(fileURLWithPath: cachePath)
        guard let data = try? Data(contentsOf: url),
              let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let entryStatus = root["entryStatus"] as? [String: Any],
              let items = entryStatus["items"] as? [String: Any] else {
            throw QuotaFetchError.sourceUnavailable(detail: "未找到 Z Code coding plan 缓存")
        }

        var availablePlans: [String] = []
        var unavailableReasons: [String: String] = [:]
        for (plan, raw) in items {
            guard let item = raw as? [String: Any],
                  let status = item["status"] as? String else {
                continue
            }
            switch status {
            case "available":
                availablePlans.append(plan)
            case "unavailable":
                unavailableReasons[plan] = (item["reason"] as? String) ?? "unavailable"
            default:
                unavailableReasons[plan] = status
            }
        }

        return PlanStatus(
            availablePlans: availablePlans.sorted(),
            unavailableReasons: unavailableReasons
        )
    }
}
