import CorePresentation
import CoreSwift
import Foundation

@MainActor
/// Tests focused on verifying banner style configurations.
enum StyleTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "style",
            name: "Style Tests",
            tests: [
                InfoStyleTest(service: service),
                SuccessStyleTest(service: service),
                WarningStyleTest(service: service),
                ErrorStyleTest(service: service),
                CustomStyleTest(service: service)
            ]
        )
    }
}

@MainActor
struct InfoStyleTest: TestCase {
    let id = "style.info"
    let name = "Info banner style"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(title: "Info", style: .info)
        
        // Show for visual and state verification
        service.show(config)
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.style == .info else {
            return .failed(reason: "Style mismatch: expected .info, got \(current.style)")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct SuccessStyleTest: TestCase {
    let id = "style.success"
    let name = "Success banner style"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(title: "Success", style: .success)
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.style == .success else {
            return .failed(reason: "Style mismatch: expected .success, got \(current.style)")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct WarningStyleTest: TestCase {
    let id = "style.warning"
    let name = "Warning banner style"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(title: "Warning", style: .warning)
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.style == .warning else {
            return .failed(reason: "Style mismatch: expected .warning, got \(current.style)")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct ErrorStyleTest: TestCase {
    let id = "style.error"
    let name = "Error banner style"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(title: "Error", style: .error)
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.style == .error else {
            return .failed(reason: "Style mismatch: expected .error, got \(current.style)")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct CustomStyleTest: TestCase {
    let id = "style.custom"
    let name = "Custom banner style"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(title: "Custom", style: .custom)
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.style == .custom else {
            return .failed(reason: "Style mismatch: expected .custom, got \(current.style)")
        }
        
        service.dismissAll()
        return .passed
    }
}
