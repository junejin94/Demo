import CorePresentation
import CoreSwift
import Foundation

@MainActor
/// Tests focused on banner priority logic and preemption.
enum PriorityTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "priority",
            name: "Priority Tests",
            tests: [
                PriorityOrderTest(), // Logic only, no service needed
                PreemptionTest(service: service)
            ]
        )
    }
}

@MainActor
struct PriorityOrderTest: TestCase {
    let id = "priority.order"
    let name = "Priority ordering check"
    
    func run() async throws -> TestResult {
        
        
        guard Banner.Priority.critical > Banner.Priority.high else {
            return .failed(reason: "Critical not > High")
        }
        guard Banner.Priority.high > Banner.Priority.medium else {
            return .failed(reason: "High not > Medium")
        }
        guard Banner.Priority.medium > Banner.Priority.low else {
            return .failed(reason: "Medium not > Low")
        }
        
        return .passed
    }
}

@MainActor
struct PreemptionTest: TestCase {
    let id = "priority.preempt"
    let name = "High priority preempts low"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(500))
        
        // 1. Show low priority banner
        CoreLogger.shared.debug("Showing low priority banner", category: .testing)
        service.info("Low", priority: .low)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner?.title == "Low" else {
            return .failed(reason: "Initial banner not shown")
        }
        
        // 2. Show high priority banner - should preempt
        CoreLogger.shared.debug("Showing high priority banner", category: .testing)
        service.error("High", priority: .high)
        try await Task.sleep(for: .milliseconds(500))
        
        guard service.currentBanner?.title == "High" else {
            return .failed(reason: "High priority did not preempt")
        }
        
        service.dismissAll()
        return .passed
    }
}
