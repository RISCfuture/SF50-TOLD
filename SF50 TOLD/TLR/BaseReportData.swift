import Foundation
import SF50_Shared

// MARK: - Base Report Data

class BaseReportData<PerformanceType, ScenarioType> {
  let input: PerformanceInput
  let performance: DefaultPerformanceCalculationService
  let scenarios: [PerformanceScenario]

  init(
    input: PerformanceInput,
    scenarios: [PerformanceScenario],
    performance: DefaultPerformanceCalculationService = .shared
  ) {
    self.input = input
    self.scenarios = scenarios
    self.performance = performance
  }

  // MARK: - Template Methods (to be overridden)

  func operation() -> SF50_Shared.Operation {
    fatalError("Subclasses must override operation()")
  }

  func calculatePerformance(
    for _: RunwayInput,
    conditions _: Conditions,
    config _: Configuration
  ) throws -> PerformanceType {
    fatalError("Subclasses must override calculatePerformance(for:conditions:config:)")
  }

  func determineMaxWeight(runway _: RunwayInput) throws -> (
    Measurement<UnitMass>, LimitingFactor
  ) {
    fatalError("Subclasses must override determineMaxWeight(runway:)")
  }

  func createScenario(name _: String, runways _: [RunwayInput: PerformanceType]) -> ScenarioType {
    fatalError("Subclasses must override createScenario(name:runways:)")
  }

  func maxWeight() -> Measurement<UnitMass> {
    fatalError("Subclasses must override maxWeight()")
  }

  // MARK: - Common Implementation

  func generate() throws -> ReportOutput<ScenarioType> {
    let runways = try generateRunwayInfo()
    let scenarios = try generateScenarios()

    return .init(runwayInfo: runways, scenarios: scenarios)
  }

  func generateRunwayInfo() throws -> [RunwayInput: RunwayInfo] {
    try input.airport.runways.sorted().reduce(into: [:]) { dict, runway in
      let (maxWeight, limitingFactor) = try determineMaxWeight(runway: runway)

      dict[runway] = .init(
        maxWeight: maxWeight,
        limitingFactor: limitingFactor,
        contamination: runway.notam?.contamination
      )
    }
  }

  func generateScenarios() throws -> [ScenarioType] {
    try scenarios.map { scenarioDef in
      let runways = try calculatePerformanceForAllRunways(scenario: scenarioDef)
      return createScenario(name: scenarioDef.name, runways: runways)
    }
  }

  func calculatePerformanceForAllRunways(
    scenario: PerformanceScenario
  ) throws -> [RunwayInput: PerformanceType] {
    try input.airport.runways.reduce(into: [:]) { runways, runway in
      // Apply scenario adjustments for this specific runway
      let (conditions, config, adjustedRunway) = scenario.apply(
        baseConditions: input.conditions,
        baseConfiguration: input.configuration,
        runway: runway
      )

      let performance = try calculatePerformance(
        for: adjustedRunway,
        conditions: conditions,
        config: config
      )
      runways[runway] = performance
    }
  }

  // MARK: - Binary Search for Max Weight

  func binarySearchMaxWeight(
    runway _: RunwayInput,
    min: Measurement<UnitMass>,
    max: Measurement<UnitMass>,
    increment: Measurement<UnitMass> = .init(value: 50, unit: .pounds),
    isValid: (Measurement<UnitMass>) throws -> (valid: Bool, factor: LimitingFactor)
  ) rethrows -> (weight: Measurement<UnitMass>, limitingFactor: LimitingFactor?) {
    var low = (min / increment).rounded(.up) * increment
    var high = (max / increment).rounded(.down) * increment
    var bestValue = low
    var limitingFactor: LimitingFactor?

    while low <= high {
      let weight = ((low + high) / 2 / increment).rounded() * increment

      let result = try isValid(weight)

      if result.valid {
        bestValue = weight
        low = weight + increment
      } else {
        limitingFactor = result.factor
        high = weight - increment
      }
    }

    return (bestValue, limitingFactor)
  }
}
