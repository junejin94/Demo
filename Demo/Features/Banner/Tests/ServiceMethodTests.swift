import Foundation
import CorePresentation

@MainActor
/// Tests focused on Banner.Service method APIs (dismiss by ID, remove from queue).
enum ServiceMethodTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "service_methods",
            name: "Service Method Tests",
            tests: [
                DismissByIdTest(service: service),
                RemoveFromQueueTest(service: service),
                DismissByIdNotFoundTest(service: service),
                RemoveFromQueueNotFoundTest(service: service)
            ]
        )
    }
}

@MainActor
/// Verifies that dismiss(id:) removes the currently active banner.
struct DismissByIdTest: TestCase {
    let id = "service.dismiss_by_id"
    let name = "Dismiss banner by UUID"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let bannerId = UUID()
        let config = DefaultBannerConfiguration(
            id: bannerId,
            title: "Target Banner",
            style: .info,
            priority: .medium
        )
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner?.id == bannerId else {
            return .failed(reason: "Banner not shown with correct ID")
        }
        
        // Dismiss by ID
        service.dismiss(id: bannerId)
        try await Task.sleep(for: .milliseconds(300))
        
        guard service.currentBanner == nil else {
            return .failed(reason: "Banner not dismissed by ID")
        }
        
        return .passed
    }
}

@MainActor
/// Verifies that removeFromQueue(id:) removes a queued banner without affecting current.
struct RemoveFromQueueTest: TestCase {
    let id = "service.remove_from_queue"
    let name = "Remove specific banner from queue"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let firstId = UUID()
        let targetId = UUID()
        let thirdId = UUID()
        
        // Show three banners
        service.show(DefaultBannerConfiguration(id: firstId, title: "First", style: .info))
        service.show(DefaultBannerConfiguration(id: targetId, title: "Target", style: .info))
        service.show(DefaultBannerConfiguration(id: thirdId, title: "Third", style: .info))
        
        try await Task.sleep(for: .milliseconds(100))
        
        // Verify queue setup
        let pendingBefore = await service.pendingQueue
        guard pendingBefore.count == 2 else {
            return .failed(reason: "Setup failed: expected 2 queued, got \(pendingBefore.count)")
        }
        
        // Remove target from queue
        service.removeFromQueue(id: targetId)
        try await Task.sleep(for: .milliseconds(50))
        
        let pendingAfter = await service.pendingQueue
        
        // Queue should now have 1 item
        guard pendingAfter.count == 1 else {
            return .failed(reason: "Expected 1 in queue, got \(pendingAfter.count)")
        }
        
        // Target should be removed
        let hasTarget = pendingAfter.contains { $0.id == targetId }
        guard !hasTarget else {
            return .failed(reason: "Target banner still in queue")
        }
        
        // Third should still be there
        let hasThird = pendingAfter.contains { $0.id == thirdId }
        guard hasThird else {
            return .failed(reason: "Third banner missing from queue")
        }
        
        // Current banner should be unchanged
        guard service.currentBanner?.id == firstId else {
            return .failed(reason: "Current banner changed unexpectedly")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies that dismiss(id:) handles non-existent IDs gracefully.
struct DismissByIdNotFoundTest: TestCase {
    let id = "service.dismiss_by_id.not_found"
    let name = "Dismiss non-existent ID (no-op)"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        service.info("Active", priority: .medium)
        try await Task.sleep(for: .milliseconds(50))
        
        let nonExistentId = UUID()
        
        // Should not crash or affect current banner
        service.dismiss(id: nonExistentId)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner?.title == "Active" else {
            return .failed(reason: "Current banner affected by invalid dismiss")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies that removeFromQueue(id:) handles non-existent IDs gracefully.
struct RemoveFromQueueNotFoundTest: TestCase {
    let id = "service.remove_from_queue.not_found"
    let name = "Remove non-existent ID from queue (no-op)"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        service.info("First", priority: .medium)
        service.info("Second", priority: .medium)
        try await Task.sleep(for: .milliseconds(50))
        
        let pendingBefore = await service.pendingQueue
        let countBefore = pendingBefore.count
        
        let nonExistentId = UUID()
        
        // Should not crash or affect queue
        service.removeFromQueue(id: nonExistentId)
        try await Task.sleep(for: .milliseconds(50))
        
        let pendingAfter = await service.pendingQueue
        guard pendingAfter.count == countBefore else {
            return .failed(reason: "Queue count changed unexpectedly")
        }
        
        service.dismissAll()
        return .passed
    }
}
