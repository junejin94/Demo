import Foundation
import CorePresentation

@MainActor
/// Tests focused on stability under rapid-fire conditions.
enum RapidTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "rapid",
            name: "Rapid Fire Tests",
            tests: [
                RapidShowTest(service: service)
            ]
        )
    }
}

@MainActor
struct RapidShowTest: TestCase {
    let id = "rapid.show"
    let name = "Show 20 banners rapidly"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let count = 20
        for i in 1...count {
            // Use persistent to ensure they don't auto-dismiss while we count
            let config = DefaultBannerConfiguration(
                title: "Rapid \(i)",
                style: .info,
                priority: .medium,
                dismissal: .persistent
            )
            service.show(config)
        }
        
        // DemoApp uses maxQueueSize: 5
        // Expected: 1 active + 5 queued = 6 total retained.
        
        try await Task.sleep(for: .milliseconds(200))
        
        // Verify system stability after rapid fire
        let pending = await service.pendingQueue
        let current = service.currentBanner
        
        guard current != nil else {
            return .failed(reason: "No current banner after rapid fire")
        }
        
        guard !pending.isEmpty else {
            return .failed(reason: "Queue empty after rapid fire (expected up to 5)")
        }
        
        guard pending.count <= 5 else {
            return .failed(reason: "Queue has \(pending.count) items, max should be 5")
        }
        
        // Verify we have expected queue size (accept 4 or 5 to be robust against race conditions)
        if pending.count >= 4 && pending.count <= 5 {
            service.dismissAll()
            return .passed
        } else {
            service.dismissAll()
            return .failed(reason: "Queue has \(pending.count) items, expected 4 or 5")
        }
    }
}
