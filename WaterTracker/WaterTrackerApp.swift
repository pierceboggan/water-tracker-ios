import SwiftUI

@main
struct WaterTrackerApp: App {
    @StateObject private var waterStore = WaterStore()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(waterStore)
        }
    }
}
