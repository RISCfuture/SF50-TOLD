import Foundation
import SF50_Shared
import SwiftData

/**
 * Fetches user-defined scenarios from SwiftData for TLR generation.
 *
 * ``ScenarioFetcher`` is a `@ModelActor` that queries `Scenario` models and
 * converts them to ``PerformanceScenario`` structs for use in report generation.
 *
 * ## Usage
 *
 * ```swift
 * let fetcher = ScenarioFetcher(modelContainer: container)
 * let scenarios = try await fetcher.fetchTakeoffScenarios()
 * ```
 *
 * Both fetch methods automatically prepend a "Forecast Conditions" scenario
 * with no adjustments, ensuring the base case is always calculated.
 */
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
