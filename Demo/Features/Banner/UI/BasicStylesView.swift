import SwiftUI
import CorePresentation

/// A demo view showcasing the standard banner styles.
///
/// Demonstrates `.info`, `.success`, `.warning`, and `.error` styles using
/// default configurations.
struct BasicStylesView: View {
    @EnvironmentObject var banners: DefaultBannerService
    
    var body: some View {
        List {
            Section("Standard Styles") {
                Button("Show Info") {
                    banners.show(
                        DefaultBannerConfiguration(
                            title: "Information",
                            message: "This is an informational message.",
                            style: .info
                        )
                    )
                }
                
                Button("Show Success") {
                    banners.show(
                        DefaultBannerConfiguration(
                            title: "Success",
                            message: "Operation completed successfully.",
                            style: .success
                        )
                    )
                }
                
                Button("Show Warning") {
                    banners.show(
                        DefaultBannerConfiguration(
                            title: "Warning",
                            message: "Something might be wrong.",
                            style: .warning
                        )
                    )
                }
                
                Button("Show Error") {
                    banners.show(
                        DefaultBannerConfiguration(
                            title: "Error",
                            message: "An error occurred.",
                            style: .error
                        )
                    )
                }
            }
        }
        .groupedListBackground()
        .navigationTitle("Basic Styles")
    }
}
