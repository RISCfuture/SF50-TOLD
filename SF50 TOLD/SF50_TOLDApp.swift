import Defaults
import SF50_Shared
import Sentry
import SwiftData
import SwiftNASR
import SwiftUI
import WidgetKit

#if canImport(UIKit)
  @MainActor let navigationStyle = StackNavigationViewStyle()
#else
  @MainActor let navigationStyle = DefaultNavigationViewStyle()
#endif

private class WidgetReloadObserver: ObservableObject {
  private var notificationObserver: Any?

  init() {
    setupObserver()
  }

  private func setupObserver() {
    notificationObserver = NotificationCenter.default.addObserver(
      forName: UserDefaults.didChangeNotification,
      object: nil,
      queue: .main
    ) { _ in
      WidgetCenter.shared.reloadTimelines(ofKind: "SF50_SelectedAirport")
    }
  }

  deinit {
    if let observer = notificationObserver {
      NotificationCenter.default.removeObserver(observer)
    }
  }
}

@main
struct SF50_TOLDApp: App {
  var sharedModelContainer: ModelContainer = {
    let schema = Schema([
      Airport.self,
      Runway.self,
      NOTAM.self,
      Scenario.self
    ])
    let modelConfiguration = ModelConfiguration(
      schema: schema,
      isStoredInMemoryOnly: false,
      groupContainer: .identifier("group.codes.tim.TOLD")
    )

    do {
      return try ModelContainer(for: schema, configurations: [modelConfiguration])
    } catch {
      fatalError("Could not create ModelContainer: \(error)")
    }
  }()

  @StateObject private var widgetReloadObserver = WidgetReloadObserver()

  var body: some Scene {
    WindowGroup {
      ContentView()
        .modelContainer(sharedModelContainer)
        .task {
          ScenarioSeeder(container: sharedModelContainer).seedDefaultScenariosIfNeeded()
        }
    }
  }

  init() {
    // Handle UI testing mode
    let isUITesting = ProcessInfo.processInfo.arguments.contains("UI-TESTING")

    if isUITesting {
      UITestingHelper.setupUITestingEnvironment(container: sharedModelContainer)
    }

    // Only initialize Sentry if not running UI tests
    if !isUITesting {
      SentrySDK.start { options in
        options.dsn =
          "https://18ccb9d2342467fafcaebcc33cc676e5@o4510156629475328.ingest.us.sentry.io/4510161674502144"
        options.debug = true  // Enabled debug when first installing is always helpful

        // Adds IP for users.
        // For more information, visit: https://docs.sentry.io/platforms/apple/data-management/data-collected/
        options.sendDefaultPii = true

        // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
        // We recommend adjusting this value in production.
        options.tracesSampleRate = 1.0

        // Configure profiling. Visit https://docs.sentry.io/platforms/apple/profiling/ to learn more.
        options.configureProfiling = {
          $0.sessionSampleRate = 1.0  // We recommend adjusting this value in production.
          $0.lifecycle = .trace
        }

        // Filter out all errors from simulators to reduce CI noise
        options.beforeSend = { event in
          // Check if this event is from a simulator
          if let contexts = event.context,
            let device = contexts["device"],
            let simulator = device["simulator"] as? Bool,
            simulator == true
          {
            // Drop all simulator errors
            return nil
          }
          return event
        }

        // Uncomment the following lines to add more data to your events
        // options.attachScreenshot = true // This adds a screenshot to the error events
        // options.attachViewHierarchy = true // This adds the view hierarchy to the error events

        // Enable experimental logging features
        options.experimental.enableLogs = true
      }
    }
  }
}
