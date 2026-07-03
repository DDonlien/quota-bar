import Foundation

enum QuotaBarDataDirectory {
    static func defaultURL(fileManager: FileManager = .default) -> URL {
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            return appSupport.appendingPathComponent("QuotaBar", isDirectory: true)
        }
        return URL(fileURLWithPath: NSHomeDirectory())
            .appendingPathComponent("Library/Application Support/QuotaBar", isDirectory: true)
    }

    static func ensureExists(_ url: URL, fileManager: FileManager = .default) throws {
        try fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        try? fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: url.path)
    }
}

enum ProviderFetchLayer: String, Codable, CaseIterable, Hashable, Sendable {
    case provider
    case quota
    case expiration
    case plan
}

enum ProviderSourceKind: String, Codable, Hashable, Sendable {
    case appBundle
    case configFile
    case cli
    case api
    case rpc
    case browserCookie
    case keychain
    case localLog
    case environment
    case unknown
}

struct ProviderSourceRecord: Codable, Hashable, Sendable {
    let providerKind: ProviderKind
    let layer: ProviderFetchLayer
    var sourceKind: ProviderSourceKind
    let sourceId: String
    var succeededAt: Date?
    var failureCount: Int
    var lastFailedAt: Date?
    var lastErrorSummary: String?
    var metadata: [String: String]
}

@MainActor
final class ProviderSourceIndexStore {
    static let shared = ProviderSourceIndexStore()

    private struct Payload: Codable {
        var schemaVersion: Int
        var records: [ProviderSourceRecord]
    }

    private let fileURL: URL
    private var records: [ProviderSourceRecord] = []
    private let schemaVersion = 1

    init(directoryURL: URL = QuotaBarDataDirectory.defaultURL()) {
        self.fileURL = directoryURL.appendingPathComponent("provider-sources.json")
        load()
    }

    func preferredSourceID(for kind: ProviderKind, layer: ProviderFetchLayer) -> String? {
        preferredSource(for: kind, layer: layer)?.sourceId
    }

    func preferredSource(for kind: ProviderKind, layer: ProviderFetchLayer) -> ProviderSourceRecord? {
        records
            .filter { $0.providerKind == kind && $0.layer == layer && $0.succeededAt != nil }
            .sorted {
                ($0.succeededAt ?? .distantPast) > ($1.succeededAt ?? .distantPast)
            }
            .first
    }

    func recordSuccess(
        kind: ProviderKind,
        layer: ProviderFetchLayer,
        sourceKind: ProviderSourceKind,
        sourceId: String,
        metadata: [String: String] = [:],
        at date: Date = Date()
    ) {
        let index = indexOf(kind: kind, layer: layer, sourceId: sourceId)
        if let index {
            records[index].sourceKind = sourceKind
            records[index].succeededAt = date
            records[index].failureCount = 0
            records[index].lastErrorSummary = nil
            records[index].metadata = sanitized(metadata)
        } else {
            records.append(ProviderSourceRecord(
                providerKind: kind,
                layer: layer,
                sourceKind: sourceKind,
                sourceId: sourceId,
                succeededAt: date,
                failureCount: 0,
                lastFailedAt: nil,
                lastErrorSummary: nil,
                metadata: sanitized(metadata)
            ))
        }
        save()
    }

    func recordFailure(
        kind: ProviderKind,
        layer: ProviderFetchLayer,
        sourceKind: ProviderSourceKind,
        sourceId: String,
        error: String,
        metadata: [String: String] = [:],
        at date: Date = Date()
    ) {
        let index = indexOf(kind: kind, layer: layer, sourceId: sourceId)
        if let index {
            records[index].sourceKind = sourceKind
            records[index].failureCount += 1
            records[index].lastFailedAt = date
            records[index].lastErrorSummary = String(error.prefix(240))
            records[index].metadata = sanitized(metadata)
        } else {
            records.append(ProviderSourceRecord(
                providerKind: kind,
                layer: layer,
                sourceKind: sourceKind,
                sourceId: sourceId,
                succeededAt: nil,
                failureCount: 1,
                lastFailedAt: date,
                lastErrorSummary: String(error.prefix(240)),
                metadata: sanitized(metadata)
            ))
        }
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder.quotaBar.decode(Payload.self, from: data),
              payload.schemaVersion == schemaVersion else {
            records = []
            return
        }
        records = payload.records
    }

