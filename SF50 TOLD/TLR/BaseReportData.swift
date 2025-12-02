import Foundation
import SF50_Shared

// MARK: - Base Report Data

/// Base class for generating TLR performance data using the Template Method pattern.
///
/// ``BaseReportData`` provides the algorithm skeleton for calculating performance
/// across all runways and scenarios. Subclasses override template methods to provide
/// takeoff-specific or landing-specific calculations.
///
/// ## Template Methods
///
/// Subclasses must override:
/// - ``operation()``: Returns the operation type (takeoff/landing)
/// - ``maxWeight()``: Returns the maximum allowable weight
/// - ``calculatePerformance(for:conditions:config:)``: Calculates performance for one runway
/// - ``determineMaxWeight(runway:)``: Finds maximum weight for a runway
/// - ``createScenario(name:runways:)``: Creates a typed scenario from results
///
/// ## Usage
///
/// ```swift
/// let reportData = TakeoffReportData(input: input, scenarios: scenarios)
/// let output = try reportData.generate()
/// ```
///
/// ## See Also
///
/// - ``TakeoffReportData``
/// - ``LandingReportData``
class BaseReportData<PerformanceType, ScenarioType> {
  /// Input configuration for the report.
  let input: PerformanceInput

  /// Service for performing calculations.
  let performance: DefaultPerformanceCalculationService

  /// Scenarios to calculate performance for.
  let scenarios: [PerformanceScenario]

  /**
   * Creates a new report data generator.
   *
   * - Parameters:
   *   - input: Performance calculation inputs.
   *   - scenarios: What-if scenarios to calculate.
   *   - performance: Calculation service (defaults to shared instance).
   */
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

  /// Returns the operation type. Override in subclass.
  func operation() -> SF50_Shared.Operation {
    fatalError("Subclasses must override operation()")
  }

  /// Calculates performance for a single runway. Override in subclass.
  func calculatePerformance(
    for _: RunwayInput,
    conditions _: Conditions,
    config _: Configuration
  ) throws -> PerformanceType {
    fatalError("Subclasses must override calculatePerformance(for:conditions:config:)")
  }

  /// Determines maximum weight and limiting factor for a runway. Override in subclass.
  func determineMaxWeight(runway _: RunwayInput) throws -> (
    Measurement<UnitMass>, LimitingFactor
  ) {
    fatalError("Subclasses must override determineMaxWeight(runway:)")
  }

  /// Creates a typed scenario from runway results. Override in subclass.
  func createScenario(name _: String, runways _: [RunwayInput: PerformanceType]) -> ScenarioType {
    fatalError("Subclasses must override createScenario(name:runways:)")
  }

  /// Returns the maximum allowable weight. Override in subclass.
  func maxWeight() -> Measurement<UnitMass> {
    fatalError("Subclasses must override maxWeight()")
  }

  // MARK: - Common Implementation

  /// Generates complete report output with runway info and all scenarios.
  func generate() throws -> ReportOutput<ScenarioType> {
    let runways = try generateRunwayInfo()
    let scenarios = try generateScenarios()

    return .init(runwayInfo: runways, scenarios: scenarios)
  }

  /// Generates max weight analysis for all runways.
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

  /// Generates performance calculations for all scenarios.
  func generateScenarios() throws -> [ScenarioType] {
    try scenarios.map { scenarioDef in
      let runways = try calculatePerformanceForAllRunways(scenario: scenarioDef)
      return createScenario(name: scenarioDef.name, runways: runways)
    }
  }

  /// Calculates performance for all runways under a given scenario.
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

  /**
   * Performs binary search to find maximum valid weight.
   *
   * - Parameters:
   *   - min: Minimum weight to consider.
   *   - max: Maximum weight to consider.
   *   - increment: Weight increment for search (default 50 lbs).
   *   - isValid: Closure that tests if a weight is valid and returns limiting factor.
   * - Returns: Tuple of maximum valid weight and limiting factor.
   */
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
