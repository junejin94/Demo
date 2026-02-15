import SwiftUI
import CorePresentation

/// A demo view showcasing banner priority and preemption.
///
/// Demonstrates how higher priority banners (e.g., `.critical`) can preempt
/// currently displayed lower priority banners.
struct PriorityDemoView: View {
    @EnvironmentObject var banners: DefaultBannerService
    
    var body: some View {
        List {
            Section("Priorities") {
                Button("Low Priority") {
                    banners.show(
                        DefaultBannerConfiguration(title: "Low Priority", style: .info, priority: .low)
                    )
                }
                
                Button("Medium Priority") {
                    banners.show(
                        DefaultBannerConfiguration(title: "Medium Priority", style: .info, priority: .medium)
                    )
                }
                
                Button("High Priority") {
                    banners.show(
                        DefaultBannerConfiguration(title: "High Priority", style: .warning, priority: .high)
                    )
                }
                
                Button("Critical Priority (Preempts)") {
                    banners.show(
                        DefaultBannerConfiguration(title: "Critical!", style: .error, priority: .critical)
                    )
                }
            }
            
            Section("Instructions") {
                Text("Tap Low, then Critical to see preemption in action.")
            }
        }
        .groupedListBackground()
        .navigationTitle("Priority Demo")
    }
}