    private func save() {
        do {
            try QuotaBarDataDirectory.ensureExists(fileURL.deletingLastPathComponent())
            let payload = Payload(schemaVersion: schemaVersion, records: records)
            let data = try JSONEncoder.quotaBar.encode(payload)
            try data.write(to: fileURL, options: [.atomic])
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            NSLog("QuotaBar: failed to save provider source index: \(error)")
        }
    }

    private func indexOf(kind: ProviderKind, layer: ProviderFetchLayer, sourceId: String) -> Int? {
        records.firstIndex {
            $0.providerKind == kind && $0.layer == layer && $0.sourceId == sourceId
        }
    }

    private func sanitized(_ metadata: [String: String]) -> [String: String] {
        metadata.filter { key, value in
            let lowered = key.lowercased()
            guard !lowered.contains("token"),
                  !lowered.contains("cookie"),
                  !lowered.contains("secret"),
                  !lowered.contains("key"),
                  !lowered.contains("authorization") else {
                return false
            }
            return !value.isEmpty && value.count <= 500
        }
    }
}

@MainActor
final class ProviderSnapshotCacheStore {
    static let shared = ProviderSnapshotCacheStore()

    private struct Payload: Codable {
        var schemaVersion: Int
        var records: [ProviderSnapshotRecord]
    }

    private struct ProviderSnapshotRecord: Codable {
        var id: UUID
        var kind: ProviderKind
        var subscriptionTier: String?
        var availability: AvailabilityRecord
        var quotas: [QuotaWindowRecord]
        var monthlyPrice: String?
        var subscriptionExpiresAt: Date?
        var subscriptionExpiresAtSource: SubscriptionExpirySourceKind?
        var subscriptionExpiresAtConfidence: SubscriptionExpiryConfidence?
        var fetchedAt: Date
        var sourceKind: ProviderSourceKind?
        var sourceId: String?

        init(snapshot: ProviderSnapshot, sourceKind: ProviderSourceKind?, sourceId: String?) {
            self.id = snapshot.id
            self.kind = snapshot.kind
            self.subscriptionTier = snapshot.subscriptionTier
            self.availability = AvailabilityRecord(snapshot.availability)
            self.quotas = snapshot.quotas.map(QuotaWindowRecord.init)
            self.monthlyPrice = snapshot.monthlyPrice
            self.subscriptionExpiresAt = snapshot.subscriptionExpiresAt
            self.subscriptionExpiresAtSource = snapshot.subscriptionExpiresAtSource
            self.subscriptionExpiresAtConfidence = snapshot.subscriptionExpiresAtConfidence
            self.fetchedAt = snapshot.fetchedAt
            self.sourceKind = sourceKind
            self.sourceId = sourceId
        }

        func snapshot() -> ProviderSnapshot {
            ProviderSnapshot(
                id: id,
                kind: kind,
                subscriptionTier: subscriptionTier,
                availability: availability.availability,
                quotas: quotas.map { $0.quotaWindow() },
                monthlyPrice: monthlyPrice,
                subscriptionExpiresAt: subscriptionExpiresAt,
                subscriptionExpiresAtSource: subscriptionExpiresAtSource,
                subscriptionExpiresAtConfidence: subscriptionExpiresAtConfidence,
                fetchedAt: fetchedAt,
                isStale: true
            )
        }
    }

    private struct AvailabilityRecord: Codable {
        var status: String
        var reason: String?
        var plan: String?
        var expiredAt: Date?

        init(_ availability: ProviderAvailability) {
            switch availability {
            case .available:
                status = "available"
                reason = nil
                plan = nil
                expiredAt = nil
            case .subscriptionExpired(let plan, let expiredAt):
                status = "subscriptionExpired"
                reason = nil
                self.plan = plan
                self.expiredAt = expiredAt
            case .notSubscribed(let reason):
                status = "notSubscribed"
                self.reason = reason
                plan = nil
                expiredAt = nil
            case .needsConfiguration(let reason):
                status = "needsConfiguration"
                self.reason = reason
                plan = nil
                expiredAt = nil
            case .loading:
                status = "loading"
                reason = nil
                plan = nil
                expiredAt = nil
            case .notInstalled:
                status = "notInstalled"
                reason = nil
                plan = nil
                expiredAt = nil
            case .fetchFailed(let reason):
                status = "fetchFailed"
                self.reason = reason
                plan = nil
                expiredAt = nil
            }
        }

