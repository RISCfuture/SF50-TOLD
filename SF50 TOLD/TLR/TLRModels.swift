import Foundation
import SF50_Shared

// MARK: - Performance Input

/// Contains all inputs needed to calculate takeoff or landing performance.
///
/// ``PerformanceInput`` aggregates aircraft configuration, weather conditions, runway
/// data, and user preferences into a single structure that drives report generation.
/// It's passed to both ``BaseReportData`` for calculations and ``BaseReportTemplate``
/// for rendering.
struct PerformanceInput {
  /// Airport data snapshot for performance calculations.
  let airport: AirportInput

  /// Selected runway for the operation.
  let runway: RunwayInput

  /// Atmospheric conditions (temperature, pressure, wind).
  let conditions: Conditions

  /// Aircraft gross weight for the operation.
  let weight: Measurement<UnitMass>

  /// Flap setting for takeoff or landing.
  let flapSetting: FlapSetting

  /// Safety factor multiplier for distances (e.g., 1.15 for 15%).
  let safetyFactor: Double

  /// Whether to use regression model vs tabular model.
  let useRegressionModel: Bool

  /// Aircraft type (G1, G2, or G2+). Use `aircraftType.usesUpdatedThrustSchedule`
  /// for performance model selection.
  let aircraftType: AircraftType

  /// Aircraft empty weight for max weight calculations.
  let emptyWeight: Measurement<UnitMass>

  /// Date/time for the planned operation.
  let date: Date

  /// Aggregated aircraft info for display.
  var aircraftInfo: AircraftInfo {
    AircraftInfo(
      aircraftType: aircraftType,
      emptyWeight: emptyWeight
    )
  }

  /// Configuration object for performance model calculations.
  var configuration: Configuration {
    Configuration(weight: weight, flapSetting: flapSetting)
  }

  init(
    airport: AirportInput,
    runway: RunwayInput,
    conditions: Conditions,
    weight: Measurement<UnitMass>,
    flapSetting: FlapSetting,
    safetyFactor: Double,
    useRegressionModel: Bool,
    aircraftType: AircraftType,
    emptyWeight: Measurement<UnitMass>,
    date: Date
  ) {
    self.airport = airport
    self.runway = runway
    self.conditions = conditions
    self.weight = weight
    self.flapSetting = flapSetting
    self.safetyFactor = safetyFactor
    self.useRegressionModel = useRegressionModel
    self.aircraftType = aircraftType
    self.emptyWeight = emptyWeight
    self.date = date
  }
}

// MARK: - Limiting Factors

/// Identifies what factor limits maximum takeoff or landing weight.
///
/// ``LimitingFactor`` is used in runway analysis to show pilots why a particular
/// weight limit applies. The raw values are abbreviations shown in the TLR report.
///
/// ## Cases
///
/// - ``AFM``: Limited by Aircraft Flight Manual charts
/// - ``field``: Limited by available runway length
/// - ``obstacle``: Limited by obstacle clearance requirements
/// - ``climb``: Limited by climb gradient requirements
enum LimitingFactor: String, Codable, Sendable {
  case AFM = "AFM"
  case field = "FLD"
  case obstacle = "OBS"
  case climb = "CLB"
}

/// Aircraft identification information for TLR report display.
///
/// ``AircraftInfo`` provides displayable aircraft information derived from
/// configuration settings.
struct AircraftInfo {
  /// The aircraft type (G1, G2, or G2+).
  let aircraftType: AircraftType

  /// Basic empty weight used for max weight calculations.
  let emptyWeight: Measurement<UnitMass>
}

/// Wind information for TLR display. Direction is nil for variable or calm winds.
struct WindInfo {
  /// Wind direction in degrees true (nil for variable/calm).
  let direction: Measurement<UnitAngle>?

  /// Wind speed.
  let speed: Measurement<UnitSpeed>
}

/// Runway analysis results showing weight limits.
///
/// ``RunwayInfo`` captures the maximum weight that can be used for a runway
/// along with what factor limits that weight.
struct RunwayInfo: Sendable {
  /// Maximum allowable weight for this runway under current conditions.
  let maxWeight: Measurement<UnitMass>

  /// What limits the maximum weight (AFM, field length, obstacle, climb).
  let limitingFactor: LimitingFactor

  /// Current runway contamination from NOTAM, if any.
  let contamination: Contamination?
}

