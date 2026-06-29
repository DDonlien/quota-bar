import Foundation
import SwiftUI

@MainActor
final class AgentStore: ObservableObject {
    static let shared = AgentStore()

    @Published var detectionResult: DetectionResult?
    @Published var isDetecting: Bool = false
    @Published var lastError: String?

    func detect() async {
        isDetecting = true
        lastError = nil
        defer { isDetecting = false }

        let result = await AgentDetector.detectAll()
        self.detectionResult = result
    }
}