        var availability: ProviderAvailability {
            switch status {
            case "available":
                return .available
            case "subscriptionExpired":
                return .subscriptionExpired(plan: plan, expiredAt: expiredAt)
            case "notSubscribed":
                return .notSubscribed(reason: reason ?? "未订阅")
            case "needsConfiguration":
                return .needsConfiguration(reason: reason ?? "待配置")
            case "notInstalled":
                return .notInstalled
            case "fetchFailed":
                return .fetchFailed(reason: reason ?? "获取失败")
            case "loading":
                return .loading
            default:
                return .fetchFailed(reason: "缓存状态不可识别")
            }
        }
    }

    private struct QuotaWindowRecord: Codable {
        var id: UUID
        var title: String
        var remainingFraction: Double
        var refreshDescription: String
        var resetsAt: Date?
        var periodSeconds: TimeInterval?
        var scope: String?
        var subscriptionGroup: String?

        init(_ quota: QuotaWindow) {
            id = quota.id
            title = quota.title
            remainingFraction = quota.remainingFraction
            refreshDescription = quota.refreshDescription
            resetsAt = quota.resetsAt
            periodSeconds = quota.periodSeconds
            scope = quota.scope
            subscriptionGroup = quota.subscriptionGroup
        }

        func quotaWindow() -> QuotaWindow {
            QuotaWindow(
                id: id,
                title: title,
                remainingFraction: remainingFraction,
                refreshDescription: refreshDescription,
                resetsAt: resetsAt,
                periodSeconds: periodSeconds,
                scope: scope,
                subscriptionGroup: subscriptionGroup
            )
        }
    }

    private let fileURL: URL
    private let schemaVersion = 1
    private var records: [ProviderKind: ProviderSnapshotRecord] = [:]

    init(directoryURL: URL = QuotaBarDataDirectory.defaultURL()) {
        self.fileURL = directoryURL.appendingPathComponent("snapshots.json")
        load()
    }

    func loadAll() -> [ProviderSnapshot] {
        records.values.map { $0.snapshot() }
    }

    func snapshot(for kind: ProviderKind) -> ProviderSnapshot? {
        records[kind]?.snapshot()
    }

    func store(_ snapshot: ProviderSnapshot, sourceKind: ProviderSourceKind? = nil, sourceId: String? = nil) {
        guard isWriteEligible(snapshot) else {
            remove(kind: snapshot.kind)
            return
        }
        records[snapshot.kind] = ProviderSnapshotRecord(
            snapshot: snapshot.withStaleFlag(false),
            sourceKind: sourceKind,
            sourceId: sourceId
        )
        save()
    }

    func remove(kind: ProviderKind) {
        guard records.removeValue(forKey: kind) != nil else { return }
        save()
    }

    private func isWriteEligible(_ snapshot: ProviderSnapshot) -> Bool {
        switch snapshot.availability {
        case .available:
            return !snapshot.quotas.isEmpty
        case .subscriptionExpired, .notSubscribed:
            return true
        case .loading, .needsConfiguration, .notInstalled, .fetchFailed:
            return false
        }
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL),
              let payload = try? JSONDecoder.quotaBar.decode(Payload.self, from: data),
              payload.schemaVersion == schemaVersion else {
            records = [:]
            return
        }
        records = Dictionary(uniqueKeysWithValues: payload.records
            .filter { !Self.isDeprecatedCacheRecord($0) }
            .map { ($0.kind, $0) })
    }

    private func save() {
        do {
            try QuotaBarDataDirectory.ensureExists(fileURL.deletingLastPathComponent())
            let payload = Payload(
                schemaVersion: schemaVersion,
                records: records.values.sorted { $0.kind.rawValue < $1.kind.rawValue }
            )
            let data = try JSONEncoder.quotaBar.encode(payload)
            try data.write(to: fileURL, options: [.atomic])
            try? FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
        } catch {
            NSLog("QuotaBar: failed to save provider snapshot cache: \(error)")
        }
    }

    private static func isDeprecatedCacheRecord(_ record: ProviderSnapshotRecord) -> Bool {
        guard record.kind == .codex else { return false }
        return record.sourceKind == .localLog || record.sourceId == "codex-cli"
    }
}

private extension JSONEncoder {
    static var quotaBar: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}

private extension JSONDecoder {
    static var quotaBar: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
