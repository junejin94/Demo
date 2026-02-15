import Foundation
import CorePresentation

@MainActor
/// Tests focused on queue overflow policies (dropping items when full).
enum OverflowTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "overflow",
            name: "Overflow Policy Tests",
            tests: [
                DropOldestTest(service: service),
                DropNewestPolicyTest(service: service),
                DropLowPriorityTest(service: service)
            ]
        )
    }
}

@MainActor
struct DropOldestTest: TestCase {
    let id = "overflow.oldest"
    let name = "Drop oldest when full"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        // Queue size is 5 (set in DemoApp)
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Show 1 active
        service.info("Active", priority: .medium)
        
        // Fill queue with 5 items (Q1-Q5)
        for i in 1...5 {
            service.info("Q\(i)", priority: .medium)
        }
        
        // Queue is now full [Q1...Q5]
        
        // Add one more (should drop Q1)
        service.info("Overflow", priority: .medium)
        
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify Q1 is gone from pending
        let pending = await service.pendingQueue
        let hasQ1 = pending.contains { $0.title == "Q1" }
        let hasOverflow = pending.contains { $0.title == "Overflow" }
        
        if !hasQ1 && hasOverflow {
            service.dismissAll()
            try? await Task.sleep(for: .milliseconds(500)) // Wait for cleanup
            return .passed
        } else {
            service.dismissAll()
            try? await Task.sleep(for: .milliseconds(500))
            return .failed(reason: "Oldest not dropped. Q1 present: \(hasQ1)")
        }
    }
}

@MainActor
/// Verifies that the .dropNewest overflow policy rejects new banners when queue is full.
struct DropNewestPolicyTest: TestCase {
    let id = "overflow.newest"
    let name = "Drop newest policy rejects overflow"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Create local service with .dropNewest policy
        let localService = DefaultBannerService(
            maxQueueSize: 3,
            overflowPolicy: .dropNewest
        )
        
        // Show 1 active banner
        localService.info("Active", priority: .medium)
        try await Task.sleep(for: .milliseconds(50))
        
        // Fill queue to capacity (3 items)
        localService.info("Q1", priority: .medium)
        localService.info("Q2", priority: .medium)
        localService.info("Q3", priority: .medium)
        try await Task.sleep(for: .milliseconds(50))
        
        var pending = await localService.pendingQueue
        guard pending.count == 3 else {
            return .failed(reason: "Setup failed: queue has \(pending.count) items, expected 3")
        }
        
        // Try to add one more (should be dropped as "newest")
        localService.info("Overflow", priority: .medium)
        try await Task.sleep(for: .milliseconds(50))
        
        pending = await localService.pendingQueue
        
        // Queue should still be 3 items
        guard pending.count == 3 else {
            return .failed(reason: "Queue size changed to \(pending.count), expected 3")
        }
        
        // "Overflow" should NOT be in queue
        let hasOverflow = pending.contains { $0.title == "Overflow" }
        guard !hasOverflow else {
            return .failed(reason: "Newest banner was added instead of dropped")
        }
        
        // Original queue items should still be there
        let titles = pending.map { $0.title ?? "" }
        let expectedTitles = ["Q1", "Q2", "Q3"]
        guard titles == expectedTitles else {
            return .failed(reason: "Queue contents: \(titles), expected \(expectedTitles)")
        }
        
        localService.dismissAll()
        return .passed
    }
}

@MainActor
struct DropLowPriorityTest: TestCase {
    let id = "overflow.priority"
    let name = "Drop lowest priority first"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        // Queue size is 5. Test that low priority is dropped first.
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        service.info("Active", priority: .high)
        
        // Fill queue with 4 High priority
        for i in 1...4 {
            service.info("High\(i)", priority: .high)
        }
        
        // Add one Low priority (should be in queue)
        service.info("Low1", priority: .low)
        
        // Queue: [High1...High4, Low1] (Size 5)
        
        // Add another High (should drop Low1)
        service.info("High5", priority: .high)
        
        try await Task.sleep(for: .milliseconds(100))
        
        let pending = await service.pendingQueue
        let hasLow = pending.contains { $0.title == "Low1" }
        
        if !hasLow {
            service.dismissAll()
            try? await Task.sleep(for: .milliseconds(500))
            return .passed
        } else {
            service.dismissAll()
            try? await Task.sleep(for: .milliseconds(500))
            return .failed(reason: "Low priority not dropped")
        }
    }
}