/// A calculated distance with runway margin.
///
/// ``PerformanceDistance`` pairs a calculated performance distance with the
/// available runway distance, allowing margin calculation for display.
struct PerformanceDistance {
  /// The calculated takeoff or landing distance.
  let distance: Measurement<UnitLength>

  /// The available runway distance (TODA, TORA, or LDA).
  let availableDistance: Measurement<UnitLength>

  /// Remaining runway after the calculated distance (positive = good).
  var margin: Measurement<UnitLength> {
    .init(
      value: availableDistance.converted(to: .feet).value - distance.converted(to: .feet).value,
      unit: .feet
    )
  }
}

// MARK: - Takeoff Data Structures

/// Planned takeoff conditions for display in the TLR header.
struct TakeoffData {
  /// Airport identifier.
  let airport: String

  /// Selected runway designator.
  let plannedRunway: String

  /// Outside air temperature.
  let plannedOAT: Measurement<UnitTemperature>

  /// Wind conditions.
  let plannedWind: WindInfo

  /// Altimeter setting.
  let plannedQNH: Measurement<UnitPressure>

  /// Planned takeoff weight.
  let plannedTOW: Measurement<UnitMass>
}

/// Calculated takeoff performance for a single runway.
///
/// Contains ground run, total distance (to 50'), climb gradient, and
/// whether the takeoff is valid (sufficient runway margin).
struct TakeoffRunwayPerformance {
  /// Takeoff ground run distance with margin.
  let groundRun: Value<PerformanceDistance>?

  /// Total takeoff distance to 50' with margin.
  let totalDistance: Value<PerformanceDistance>?

  /// Takeoff climb gradient.
  let climbRate: Value<Measurement<UnitSlope>>?

  /// Whether takeoff is valid (positive margin and meets requirements).
  let isValid: Bool
}

/// A named scenario containing takeoff performance for all runways.
struct TakeoffPerformanceScenario {
  /// Display name for this scenario (e.g., "Planned", "Hot Day").
  let scenarioName: String

  /// Takeoff performance keyed by runway.
  let runways: [RunwayInput: TakeoffRunwayPerformance]
}

// MARK: - Landing Data Structures

/// Planned landing conditions for display in the TLR header.
struct LandingData {
  /// Airport identifier.
  let airport: String

  /// Selected runway designator.
  let plannedRunway: String

  /// Outside air temperature.
  let plannedOAT: Measurement<UnitTemperature>

  /// Wind conditions.
  let plannedWind: WindInfo

  /// Altimeter setting.
  let plannedQNH: Measurement<UnitPressure>

  /// Planned landing weight.
  let plannedLW: Measurement<UnitMass>

  /// Flap configuration description.
  let configuration: String
}

/// Calculated landing performance for a single runway.
///
/// Contains Vref, landing run, landing distance (to 50'), go-around compliance,
/// and whether the landing is valid.
struct LandingRunwayPerformance {
  /// Reference speed for the approach.
  let Vref: Value<Measurement<UnitSpeed>>?

  /// Landing ground run distance with margin.
  let landingRun: Value<PerformanceDistance>?

  /// Total landing distance from 50' with margin.
  let landingDistance: Value<PerformanceDistance>?

  /// Whether the aircraft meets go-around climb gradient requirements.
  let meetsGoAroundRequirement: Value<Bool>?

  /// Whether landing is valid (positive margin and meets requirements).
  let isValid: Bool
}

/// A named scenario containing landing performance for all runways.
struct LandingPerformanceScenario {
  /// Display name for this scenario (e.g., "Planned", "Wet").
  let scenarioName: String

  /// Landing performance keyed by runway.
  let runways: [RunwayInput: LandingRunwayPerformance]
}

// MARK: - Generic Report Output

/// Combined output from report data generation.
///
/// ``ReportOutput`` contains both the runway analysis (max weights and limiting
/// factors) and the scenario-based performance calculations.
struct ReportOutput<ScenarioType> {
  /// Max weight and limiting factor for each runway.
  let runwayInfo: [RunwayInput: RunwayInfo]

  /// Performance calculations for each scenario.
  let scenarios: [ScenarioType]
}

/// Report output specialized for takeoff scenarios.
typealias TakeoffReportOutput = ReportOutput<TakeoffPerformanceScenario>

/// Report output specialized for landing scenarios.
typealias LandingReportOutput = ReportOutput<LandingPerformanceScenario>
