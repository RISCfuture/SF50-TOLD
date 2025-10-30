import Logging
import SwiftNASR
import SwiftUI

@main
struct DownloadNASRApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }

    Settings {
      SettingsView()
    }
  }

  init() {
    // Configure default log level
    LoggingSystem.bootstrap { label in
      var handler = StreamLogHandler.standardOutput(label: label)
      handler.logLevel = .notice
      return handler
    }
  }
}
