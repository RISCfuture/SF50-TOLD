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

    // Default takeoff scenarios (hypotheticals only)
    let takeoffScenarios: [Scenario] = [
      Scenario(
        name: "OAT +10°C",
        operation: .takeoff,
        deltaTemperature: .init(value: 10, unit: .celsius)
      ),
      Scenario(
        name: "OAT -10°C",
        operation: .takeoff,
        deltaTemperature: .init(value: -10, unit: .celsius)
      ),
      Scenario(
        name: "Wind Speed +10 kts",
        operation: .takeoff,
        deltaWindSpeed: .init(value: 10, unit: .knots)
      ),
      Scenario(
        name: "Wind Speed -10 kts",
        operation: .takeoff,
        deltaWindSpeed: .init(value: -10, unit: .knots)
      ),
      Scenario(
        name: "Weight +200 lbs",
        operation: .takeoff,
        deltaWeight: .init(value: 200, unit: .pounds)
      ),
      Scenario(
        name: "Weight -200 lbs",
        operation: .takeoff,
        deltaWeight: .init(value: -200, unit: .pounds)
      )
    ]

    // Default landing scenarios (hypotheticals only)
    let landingScenarios: [Scenario] = [
      Scenario(
        name: "OAT +10°C",
        operation: .landing,
        deltaTemperature: .init(value: 10, unit: .celsius)
      ),
      Scenario(
        name: "OAT -10°C",
        operation: .landing,
        deltaTemperature: .init(value: -10, unit: .celsius)
      ),
      Scenario(
        name: "Wind Speed +10 kts",
        operation: .landing,
        deltaWindSpeed: .init(value: 10, unit: .knots)
      ),
      Scenario(
        name: "Wind Speed -10 kts",
        operation: .landing,
        deltaWindSpeed: .init(value: -10, unit: .knots)
      ),
      Scenario(
        name: "Weight +200 lbs",
        operation: .landing,
        deltaWeight: .init(value: 200, unit: .pounds)
      ),
      Scenario(
        name: "Weight -200 lbs",
        operation: .landing,
        deltaWeight: .init(value: -200, unit: .pounds)
      ),
      Scenario(
        name: "Flaps 50",
        operation: .landing,
        flapSettingOverride: "flaps50"
      )
    ]

    for scenario in takeoffScenarios + landingScenarios {
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
