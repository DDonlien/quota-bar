import Foundation
import Testing
@testable import QuotaBar

@Suite("OpenCodeAuthProvider")
struct OpenCodeAuthProviderTests {
    @Test("parses provider ids from a multi-provider auth.json")
    func parsesConfiguredProviderIDs() throws {
        let json = """
        {
          "anthropic": { "type": "oauth", "access": "sk-ant-xxx", "refresh": "r" },
          "opencode-go": { "type": "api", "key": "ocg-xxx" },
          "empty-provider": { "type": "api" }
        }
        """

        let ids = try #require(OpenCodeAuthProvider.parseConfiguredProviderIDs(data: Data(json.utf8)))
        #expect(ids == ["anthropic", "opencode-go"])
    }

    @Test("tier summary prefers Go, then Zen, then generic BYOK")
    func tierSummaryPriority() {
        #expect(OpenCodeAuthProvider.tierSummary(providerIDs: ["opencode-go", "opencode", "anthropic"]) == "Go")
        #expect(OpenCodeAuthProvider.tierSummary(providerIDs: ["opencode", "anthropic"]) == "Zen")
        #expect(OpenCodeAuthProvider.tierSummary(providerIDs: ["anthropic", "openai"]) == "BYOK")
    }

    @Test("fetchSnapshot returns available with empty quotas when a credential file has configured providers")
    func fetchSnapshotAvailableWithConfiguredProvider() async throws {
        let tempFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("opencode-auth-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempFile) }
        try #"{"anthropic": {"type": "oauth", "access": "sk-ant-xxx"}}"#
            .write(to: tempFile, atomically: true, encoding: .utf8)

        let provider = OpenCodeAuthProvider(authPaths: [tempFile.path])
        let snapshot = try await provider.fetchSnapshot(timeout: 5)

        #expect(snapshot.availability == .available)
        #expect(snapshot.quotas.isEmpty)
        #expect(snapshot.subscriptionTier == "BYOK")
    }

    @Test("fetchSnapshot throws missingCredentials when no auth file and no manual key exist")
    func fetchSnapshotMissingCredentials() async {
        let provider = OpenCodeAuthProvider(
            authPaths: ["/tmp/quota-bar-nonexistent-opencode-auth.json"],
            manualKeyConfigPath: "/tmp/quota-bar-nonexistent-opencode-api-key.json"
        )

        await #expect(throws: QuotaFetchError.self) {
            _ = try await provider.fetchSnapshot(timeout: 5)
        }
    }

    @Test("fetchSnapshot falls back to a manually saved key as BYOK when auth.json is missing")
    func fetchSnapshotFallsBackToManualKey() async throws {
        let tempKeyFile = FileManager.default.temporaryDirectory
            .appendingPathComponent("opencode-api-key-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempKeyFile) }
        try OpenCodeManualKeyStore.save(apiKey: "oc-manual-test-key", configPath: tempKeyFile.path)

        let provider = OpenCodeAuthProvider(
            authPaths: ["/tmp/quota-bar-nonexistent-opencode-auth.json"],
            manualKeyConfigPath: tempKeyFile.path
        )
        let snapshot = try await provider.fetchSnapshot(timeout: 5)

        #expect(snapshot.availability == .available)
        #expect(snapshot.quotas.isEmpty)
        #expect(snapshot.subscriptionTier == "BYOK")
    }
}

@Suite("OpenCodeManualKeyStore")
struct OpenCodeManualKeyStoreTests {
    private static func tempPath() -> String {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("opencode-api-key-\(UUID().uuidString).json")
            .path
    }

    @Test("missing by default")
    func missingByDefault() {
        #expect(OpenCodeManualKeyStore.currentKeyState(configPath: Self.tempPath()) == .missing)
    }

    @Test("save and read round-trips with a masked display value")
    func saveAndReadRoundTrips() throws {
        let path = Self.tempPath()
        defer { try? FileManager.default.removeItem(atPath: path) }

        try OpenCodeManualKeyStore.save(apiKey: "oc-1234567890", configPath: path)

        #expect(OpenCodeManualKeyStore.readAPIKey(configPath: path) == "oc-1234567890")
        #expect(OpenCodeManualKeyStore.currentKeyState(configPath: path) == .configured(masked: "oc-12345···7890"))
    }

    @Test("rejects an empty key")
    func rejectsEmptyKey() {
        #expect(throws: OpenCodeManualKeyStore.PersistError.self) {
            try OpenCodeManualKeyStore.save(apiKey: "   ", configPath: Self.tempPath())
        }
    }
}
