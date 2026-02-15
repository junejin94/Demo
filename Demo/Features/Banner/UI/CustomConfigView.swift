import SwiftUI
import CorePresentation

/// A demo view showcasing advanced banner customizations.
///
/// Demonstrates custom icons, colors, haptics, backgrounds, persistence,
/// actions, and custom durations.
struct CustomConfigView: View {
    @EnvironmentObject var banners: DefaultBannerService
    
    var body: some View {
        List {
            Section("Customization") {
                Button("Custom Icon (Star)") {
                    var config = DefaultBannerConfiguration(
                        title: "You're a Star!",
                        style: .success
                    )
                    config.icon = .system("star.fill")
                    banners.show(config)
                }
                
                Button("Custom Colors") {
                    var config = DefaultBannerConfiguration(
                        title: "Purple Rain",
                        style: .info
                    )
                    config.tintColor = .purple
                    banners.show(config)
                }
                
                Button("No Haptics") {
                    var config = DefaultBannerConfiguration(
                        title: "Silent Success",
                        style: .success
                    )
                    config.haptic = .none
                    banners.show(config)
                }
                Button("Custom Background (Pink)") {
                    var config = DefaultBannerConfiguration(
                        title: "Pretty in Pink",
                        message: "Custom background color",
                        style: .custom,
                        priority: .medium
                    )
                    config.backgroundColor = .pink
                    config.tintColor = .white
                    banners.show(config)
                }
                
                Button("Persistent (No Auto-Dismiss)") {
                    let config = DefaultBannerConfiguration(
                        title: "I'm staying here",
                        message: "Swipe to dismiss me manually",
                        style: .warning,
                        dismissal: .persistent
                    )
                    banners.show(config)
                }
                
                Button("Action Callback") {
                    let config = DefaultBannerConfiguration(
                        title: "Tap Me!",
                        message: "I will print to console",
                        style: .info,
                        action: {
                            print("Banner tapped!")
                        }
                    )
                    banners.show(config)
                }
                
                Button("Long Duration (10s)") {
                    let config = DefaultBannerConfiguration(
                        title: "Slow Fade",
                        message: "I stick around for 10 seconds",
                        style: .success,
                        dismissal: .auto(duration: 10.0)
                    )
                    banners.show(config)
                }
                
                Button("Swipe Disabled") {
                    let config = DefaultBannerConfiguration(
                        title: "Can't Touch This",
                        message: "Swipe to dismiss is disabled",
                        style: .error,
                        isDismissible: false
                    )
                    banners.show(config)
                }
            }
        }
        .groupedListBackground()
        .navigationTitle("Custom Config")
    }
}
