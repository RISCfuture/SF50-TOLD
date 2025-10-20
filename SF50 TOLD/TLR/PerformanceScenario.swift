import Foundation
import SF50_Shared
import SwiftData

// MARK: - Performance Scenario

struct PerformanceScenario: Sendable {

  // MARK: - Instance Properties

  let deltaTemperature: Measurement<UnitTemperature>
  let deltaWindSpeed: Measurement<UnitSpeed>
  let deltaWeight: Measurement<UnitMass>
  let flapSettingOverride: FlapSetting?
  let contaminationOverride: Contamination?
  let isDryOverride: Bool  // Special flag to force dry runway (nil contamination)
  let name: String

  // MARK: - Initialization

  init(
    deltaTemperature: Measurement<UnitTemperature> = .init(value: 0, unit: .celsius),
    deltaWindSpeed: Measurement<UnitSpeed> = .init(value: 0, unit: .knots),
    deltaWeight: Measurement<UnitMass> = .init(value: 0, unit: .pounds),
    flapSettingOverride: FlapSetting? = nil,
    contaminationOverride: Contamination? = nil,
    isDryOverride: Bool = false,
    name: String
  ) {
    self.deltaTemperature = deltaTemperature
    self.deltaWindSpeed = deltaWindSpeed
    self.deltaWeight = deltaWeight
    self.flapSettingOverride = flapSettingOverride
    self.contaminationOverride = contaminationOverride
    self.isDryOverride = isDryOverride
    self.name = name
  }

  // MARK: - Type Methods

  /// Converts a Scenario model to a PerformanceScenario struct
  static func from(_ scenario: Scenario) -> Self {
    Self(
      deltaTemperature: scenario.deltaTemperature,
      deltaWindSpeed: scenario.deltaWindSpeed,
      deltaWeight: scenario.deltaWeight,
      flapSettingOverride: scenario.getFlapSettingOverride(),
      contaminationOverride: scenario.getContaminationOverride(),
      isDryOverride: scenario.isDryOverride,
      name: scenario.name
    )
  }

  // MARK: - Instance Methods

  func apply(
    baseConditions: Conditions,
    baseConfiguration: Configuration,
    runway: RunwayInput
  ) -> (Conditions, Configuration, RunwayInput) {
    let adjustedTemp = baseConditions.temperature.map { $0 + deltaTemperature }
    let adjustedWeight = baseConfiguration.weight + deltaWeight
    let adjustedFlaps = flapSettingOverride ?? baseConfiguration.flapSetting

    var adjustedWindDirection = baseConditions.windDirection
    var adjustedWindSpeed = baseConditions.windSpeed.map { $0 + deltaWindSpeed }
    if let speed = adjustedWindSpeed?.value, speed < 0 {
      adjustedWindDirection = adjustedWindDirection?.reciprocal
      adjustedWindSpeed = adjustedWindSpeed?.absoluteValue
    }

    let conditions = Conditions(
      windDirection: adjustedWindDirection,
      windSpeed: adjustedWindSpeed,
      temperature: adjustedTemp,
      seaLevelPressure: baseConditions.seaLevelPressure
    )
    let configuration = Configuration(
      weight: adjustedWeight,
      flapSetting: adjustedFlaps
    )

    // Apply contamination override if present
    let adjustedRunway =
      if let contamination = contaminationOverride {
        runway.withContamination(contamination)
      } else if isDryOverride {
        runway.withContamination(nil)  // Force dry runway
      } else {
        runway
      }

    return (conditions, configuration, adjustedRunway)
  }
}
