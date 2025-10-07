import Foundation
import SF50_Shared

// MARK: - Performance Input

struct PerformanceInput {
  let airport: AirportInput
  let runway: RunwayInput
  let conditions: Conditions
  let weight: Measurement<UnitMass>
  let flapSetting: FlapSetting
  let safetyFactor: Double
  let useRegressionModel: Bool
  let updatedThrustSchedule: Bool
  let emptyWeight: Measurement<UnitMass>
  let date: Date

  var aircraftInfo: AircraftInfo {
    AircraftInfo(
      updatedThrustSchedule: updatedThrustSchedule,
      emptyWeight: emptyWeight
    )
  }

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
    updatedThrustSchedule: Bool,
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
    self.updatedThrustSchedule = updatedThrustSchedule
    self.emptyWeight = emptyWeight
    self.date = date
  }
}

// MARK: - Limiting Factors

enum LimitingFactor: String, Codable, Sendable {
  case AFM = "AFM"
  case field = "FLD"
  case obstacle = "OBS"
  case climb = "CLB"
}

struct AircraftInfo {
  let updatedThrustSchedule: Bool
  let emptyWeight: Measurement<UnitMass>

  var model: String {
    updatedThrustSchedule ? String(localized: "SF50 G2+") : String(localized: "SF50 G1/G2")
  }
}

struct WindInfo {
  let direction: Measurement<UnitAngle>?  // nil for variable/calm winds
  let speed: Measurement<UnitSpeed>
}

struct RunwayInfo: Sendable {
  let maxWeight: Measurement<UnitMass>
  let limitingFactor: LimitingFactor
  let contamination: Contamination?
}

struct PerformanceDistance {
  let distance: Measurement<UnitLength>
  let availableDistance: Measurement<UnitLength>

  var margin: Measurement<UnitLength> {
    .init(
      value: availableDistance.converted(to: .feet).value - distance.converted(to: .feet).value,
      unit: .feet
    )
  }
}

// MARK: - Takeoff Data Structures

struct TakeoffData {
  let airport: String
  let plannedRunway: String
  let plannedOAT: Measurement<UnitTemperature>
  let plannedWind: WindInfo
  let plannedQNH: Measurement<UnitPressure>
  let plannedTOW: Measurement<UnitMass>
}

struct TakeoffRunwayPerformance {
  let groundRun: Value<PerformanceDistance>?
  let totalDistance: Value<PerformanceDistance>?
  let climbRate: Value<Measurement<UnitSlope>>?
  let isValid: Bool
}

struct TakeoffPerformanceScenario {
  let scenarioName: String
  let runways: [RunwayInput: TakeoffRunwayPerformance]
}

// MARK: - Landing Data Structures

struct LandingData {
  let airport: String
  let plannedRunway: String
  let plannedOAT: Measurement<UnitTemperature>
  let plannedWind: WindInfo
  let plannedQNH: Measurement<UnitPressure>
  let plannedLW: Measurement<UnitMass>
  let configuration: String
}

struct LandingRunwayPerformance {
  let Vref: Value<Measurement<UnitSpeed>>?
  let landingRun: Value<PerformanceDistance>?
  let landingDistance: Value<PerformanceDistance>?
  let meetsGoAroundRequirement: Value<Bool>?
  let isValid: Bool
}

struct LandingPerformanceScenario {
  let scenarioName: String
  let runways: [RunwayInput: LandingRunwayPerformance]
}

// MARK: - Generic Report Output

struct ReportOutput<ScenarioType> {
  let runwayInfo: [RunwayInput: RunwayInfo]
  let scenarios: [ScenarioType]
}

// Type aliases for specific report types
typealias TakeoffReportOutput = ReportOutput<TakeoffPerformanceScenario>
typealias LandingReportOutput = ReportOutput<LandingPerformanceScenario>
