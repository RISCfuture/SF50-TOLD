import Defaults
import Foundation
import SF50_Shared
import SwiftData
import SwiftNASR

enum UITestingHelper {
  static func setupUITestingEnvironment(container: ModelContainer) {
    // Reset all defaults
    Defaults.removeAll(suite: UserDefaults(suiteName: "group.codes.tim.TOLD")!)

    // Check if we're generating screenshots (should use live data)
    let isGeneratingScreenshots = ProcessInfo.processInfo.arguments.contains("GENERATE-SCREENSHOTS")

    // Set minimal configuration for testing - let tests go through setup flow
    Defaults[.schemaVersion] = latestSchemaVersion
    Defaults[.favoriteAirports] = []  // Ensure no favorites at start

    // Only seed test data for regular UI tests, not screenshot generation
    if !isGeneratingScreenshots {
      Defaults[.lastCycleLoaded] = Cycle.current  // Prevent database loader from appearing

      // Seed test data for airports used in UI tests
      Task { @MainActor in
        seedTestData(container: container)
      }
    }
  }

  @MainActor
  private static func seedTestData(container: ModelContainer) {
    let context = container.mainContext

    // Delete existing data
    try? context.delete(model: Runway.self)
    try? context.delete(model: Airport.self)
    try? context.delete(model: NOTAM.self)
    try? context.delete(model: Scenario.self)

    // Insert test airports
    try? insertAirport(.KOAK, context: context)
    try? insertAirport(.KSQL, context: context)
    try? insertAirport(.K1C9, context: context)

    try? context.save()
  }

  @MainActor
  private static func insertAirport(_ builder: AirportBuilder, context: ModelContext) throws {
    let airport = builder.unsaved()
    context.insert(airport)
    for runway in airport.runways {
      context.insert(runway)
    }
  }
}
