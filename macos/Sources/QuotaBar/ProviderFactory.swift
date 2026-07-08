import Foundation

/// Provider 工厂：根据可用数据源创建 Provider 列表。
///
/// 对外仍返回 `[QuotaProvider]`，内部使用 CodexBar 风格的 pipeline：
/// 同一服务的多个数据源串行 fallback。
enum ProviderFactory {
    @MainActor
    static func createProviders() -> [QuotaProvider] {
        ProviderPipelines.makePipelines().map { pipeline in
            PipelineQuotaProvider(id: "\(pipeline.providerKind.rawValue)-pipeline", pipeline: pipeline)
        }
    }

    @MainActor
    static func createInstallDetectors() -> [ProviderKind: InstallDetectorProvider] {
        ProviderPipelines.makeInstallDetectors()
    }
}
