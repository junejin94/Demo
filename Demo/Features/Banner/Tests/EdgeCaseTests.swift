import CorePresentation
import CoreSwift
import Foundation

@MainActor
/// Tests focused on edge cases and boundary conditions (e.g. empty content).
enum EdgeCaseTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "edge",
            name: "Edge Cases",
            tests: [
                EmptyContentTest(service: service),
                DismissCurrentWhenNoneTest(service: service),
                ClearEmptyQueueTest(service: service),
                SamePriorityOrderTest(service: service),
                ShowDuplicateIDWhileActiveTest(service: service)
            ]
        )
    }
}

@MainActor
struct EmptyContentTest: TestCase {
    let id = "edge.empty"
    let name = "Empty title and message"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(title: "", message: nil, style: .info)
        service.show(config)
        
        try await Task.sleep(for: .milliseconds(100))
        
        // Should still show (empty is valid)
        guard service.currentBanner != nil else {
            return .failed(reason: "Empty banner not displayed")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies that dismissCurrent() when no banner is shown doesn't crash.
struct DismissCurrentWhenNoneTest: TestCase {
    let id = "edge.dismiss_none"
    let name = "Dismiss current with no banner"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Ensure no banner is active
        guard service.currentBanner == nil else {
            return .failed(reason: "Setup failed: banner still present")
        }
        
        // Should not crash
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(100))
        
        // Should still be nil
        guard service.currentBanner == nil else {
            return .failed(reason: "Unexpected banner appeared")
        }
        
        return .passed
    }
}

@MainActor
/// Verifies that clearQueue() when queue is empty doesn't crash.
struct ClearEmptyQueueTest: TestCase {
    let id = "edge.clear_empty"
    let name = "Clear already-empty queue"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let pendingBefore = await service.pendingQueue
        guard pendingBefore.isEmpty else {
            return .failed(reason: "Setup failed: queue not empty")
        }
        
        // Should not crash
        service.clearQueue()
        try await Task.sleep(for: .milliseconds(50))
        
        let pendingAfter = await service.pendingQueue
        guard pendingAfter.isEmpty else {
            return .failed(reason: "Queue not empty after clear")
        }
        
        return .passed
    }
}

@MainActor
/// Verifies FIFO ordering for banners with identical priority.
struct SamePriorityOrderTest: TestCase {
    let id = "edge.same_priority_fifo"
    let name = "FIFO order for same priority"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Show multiple banners with same priority
        service.info("First", priority: .medium)
        try await Task.sleep(for: .milliseconds(20))
        service.info("Second", priority: .medium)
        try await Task.sleep(for: .milliseconds(20))
        service.info("Third", priority: .medium)
        try await Task.sleep(for: .milliseconds(50))
        
        // First should be active
        guard service.currentBanner?.title == "First" else {
            return .failed(reason: "First banner not active")
        }
        
        // Dismiss and verify FIFO
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(500))
        
        guard service.currentBanner?.title == "Second" else {
            return .failed(reason: "Second did not follow First (FIFO violated). Current: \(service.currentBanner?.title ?? "nil")")
        }
        
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(500))
        
        guard service.currentBanner?.title == "Third" else {
            return .failed(reason: "Third did not follow Second (FIFO violated). Current: \(service.currentBanner?.title ?? "nil")")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies behavior when showing same ID while active with allowDuplicate: false.
struct ShowDuplicateIDWhileActiveTest: TestCase {
    let id = "edge.duplicate_id_active"
    let name = "Show same ID while active (no duplicate)"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let sharedId = UUID()
        let config = DefaultBannerConfiguration(
            id: sharedId,
            title: "Original",
            style: .info,
            priority: .medium,
            allowDuplicate: false
        )
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner?.id == sharedId else {
            return .failed(reason: "Original not shown")
        }
        
        // Try to show again with same ID
        service.show(config)
        try await Task.sleep(for: .milliseconds(50))
        
        // Should not be queued since it's already active
        let pending = await service.pendingQueue
        guard pending.isEmpty else {
            return .failed(reason: "Duplicate was queued despite being active")
        }
        
        service.dismissAll()
        return .passed
    }
}
