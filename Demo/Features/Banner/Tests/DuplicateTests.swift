import Foundation
import CorePresentation

@MainActor
/// Tests focused on duplicate banner handling strategies.
enum DuplicateTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "duplicate",
            name: "Duplicate Handling",
            tests: [
                RejectDuplicateTest(service: service),
                AllowDuplicateTest(service: service)
            ]
        )
    }
}

@MainActor
struct RejectDuplicateTest: TestCase {
    let id = "dup.reject"
    let name = "Reject duplicate ID"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let id = UUID()
        let config = DefaultBannerConfiguration(
            id: id,
            title: "Original",
            style: .info,
            priority: .medium,
            allowDuplicate: false
        )
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(50))
        
        // Try show again
        service.show(config)
        try await Task.sleep(for: .milliseconds(50))
        
        // Any in queue?
        let pending = await service.pendingQueue
        if pending.isEmpty {
            return .passed
        } else {
            return .failed(reason: "Duplicate was queued")
        }
    }
}

@MainActor
struct AllowDuplicateTest: TestCase {
    let id = "dup.allow"
    let name = "Allow duplicate ID"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let id = UUID()
        let config = DefaultBannerConfiguration(
            id: id,
            title: "Replica",
            style: .info,
            priority: .medium,
            allowDuplicate: true
        )
        
        service.show(config)
        // Try show again
        service.show(config)
        
        try await Task.sleep(for: .milliseconds(50))
        
        // Should have 1 active, 1 queued
        let pending = await service.pendingQueue
        if pending.count == 1 {
            return .passed
        } else {
            return .failed(reason: "Duplicate not queued. Count: \(pending.count)")
        }
    }
}
