import CorePresentation
import CoreSwift
import Foundation


@MainActor
/// Tests focused on the interaction between multiple components or complex flows.
enum IntegrationTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "integration",
            name: "Integration Tests",
            tests: [
                ShowBannerTest(service: service),
                DismissCurrentTest(service: service),
                AutoDismissTimingTest(service: service),
                QueueOrderTest(service: service),
                PreemptionIntegrationTest(service: service),
                ClearQueueIntegrationTest(service: service)
            ]
        )
    }
}

// MARK: - Tests

@MainActor
struct ShowBannerTest: TestCase {
    let id = "integration.show"
    let name = "Show banner sets current"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        service.info("Test Banner", priority: .medium)
        
        // Allow async update propogation
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner?.title == "Test Banner" else {
            return .failed(reason: "currentBanner not set")
        }
        return .passed
    }
}

@MainActor
struct DismissCurrentTest: TestCase {
    let id = "integration.dismiss"
    let name = "Dismiss current clears banner"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        service.info("Dismiss Me", priority: .medium)
        
        // Wait for show
        try await Task.sleep(for: .milliseconds(100))
        guard service.currentBanner != nil else { return .failed(reason: "Setup failed") }
        
        service.dismissCurrent()
        
        // Wait for animation/dismiss
        try await Task.sleep(for: .milliseconds(500))
        
        guard service.currentBanner == nil else {
            return .failed(reason: "Banner not dismissed")
        }
        return .passed
    }
}

@MainActor
struct AutoDismissTimingTest: TestCase {
    let id = "integration.autodismiss"
    let name = "Auto-dismiss timing"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(
            title: "Auto Dismiss",
            style: .info,
            dismissal: .auto(duration: 0.5)
        )
        service.show(config)
        
        // Check it's shown
        try await Task.sleep(for: .milliseconds(100))
        guard service.currentBanner != nil else { return .failed(reason: "Setup failed") }
        
        // Wait for auto-dismiss (0.5s + buffer)
        try await Task.sleep(for: .milliseconds(600))
        
        guard service.currentBanner == nil else {
            return .failed(reason: "Banner did not auto-dismiss")
        }
        return .passed
    }
}

@MainActor
struct QueueOrderTest: TestCase {
    let id = "integration.queue"
    let name = "Queue FIFO order"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Show 1 (Active) - wait for it to become current
        service.info("1", priority: .medium)
        try await Task.sleep(for: .milliseconds(50))
        
        // Queue 2 and 3 with small delays to ensure ordering
        service.info("2", priority: .medium)
        try await Task.sleep(for: .milliseconds(20))
        service.info("3", priority: .medium)
        
        try await Task.sleep(for: .milliseconds(50))
        guard service.currentBanner?.title == "1" else { return .failed(reason: "1 not shown") }
        
        // Dismiss 1 -> 2 should show
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(500))
        guard service.currentBanner?.title == "2" else { return .failed(reason: "2 not shown after 1 dismissed") }
        
        // Dismiss 2 -> 3 should show
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(500))
        guard service.currentBanner?.title == "3" else { return .failed(reason: "3 not shown after 2 dismissed") }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct PreemptionIntegrationTest: TestCase {
    let id = "integration.preempt"
    let name = "High priority preempts low"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Show Low Priority
        service.info("Low", message: nil, priority: .low, action: nil)
        try await Task.sleep(for: .milliseconds(50))
        guard service.currentBanner?.title == "Low" else { return .failed(reason: "Low setup failed") }
        
        // Show High Priority -> Should replace immediately
        service.error("High", message: nil, priority: .high, action: nil)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner?.title == "High" else {
            return .failed(reason: "High did not preempt Low")
        }
        
        // Dismiss High -> Low should return (it was re-queued)
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(400))
        
        guard service.currentBanner?.title == "Low" else {
            return .failed(reason: "Low did not return after preempt")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct ClearQueueIntegrationTest: TestCase {
    let id = "integration.clear"
    let name = "Clear queue empties pending"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Show 1, Queue 2, Queue 3
        service.info("1", priority: .medium)
        service.info("2", priority: .medium)
        service.info("3", priority: .medium)
        
        // Wait for queue to populate
        try await Task.sleep(for: .milliseconds(50))
        
        // Verify we have pending items
        let countBefore = await service.pendingQueue.count
        guard countBefore == 2 else {
            return .failed(reason: "Queue setup failed")
        }
        
        // Clear queue
        service.clearQueue()
        try await Task.sleep(for: .milliseconds(50))
        
        // Verify empty
        let countAfter = await service.pendingQueue.count
        guard countAfter == 0 else {
            return .failed(reason: "Queue not empty")
        }
        
        // Current banner should still be there
        guard service.currentBanner?.title == "1" else {
            return .failed(reason: "Current banner cleared incorrectly")
        }
        
        service.dismissAll()
        return .passed
    }
}
