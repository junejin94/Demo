import Foundation
import CorePresentation

@MainActor
/// Tests focused on banner lifecycle callbacks (onDismiss).
enum CallbackTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "callbacks",
            name: "Callback Tests",
            tests: [
                OnDismissCallbackTest(service: service),
                OnDismissAutoDismissTest(service: service),
                OnDismissMultipleTest(service: service)
            ]
        )
    }
}

@MainActor
/// Verifies that onDismiss callback executes when banner is manually dismissed.
struct OnDismissCallbackTest: TestCase {
    let id = "callback.ondismiss.manual"
    let name = "onDismiss callback on manual dismiss"
    let service: any Banner.Service
    
    // Helper class to handle concurrent mutations safely
    final class CallbackState: @unchecked Sendable {
        var wasCalled = false
    }
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let state = CallbackState()
        
        var config = DefaultBannerConfiguration(
            title: "Dismiss Me",
            style: .info,
            priority: .medium,
            dismissal: .persistent
        )
        // Check if we are on main thread, but using Unchecked Sendable class for simplicity in test
        config.onDismiss = {
            state.wasCalled = true
        }
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner != nil else {
            return .failed(reason: "Banner not shown")
        }
        
        // Manually dismiss
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(300))
        
        guard state.wasCalled else {
            return .failed(reason: "onDismiss callback not executed")
        }
        
        return .passed
    }
}

@MainActor
/// Verifies that onDismiss callback executes when banner auto-dismisses.
struct OnDismissAutoDismissTest: TestCase {
    let id = "callback.ondismiss.auto"
    let name = "onDismiss callback on auto-dismiss"
    let service: any Banner.Service
    
    final class CallbackState: @unchecked Sendable {
        var wasCalled = false
    }
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let state = CallbackState()
        
        var config = DefaultBannerConfiguration(
            title: "Auto Dismiss",
            style: .info,
            priority: .medium,
            dismissal: .auto(duration: 0.3)
        )
        config.onDismiss = {
            state.wasCalled = true
        }
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner != nil else {
            return .failed(reason: "Banner not shown")
        }
        
        // Wait for auto-dismiss
        try await Task.sleep(for: .milliseconds(400))
        
        guard state.wasCalled else {
            return .failed(reason: "onDismiss callback not executed on auto-dismiss")
        }
        
        return .passed
    }
}

@MainActor
/// Verifies that each banner's onDismiss callback is independent.
struct OnDismissMultipleTest: TestCase {
    let id = "callback.ondismiss.multiple"
    let name = "Independent onDismiss callbacks"
    let service: any Banner.Service
    
    final class CallbackState: @unchecked Sendable {
        var firstDismissed = false
        var secondDismissed = false
    }
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let state = CallbackState()
        
        // Create two banners with different callbacks
        var config1 = DefaultBannerConfiguration(
            title: "First",
            style: .info,
            priority: .medium
        )
        config1.onDismiss = {
            state.firstDismissed = true
        }
        
        var config2 = DefaultBannerConfiguration(
            title: "Second",
            style: .success,
            priority: .medium
        )
        config2.onDismiss = {
            state.secondDismissed = true
        }
        
        // Show both (first active, second queued)
        service.show(config1)
        service.show(config2)
        try await Task.sleep(for: .milliseconds(100))
        
        // Dismiss first
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(500))
        
        guard state.firstDismissed else {
            return .failed(reason: "First banner's onDismiss not called")
        }
        
        guard !state.secondDismissed else {
            return .failed(reason: "Second banner's onDismiss called prematurely")
        }
        
        // Wait for second to become active
        if service.currentBanner?.title != "Second" {
            try await Task.sleep(for: .milliseconds(200))
        }
        
        guard service.currentBanner?.title == "Second" else {
            return .failed(reason: "Second banner did not become active. Current: \(service.currentBanner?.title ?? "nil")")
        }
        
        // Dismiss second (now active)
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(500))
        
        guard state.secondDismissed else {
            return .failed(reason: "Second banner's onDismiss not called")
        }
        
        return .passed
    }
}
