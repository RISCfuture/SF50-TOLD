import Defaults
import SF50_Shared
import Sentry
import SwiftData

@MainActor
struct ScenarioSeeder {
  let container: ModelContainer

  func seedDefaultScenariosIfNeeded() {
    // Check if we've already seeded default scenarios via the flag
    guard !Defaults[.defaultScenariosSeeded] else { return }

    let context = container.mainContext

    // Insert default scenarios
    for scenario in Scenario.defaultScenarios() {
      context.insert(scenario)
    }

    do {
      try context.save()
      Defaults[.defaultScenariosSeeded] = true
    } catch {
      // If save fails, rollback the context to avoid leaving it in a bad state
      context.rollback()

      // Report error to Sentry so we can track this issue
      SentrySDK.capture(error: error) { scope in
        scope.setContext(
          value: [
            "scenarioCount": Scenario.defaultScenarios().count
          ],
          key: "scenarioSeeding"
        )
      }

      // Log error but don't crash - scenarios are not critical for app function
      print("Failed to seed default scenarios: \(error)")
    }
  }
}
