import CorePresentation
import CoreSwift
import Foundation

@MainActor
/// Tests focused on banner dismissal logic (auto-dismiss, persistence, manual dismissal).
enum DismissalTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "dismissal",
            name: "Dismissal Tests",
            tests: [
                AutoDismissTest(service: service),
                PersistentTest(service: service),
                NoneDismissalTest(service: service),
                DismissPromotesNextTest(service: service)
            ]
        )
    }
}

@MainActor
struct AutoDismissTest: TestCase {
    let id = "dismiss.auto"
    let name = "Auto-dismiss duration"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        // potentially clear any existing state
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(
            title: "Auto",
            style: .info,
            dismissal: .auto(duration: 0.3)
        )
        service.show(config)
        
        try await Task.sleep(for: .milliseconds(100))
        guard service.currentBanner != nil else {
            return .failed(reason: "Setup failed")
        }
        
        CoreLogger.shared.debug("Waiting for auto-dismiss", category: .testing)
        try await Task.sleep(for: .milliseconds(400))
        
        if service.currentBanner == nil {
            return .passed
        } else {
            return .failed(reason: "Did not auto-dismiss")
        }
    }
}

@MainActor
struct PersistentTest: TestCase {
    let id = "dismiss.persistent"
    let name = "Persistent banner"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        // cleanup previous state
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(
            title: "Persistent",
            style: .info,
            dismissal: .persistent
        )
        service.show(config)
        
        // Wait longer than typical auto-dismiss
        try await Task.sleep(for: .milliseconds(500))
        
        guard service.currentBanner != nil else {
            return .failed(reason: "Persistent banner was dismissed")
        }
        
        service.dismissAll() // cleanup
        return .passed
    }
}

@MainActor
/// Verifies that banners with .none dismissal mode do not auto-dismiss but can be manually dismissed.
struct NoneDismissalTest: TestCase {
    let id = "dismiss.none"
    let name = "None dismissal mode"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(
            title: "No Auto Dismiss",
            style: .warning,
            dismissal: .none
        )
        service.show(config)
        
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner != nil else {
            return .failed(reason: "Banner not shown")
        }
        
        // Wait extended period to ensure no auto-dismiss
        try await Task.sleep(for: .milliseconds(1000))
        
        guard service.currentBanner != nil else {
            return .failed(reason: "Banner with .none dismissal was auto-dismissed")
        }
        
        // Verify manual dismissal still works
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(300))
        
        guard service.currentBanner == nil else {
            return .failed(reason: "Manual dismiss failed for .none dismissal")
        }
        
        return .passed
    }
}

@MainActor
struct DismissPromotesNextTest: TestCase {
    let id = "dismiss.current"
    let name = "Dismiss current promotes next"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        // Show two banners: one active, one queued
        let config1 = DefaultBannerConfiguration(title: "First", style: .info, priority: .medium)
        let config2 = DefaultBannerConfiguration(title: "Second", style: .success, priority: .medium)
        
        service.show(config1)
        service.show(config2)
        try await Task.sleep(for: .milliseconds(100))
        
        guard service.currentBanner?.title == "First" else {
            return .failed(reason: "First banner not active")
        }
        
        // Dismiss only the current banner
        service.dismissCurrent()
        try await Task.sleep(for: .milliseconds(500))
        
        guard service.currentBanner?.title == "Second" else {
            return .failed(reason: "Second banner did not promote. Current: \(service.currentBanner?.title ?? "nil")")
        }
        
        service.dismissAll()
        return .passed
    }
}
