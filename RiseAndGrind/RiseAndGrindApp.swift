import SwiftUI

@main
struct RiseAndGrindApp: App {
    @StateObject private var appViewModel = AppViewModel()
    @StateObject private var profileManager = ProfileManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appViewModel)
                .environmentObject(profileManager)
        }
    }
} 