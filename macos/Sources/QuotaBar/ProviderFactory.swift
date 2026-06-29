import Foundation
import SweetCookieKit

/// Provider 工厂：根据可用数据源创建 Provider 列表。
///
/// 对外仍返回 `[QuotaProvider]`，内部使用 CodexBar 风格的 pipeline：
/// 同一服务的多个数据源串行 fallback。Codex OAuth 成功后不会再碰浏览器
/// Cookie，也就不会误触发 Full Disk Access 引导。
enum ProviderFactory {
    @MainActor
    static func createProviders() -> [QuotaProvider] {
        let cookieReader = FilesystemCookieReader()
        return ProviderPipelines.makePipelines(cookieReader: cookieReader).map { pipeline in
            PipelineQuotaProvider(id: "\(pipeline.providerKind.rawValue)-pipeline", pipeline: pipeline)
        }
    }

    @MainActor
    static func createInstallDetectors() -> [ProviderKind: InstallDetectorProvider] {
        ProviderPipelines.makeInstallDetectors()
    }
}
