import Foundation
import SwiftUI

struct ContentView: View {
    @ObservedObject var state: AppState
    
    @State private var tab = 1
    
    @ViewBuilder
    var body: some View {
        if let error = state.error {
            ErrorView(error: error)
        } else if state.loadingAirports {
            LoadingView(progress: state.airportLoadingService.progress)
                .padding(.all, 20)
        } else if state.needsLoad {
            LoadingConsentView(state: state)
        } else {
            TabView(selection: $tab) {
                TakeoffView(state: state.takeoff).tabItem {
                    Label("Takeoff", image: "Takeoff")
                }.tag(1)
                LandingView(state: state.landing).tabItem {
                    Label("Landing", image: "Landing")
                }.tag(2)
                SettingsView(state: state.settings).tabItem {
                    Label("Settings", systemImage: "gear")
                }.tag(3)
                AboutView().tabItem {
                    Label("About", systemImage: "info.circle")
                }.tag(4)
            }.tapToDismissKeyboard()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        return ContentView(state: AppState())
    }
}
