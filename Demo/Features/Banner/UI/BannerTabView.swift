import SwiftUI

/// The main navigation hub for the Banner feature demos.
///
/// Provides access to various demo screens like styles, priorities, configuration, and queue management.
struct BannerTabView: View {
    var body: some View {
        NavigationStack {
            List {
                NavigationLink("Basic Styles", destination: BasicStylesView())
                NavigationLink("Priority & Preemption", destination: PriorityDemoView())
                NavigationLink("Custom Configuration", destination: CustomConfigView())
                NavigationLink("Queue Management", destination: QueueManagementView())
            }
            .groupedListBackground()
            .navigationTitle("Banner")
        }
    }
}
