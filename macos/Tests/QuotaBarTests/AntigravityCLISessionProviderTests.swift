import Foundation
import Testing
@testable import QuotaBar

/// Antigravity 真实 CLI 层：拉起临时 `agy` 会话、复用其本地 RPC 取额度。
/// 不依赖真实 agy 二进制/PTY——会话生命周期和 RPC 取数都通过注入替换。
@Suite("AntigravityCLISessionProvider")
struct AntigravityCLISessionProviderTests {

    @Test("reports sourceUnavailable when agy binary is missing")
    func missingBinaryReportsSourceUnavailable() async {
        let provider = AntigravityCLISessionProvider(
            executablePathCandidates: ["/nonexistent/agy"],
            innerFetcher: { _ in
                Issue.record("不应该在二进制缺失时尝试 innerFetcher")
                throw QuotaFetchError.sourceUnavailable(detail: "unreachable")
            },
            launchSession: { _ in
                Issue.record("不应该在二进制缺失时启动会话")
                throw QuotaFetchError.sourceUnavailable(detail: "unreachable")
            }
        )
        do {
            _ = try await provider.fetchSnapshot(timeout: 5)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .sourceUnavailable = error else {
                Issue.record("期望 sourceUnavailable，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }

    @Test("retries innerFetcher until RPC becomes ready, then returns its snapshot")
    func retriesUntilInnerFetcherSucceeds() async throws {
        let expectedSnapshot = ProviderSnapshot(
            kind: .antigravity,
            subscriptionTier: "Antigravity Starter Quota",
            availability: .available,
            quotas: [
                QuotaWindow(
                    title: "Claude Opus 4.6",
                    remainingFraction: 0.5,
                    refreshDescription: "重置时间未知",
                    subscriptionGroup: "Claude Opus 4.6"
                ),
            ],
            monthlyPrice: nil,
            fetchedAt: Date()
        )

        let attemptCount = Counter()
        let fakeSession = FakeManagedSession()
        let provider = AntigravityCLISessionProvider(
            executablePathCandidates: ["/bin/echo"],  // 真实存在即可，会话逻辑已被替换
            innerFetcher: { _ in
                let attempt = attemptCount.increment()
                if attempt < 3 {
                    throw QuotaFetchError.transient(detail: "RPC 尚未就绪")
                }
                return expectedSnapshot
            },
            launchSession: { _ in fakeSession },
            initialSettleDelay: 0,
            retryInterval: 0.01
        )

        let snapshot = try await provider.fetchSnapshot(timeout: 5)
        #expect(snapshot.subscriptionTier == "Antigravity Starter Quota")
        #expect(attemptCount.value == 3)
        #expect(fakeSession.terminateCallCount.value == 1, "无论成功失败都应该在 defer 里终止会话")
    }

    @Test("throws transient when session process exits early")
    func sessionExitsEarly() async {
        let session = FakeManagedSession()
        session.running.value = false  // 会话立即"已退出"

        let provider = AntigravityCLISessionProvider(
            executablePathCandidates: ["/bin/echo"],
            innerFetcher: { _ in
                Issue.record("会话已退出，不应该再尝试 innerFetcher")
                throw QuotaFetchError.sourceUnavailable(detail: "unreachable")
            },
            launchSession: { _ in session },
            initialSettleDelay: 0
        )

        do {
            _ = try await provider.fetchSnapshot(timeout: 5)
            Issue.record("应该抛错")
        } catch let error as QuotaFetchError {
            guard case .transient = error else {
                Issue.record("期望 transient，实际 \(error)")
                return
            }
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
        #expect(session.terminateCallCount.value == 1)
    }

    @Test("gives up after timeout when RPC never becomes ready")
    func timesOutWhenRPCNeverReady() async {
        let provider = AntigravityCLISessionProvider(
            executablePathCandidates: ["/bin/echo"],
            innerFetcher: { _ in
                throw QuotaFetchError.transient(detail: "RPC 尚未就绪")
            },
            launchSession: { _ in FakeManagedSession() },
            initialSettleDelay: 0,
            retryInterval: 0.05
        )

        do {
            _ = try await provider.fetchSnapshot(timeout: 0.3)
            Issue.record("应该超时抛错")
        } catch is QuotaFetchError {
            // 预期路径
        } catch {
            Issue.record("非 QuotaFetchError: \(error)")
        }
    }
}

// MARK: - 测试替身

private final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var _value = 0
    var value: Int { lock.withLock { _value } }
    func increment() -> Int {
        lock.withLock {
            _value += 1
            return _value
        }
    }
}

private final class AtomicBool: @unchecked Sendable {
    private let lock = NSLock()
    private var _value: Bool
    init(_ value: Bool) { self._value = value }
    var value: Bool {
        get { lock.withLock { _value } }
        set { lock.withLock { _value = newValue } }
    }
}

private final class FakeManagedSession: AntigravityCLISessionProvider.ManagedSession, @unchecked Sendable {
    let running = AtomicBool(true)
    let terminateCallCount = Counter()

    var isRunning: Bool { running.value }

    func terminate() {
        _ = terminateCallCount.increment()
    }
}

private extension NSLock {
    func withLock<T>(_ body: () -> T) -> T {
        lock()
        defer { unlock() }
        return body()
    }
}
