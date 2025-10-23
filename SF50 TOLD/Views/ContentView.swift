import Defaults
import Foundation
import SF50_Shared
import SwiftUI

struct ContentView: View {
  @Default(.initialSetupComplete)
  private var initialSetupComplete

  @State private var tab = 1
  @State private var loader: AirportLoaderViewModel?

  @Environment(\.modelContext)
  private var context

  var body: some View {
    content
      .onAppear {
        loader = .init(container: context.container)
      }
      .environment(\.locationStreamer, CoreLocationStreamer())
  }

  @ViewBuilder private var content: some View {
    if !initialSetupComplete {
      WelcomeView()
    } else if let loader, loader.showLoader {
      LoadingView()
        .environment(loader)
    } else {
      TabView(selection: $tab) {
        TakeoffView().tabItem {
          Label("Takeoff", systemImage: "airplane.departure")
        }
        .tag(1)

        ClimbView().tabItem {
          Label("Climb", systemImage: "arrow.up.right")
        }
        .tag(2)

        LandingView().tabItem {
          Label("Landing", systemImage: "airplane.arrival")
        }
        .tag(3)

        SettingsView().tabItem {
          Label("Settings", systemImage: "gear")
        }
        .tag(4)

        AboutView().tabItem {
          Label("About", systemImage: "info.circle")
        }
        .tag(5)
      }
      .tapToDismissKeyboard()
      .accessibilityIdentifier("mainTabView")
    }
  }
}

#Preview {
  ContentView()
}
