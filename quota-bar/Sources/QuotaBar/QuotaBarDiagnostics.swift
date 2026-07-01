import Foundation

enum QuotaBarDiagnostics {
    private static let queue = DispatchQueue(label: "quota-bar.diagnostics")

    static var logURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("Logs", isDirectory: true)
            .appendingPathComponent("QuotaBar.log")
    }

    static func write(_ message: String) {
        NSLog("QuotaBar: \(message)")
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let line = "\(timestamp) \(message)\n"
        queue.async {
            let url = logURL
            do {
                try FileManager.default.createDirectory(
                    at: url.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                if FileManager.default.fileExists(atPath: url.path),
                   let handle = try? FileHandle(forWritingTo: url) {
                    try handle.seekToEnd()
                    if let data = line.data(using: .utf8) {
                        try handle.write(contentsOf: data)
                    }
                    try handle.close()
                } else {
                    try line.write(to: url, atomically: true, encoding: .utf8)
                }
            } catch {
                NSLog("QuotaBar: diagnostics write failed: \(error.localizedDescription)")
            }
        }
    }
}
