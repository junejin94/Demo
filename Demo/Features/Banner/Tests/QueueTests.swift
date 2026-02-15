import CorePresentation
import CoreSwift
import Foundation

@MainActor
/// Tests focused on basic queue operations like clearing and ordering.
enum QueueTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "queue",
            name: "Queue Tests",
            tests: [
                OverflowTest(),
                ClearQueueTest(service: service)
            ]
        )
    }
}

@MainActor
struct OverflowTest: TestCase {
    let id = "queue.overflow"
    let name = "Queue overflow policy"
    
    func run() async throws -> TestResult {
        
        // Using local service for specific configuration (Max Size 3)
        // This test verifies LOGIC, not UI visibility
        let service = DefaultBannerService(maxQueueSize: 3, overflowPolicy: .dropOldest)
        
        // Show 1 active + queue 4 more (should drop oldest)
        for i in 1...5 {
            service.info("\(i)")
        }
        
        try await Task.sleep(for: .milliseconds(50))
        
        let pending = await service.pendingQueue
        guard pending.count == 3 else {
            return .failed(reason: "Queue size \(pending.count), expected 3")
        }
        
        // Oldest (2) should be dropped, queue should have 3,4,5
        // (1 is active, 2,3,4,5 queued -> max 3 -> drop 2 -> 3,4,5)
        guard pending.first?.title == "3" else {
            return .failed(reason: "Overflow policy not applied")
        }
        
        return .passed
    }
}

@MainActor
struct ClearQueueTest: TestCase {
    let id = "queue.clear"
    let name = "Clear queue operation"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        service.info("1", priority: .medium)
        service.info("2", priority: .medium)
        service.info("3", priority: .medium)
        
        try await Task.sleep(for: .milliseconds(50))
        
        service.clearQueue()
        try await Task.sleep(for: .milliseconds(50))
        
        let pending = await service.pendingQueue
        guard pending.isEmpty else {
            return .failed(reason: "Queue not empty")
        }
        
        service.dismissAll()
        return .passed
    }
}
