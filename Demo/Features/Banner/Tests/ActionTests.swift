import Foundation
import CorePresentation

@MainActor
/// Tests focused on banner action callbacks.
enum ActionTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "action",
            name: "Action Tests",
            tests: [
                ActionPresenceTest(service: service),
                ActionExecutionTest(service: service)
            ]
        )
    }
}

@MainActor
/// Verifies that a banner with an action is correctly enqueued and retains its action.
struct ActionPresenceTest: TestCase {
    let id = "action.presence"
    let name = "Action closure attached"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        service.info("Tap Me", priority: .high) {
            // Action
            // Note: We can't Programmatically tap the banner UI from unit test logic easily without UI automation.
            // But we CAN verify the closure is stored correctly in the config that is presented.
        }
        
        // Limitation: This is hard to test without UI interaction.
        // We will instead verify the current banner has an action.
        
        try await Task.sleep(for: .milliseconds(50))
        
        if let current = service.currentBanner, current.action != nil {
            return .passed
        } else {
            return .failed(reason: "Action not present on current banner")
        }
    }
}

@MainActor
/// Verifies that a banner's action callback actually executes when invoked.
struct ActionExecutionTest: TestCase {
    let id = "action.execute"
    let name = "Action callback executes"
    let service: any Banner.Service
    
    final class ActionState: @unchecked Sendable {
        var wasExecuted = false
        var executionCount = 0
    }
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Create test-scoped flag to verify execution
        let state = ActionState()
        
        service.info("Execute Action", priority: .high) {
            state.wasExecuted = true
            state.executionCount += 1
        }
        
        try await Task.sleep(for: .milliseconds(50))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard let action = current.action else {
            return .failed(reason: "Action closure not present")
        }
        
        // Directly invoke the action
        action()
        
        // Verify execution
        guard state.wasExecuted else {
            return .failed(reason: "Action did not execute")
        }
        
        guard state.executionCount == 1 else {
            return .failed(reason: "Action executed \(state.executionCount) times, expected 1")
        }
        
        // Verify action can be invoked multiple times
        action()
        guard state.executionCount == 2 else {
            return .failed(reason: "Action not re-executable")
        }
        
        service.dismissAll()
        return .passed
    }
}
