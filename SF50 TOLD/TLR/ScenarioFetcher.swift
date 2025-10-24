import Foundation
import SF50_Shared
import SwiftData

@ModelActor
actor ScenarioFetcher {
  func fetchTakeoffScenarios() throws -> [PerformanceScenario] {
    let descriptor = FetchDescriptor<Scenario>(
      predicate: #Predicate { $0._operation == "takeoff" },
      sortBy: [SortDescriptor(\.name)]
    )
    let scenarioModels = try modelContext.fetch(descriptor)
    let userScenarios = scenarioModels.map { PerformanceScenario.from($0) }

    // Always prepend "Forecast Conditions" scenario (base conditions with no adjustments)
    let forecastScenario = PerformanceScenario(name: "Forecast Conditions")
    return [forecastScenario] + userScenarios
  }

  func fetchLandingScenarios() throws -> [PerformanceScenario] {
    let descriptor = FetchDescriptor<Scenario>(
      predicate: #Predicate { $0._operation == "landing" },
      sortBy: [SortDescriptor(\.name)]
    )
    let scenarioModels = try modelContext.fetch(descriptor)
    let userScenarios = scenarioModels.map { PerformanceScenario.from($0) }

    // Always prepend "Forecast Conditions" scenario (base conditions with no adjustments)
    let forecastScenario = PerformanceScenario(name: "Forecast Conditions")
    return [forecastScenario] + userScenarios
  }
}
