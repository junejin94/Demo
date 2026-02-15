import CorePresentation
import CoreSwift
import Foundation
import SwiftUI

@MainActor
/// Tests focused on banner configuration options (icons, colors, swipe dismissal, etc.).
enum ConfigurationTests {
    static func category(service: any Banner.Service) -> TestCategory {
        TestCategory(
            id: "config",
            name: "Configuration Tests",
            tests: [
                CustomIconTest(service: service),
                CustomColorTest(service: service),
                SwipeDisabledTest(service: service),
                MessageFieldTest(service: service),
                IconNoneTest(service: service),
                IconAssetTest(service: service),
                AccessibilityLabelTest(service: service),
                HapticConfigTest(service: service),
                AnimationConfigTest(service: service)
            ]
        )
    }
}

@MainActor
struct CustomIconTest: TestCase {
    let id = "config.icon"
    let name = "Custom icon assignment"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        var config = DefaultBannerConfiguration(title: "Icon", style: .info)
        config.icon = .system("star.fill")
        
        guard config.icon == .system("star.fill") else {
            return .failed(reason: "Icon not set")
        }
        
        service.show(config)
        
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.icon == .system("star.fill") else {
            return .failed(reason: "Current banner icon mismatch")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct CustomColorTest: TestCase {
    let id = "config.color"
    let name = "Custom tint color"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        var config = DefaultBannerConfiguration(title: "Color", style: .info)
        config.tintColor = .red
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.tintColor == .red else {
            return .failed(reason: "Tint color mismatch")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct SwipeDisabledTest: TestCase {
    let id = "config.swipe"
    let name = "Swipe dismiss disabled"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(
            title: "Can't Swipe",
            style: .warning,
            isDismissible: false
        )
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(200))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.isDismissible == false else {
            return .failed(reason: "isDismissible mismatch: expected false")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
struct MessageFieldTest: TestCase {
    let id = "config.message"
    let name = "Title and message fields"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let config = DefaultBannerConfiguration(
            title: "Title Here",
            message: "Message body text",
            style: .info
        )
        
        guard config.title == "Title Here" else {
            return .failed(reason: "Title mismatch")
        }
        guard config.message == "Message body text" else {
            return .failed(reason: "Message mismatch")
        }
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.title == "Title Here", current.message == "Message body text" else {
            return .failed(reason: "Current banner fields don't match")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies that icon with .none hides the icon.
struct IconNoneTest: TestCase {
    let id = "config.icon.none"
    let name = "Icon set to .none"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        var config = DefaultBannerConfiguration(title: "No Icon", style: .info)
        config.icon = .none
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.icon == .none else {
            return .failed(reason: "Icon not set to .none")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies that icon with asset Image is preserved.
struct IconAssetTest: TestCase {
    let id = "config.icon.asset"
    let name = "Icon with custom Image asset"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        let customImage = Image(systemName: "star.fill")
        var config = DefaultBannerConfiguration(title: "Asset Icon", style: .info)
        config.icon = .asset(customImage)
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        // Note: Comparing Images is complex, so we verify the enum case
        if case .asset = current.icon {
            service.dismissAll()
            return .passed
        } else {
            service.dismissAll()
            return .failed(reason: "Icon not set to .asset type")
        }
    }
}

@MainActor
/// Verifies that accessibilityLabel is preserved.
struct AccessibilityLabelTest: TestCase {
    let id = "config.accessibility"
    let name = "Custom accessibility label"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        var config = DefaultBannerConfiguration(title: "A11y Test", style: .info)
        config.accessibilityLabel = "Custom accessibility description"
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.accessibilityLabel == "Custom accessibility description" else {
            return .failed(reason: "Accessibility label mismatch")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies that haptic configuration is preserved (cannot test actual haptic feedback).
struct HapticConfigTest: TestCase {
    let id = "config.haptic"
    let name = "Haptic configuration"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        var config = DefaultBannerConfiguration(title: "Haptic", style: .info)
        config.haptic = .none
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.haptic == .none else {
            return .failed(reason: "Haptic not set to .none")
        }
        
        service.dismissAll()
        return .passed
    }
}

@MainActor
/// Verifies that animation configuration is preserved (cannot test actual animation).
struct AnimationConfigTest: TestCase {
    let id = "config.animation"
    let name = "Animation configuration"
    let service: any Banner.Service
    
    func run() async throws -> TestResult {
        service.dismissAll()
        try? await Task.sleep(for: .milliseconds(100))
        
        var config = DefaultBannerConfiguration(title: "Animation", style: .info)
        config.animation = .none
        
        service.show(config)
        try await Task.sleep(for: .milliseconds(100))
        
        guard let current = service.currentBanner else {
            return .failed(reason: "Banner not shown")
        }
        
        guard current.animation == .none else {
            return .failed(reason: "Animation not set to .none")
        }
        
        service.dismissAll()
        return .passed
    }
}
