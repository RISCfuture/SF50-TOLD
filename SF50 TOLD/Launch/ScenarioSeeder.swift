import Defaults
import SF50_Shared
import SwiftData

@MainActor
struct ScenarioSeeder {
  let container: ModelContainer

  func seedDefaultScenariosIfNeeded() {
    // Check if we've already seeded default scenarios
    guard !Defaults[.defaultScenariosSeeded] else { return }

    let context = container.mainContext

    for scenario in Scenario.defaultScenarios() {
      context.insert(scenario)
    }

    do {
      try context.save()
      Defaults[.defaultScenariosSeeded] = true
    } catch {
      // Log error but don't crash - scenarios are not critical for app function
      print("Failed to seed default scenarios: \(error)")
    }
  }
}
