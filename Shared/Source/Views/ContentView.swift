import Foundation
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var state: AppState
    
    @State private var tab = 1
    
    @ViewBuilder
    var body: some View {
        ErrorView(error: state.error) {
            if state.loadingAirports {
                LoadingView(progress: state.airportLoadingService.progress?.progress)
                    .padding(.all, 20)
            } else if state.needsLoad {
                LoadingConsentView()
            } else {
                TabView(selection: $tab) {
                    TakeoffView().tabItem {
                        Label("Takeoff", image: "Takeoff")
                    }.tag(1).environmentObject(state.takeoff)
                    LandingView().tabItem {
                        Label("Landing", image: "Landing")
                    }.tag(2).environmentObject(state.landing)
                    SettingsView().environmentObject(state.settings).tabItem {
                        Label("Settings", systemImage: "gear")
                    }.tag(3)
                    AboutView().tabItem {
                        Label("About", systemImage: "info.circle")
                    }.tag(4)
                }.tapToDismissKeyboard()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        return ContentView().environmentObject(AppState())
    }
}

