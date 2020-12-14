import SwiftUI

#if canImport(UIKit)
let navigationStyle = StackNavigationViewStyle()
#else
let navigationStyle = DefaultNavigationViewStyle()
#endif

@main
struct SF50_TOLDApp: App {
    @StateObject private var state = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(state)
        }
    }
}
