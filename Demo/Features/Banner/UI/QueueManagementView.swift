import SwiftUI
import CorePresentation

/// A demo view showcasing banner queue management.
///
/// Demonstrates adding multiple banners to the queue, clearing the queue,
/// and immediate dismissal of all banners.
struct QueueManagementView: View {
    @EnvironmentObject var banners: DefaultBannerService
    
    var body: some View {
        List {
            Section("Queue Actions") {
                Button("Queue Multiple Banners") {
                    for index in 1...5 {
                        banners.show(
                            DefaultBannerConfiguration(
                                title: "Banner \(index)",
                                style: .info
                            )
                        )
                    }
                }
                
                Button("Clear Queue") {
                    banners.clearQueue()
                }
                
                Button("Dismiss All (Immediate)") {
                    banners.dismissAll()
                }
            }
        }
        .groupedListBackground()
        .navigationTitle("Queue Management")
    }
}
