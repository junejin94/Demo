import SwiftUI
import CorePresentation

@MainActor
/// Tests focused on custom banner background colors.
enum BackgroundColorTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "background",
            name: "Background Color Tests",
            tests: [
                CustomBackgroundTest(service: service)
            ]
        )
    }
}

@MainActor
/// Verifies that a custom background color is correctly applied to the banner configuration.
struct CustomBackgroundTest: TestCase {
    let id = "bg.custom"
    let name = "Verify custom background color"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        var config = DefaultBannerConfiguration(
            title: "Color Test",
            style: .custom,
            priority: .medium
        )
        config.backgroundColor = .blue
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(50))
        
        if let current = service.currentBanner {
            if current.backgroundColor == .blue {
                return .passed
            } else {
                return .failed(reason: "Background color mismatch. Expected blue, got \(String(describing: current.backgroundColor))")
            }
        } else {
            return .failed(reason: "No banner shown")
        }
    }
}
