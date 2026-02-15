import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            demoTab
            testingTab
        }
    }
    
    // MARK: - Tabs
    
    private var demoTab: some View {
        BannerTabView()
            .tabItem {
                Label("Demo", systemImage: "play.circle")
            }
    }
    
    private var testingTab: some View {
        TestingView()
            .tabItem {
                Label("Testing", systemImage: "checkmark.circle")
            }
    }
}


