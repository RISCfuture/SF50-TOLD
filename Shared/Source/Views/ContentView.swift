import Defaults
import Foundation
import SwiftUI

struct ContentView: View {
    @Default(.initialSetupComplete)
    var initialSetupComplete

    @ObservedObject var state: AppState
    @ObservedObject var service: AirportLoadingService

    @State private var tab = 1

    @ViewBuilder var body: some View {
        if let error = state.error {
            ErrorView(error: error)
        } else if service.loading {
            LoadingView(downloadProgress: state.airportLoadingService.downloadProgress,
                        decompressProgress: state.airportLoadingService.decompressProgress,
                        processingProgress: state.airportLoadingService.processingProgress)
            .padding(.all, 20)
        } else if !initialSetupComplete {
            WelcomeView()
        } else if service.needsLoad {
            LoadingConsentView(service: service)
        } else {
            TabView(selection: $tab) {
                TakeoffView(state: state.takeoff).tabItem {
                    Label("Takeoff", image: "Takeoff")
                }
                .tag(1)

                LandingView(state: state.landing).tabItem {
                    Label("Landing", image: "Landing")
                }
                .tag(2)

                SettingsView().tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)

                AboutView().tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(4)
            }
            .tapToDismissKeyboard()
            .accessibilityIdentifier("mainTabView")
        }
    }
}

#Preview {
    let state = AppState()

    return ContentView(state: state, service: state.airportLoadingService)
}
