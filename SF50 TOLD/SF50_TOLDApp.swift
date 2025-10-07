import Bugsnag
import BugsnagPerformance
import Defaults
import SF50_Shared
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
      NOTAM.self
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
    }
  }

  init() {
    // Only initialize BugSnag in release builds
    #if !DEBUG
      Bugsnag.start()
      BugsnagPerformance.start()
    #endif

    // Handle UI testing mode
    if ProcessInfo.processInfo.arguments.contains("UI-TESTING") {
      setupUITestingEnvironment()
    }
  }

  private func setupUITestingEnvironment() {
    // Reset all defaults
    Defaults.removeAll(suite: UserDefaults(suiteName: "group.codes.tim.TOLD")!)

    // Set minimal configuration for testing - let tests go through setup flow
    Defaults[.updatedThrustSchedule] = false  // G1 model
    Defaults[.schemaVersion] = latestSchemaVersion
  }

  @MainActor
  private func seedTestData() {
    let context = sharedModelContainer.mainContext

    // Delete existing data
    try? context.delete(model: Runway.self)
    try? context.delete(model: Airport.self)
    try? context.delete(model: NOTAM.self)

    // Insert test airports
    try? insertAirport(.KOAK, context: context)
    try? insertAirport(.KSQL, context: context)
    try? insertAirport(.K1C9, context: context)

    try? context.save()
  }

  @MainActor
  private func insertAirport(_ builder: AirportBuilder, context: ModelContext) throws {
    let airport = builder.unsaved()
    context.insert(airport)
    for runway in airport.runways {
      context.insert(runway)
    }
  }
}
