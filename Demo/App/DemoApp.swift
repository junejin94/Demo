import SwiftUI
import CorePresentation

@main
/// The entry point for the Demo application.
///
/// Configured with a default `BannerService` and capable of running
/// automated test suites via command line arguments.
struct DemoApp: App {
    private let bannerService = DefaultBannerService(maxQueueSize: 5)
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .banners(service: bannerService)
                .task {
                    guard CommandLine.arguments.contains("-runTests") else { return }
                    
                    print("--- TEST RUNNER START ---")
                    print("Identifying test suites...")
                    
                    // Wait for environment stability
                    try? await Task.sleep(for: .seconds(0.5))
                    
                    let runner = TestRunner()
                    let suites = [BannerTestSuite.create(service: bannerService)]
                    
                    print("Running \(suites.count) suite(s)...")
                    
                    await runner.runAll(suites)
                    
                    let total = runner.results.count
                    let passed = runner.passedCount
                    let failed = runner.failedCount
                    
                    print("\n--- TEST RESULTS ---")
                    
                    if failed > 0 {
                        print("\n[FAILED TESTS]")
                        
                        for (id, result) in runner.results {
                            if case .failed(let reason) = result {
                                print("❌ \(id): \(reason)")
                            } else if case .error(let message) = result {
                                print("⚠️ \(id) (Error): \(message)")
                            }
                        }
                    } else {
                        print("\nAll tests passed.")
                    }
                    
                    print("""
                    
                    [SUMMARY]
                    Total:  \(total)
                    Passed: \(passed)
                    Failed: \(failed)
                    Duration: \(String(format: "%.2f", runner.totalDuration))s
                    --------------------
                    """)
                    
                    if failed == 0 && total > 0 {
                        exit(0)
                    } else {
                        exit(1)
                    }
                }
        }
    }
}
