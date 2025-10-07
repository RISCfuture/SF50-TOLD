import Foundation
import SF50_Shared

// MARK: - Performance Scenario

struct PerformanceScenario: Sendable {
  // MARK: - Default Scenarios

  static let defaultTakeoffScenarios: [Self] = [
    .init(),  // Forecast Conditions
    .init(deltaTemperature: .init(value: 10, unit: .celsius)),
    .init(deltaTemperature: .init(value: -10, unit: .celsius)),
    .init(deltaWindSpeed: .init(value: 10, unit: .knots)),
    .init(deltaWindSpeed: .init(value: -10, unit: .knots)),
    .init(deltaWeight: .init(value: 200, unit: .pounds)),
    .init(deltaWeight: .init(value: -200, unit: .pounds))
  ]

  static let defaultLandingScenarios: [Self] = [
    .init(),  // Forecast Conditions
    .init(deltaTemperature: .init(value: 10, unit: .celsius)),
    .init(deltaTemperature: .init(value: -10, unit: .celsius)),
    .init(deltaWindSpeed: .init(value: 10, unit: .knots)),
    .init(deltaWindSpeed: .init(value: -10, unit: .knots)),
    .init(deltaWeight: .init(value: 200, unit: .pounds)),
    .init(deltaWeight: .init(value: -200, unit: .pounds)),
    .init(flapSettingOverride: .flaps50)  // Flaps 50
  ]

  // MARK: - Instance Properties

  let deltaTemperature: Measurement<UnitTemperature>
  let deltaWindSpeed: Measurement<UnitSpeed>
  let deltaWeight: Measurement<UnitMass>
  let flapSettingOverride: FlapSetting?
  let contaminationOverride: Contamination?
  let isDryOverride: Bool  // Special flag to force dry runway (nil contamination)

  var name: String {
    var components: [String] = []

    if !deltaTemperature.converted(to: .celsius).value.isZero {
      components.append(
        String(
          localized: "OAT \(deltaTemperature.asTemperature, format: .temperature(plusSign: true))"
        )
      )
    }

    if !deltaWindSpeed.value.isZero {
      components.append(
        String(localized: "Wind Speed \(deltaWindSpeed.asSpeed, format: .speed(plusSign: true))")
      )
    }

    if !deltaWeight.value.isZero {
      components.append(
        String(localized: "Weight \(deltaWeight.asWeight, format: .weight(plusSign: true))")
      )
    }

    if let flaps = flapSettingOverride {
      components.append(format(flapSetting: flaps))
    }

    if let contamination = contaminationOverride {
      switch contamination {
        case .waterOrSlush(let depth):
          components.append(
            String(localized: "Water/Slush \(depth.asDepth, format: .depth)")
          )
        case .slushOrWetSnow(let depth):
          components.append(
            String(localized: "Slush/Wet Snow \(depth.asDepth, format: .depth)")
          )
        case .drySnow:
          components.append(String(localized: "Dry Snow"))
        case .compactSnow:
          components.append(String(localized: "Compact Snow"))
      }
    }

    if isDryOverride {
      components.append(String(localized: "Dry"))
    }

    if components.isEmpty {
      return String(localized: "Forecast Conditions")
    }

    return components.formatted(.list(type: .and))
  }

  // MARK: - Initialization

  init(
    deltaTemperature: Measurement<UnitTemperature> = .init(value: 0, unit: .celsius),
    deltaWindSpeed: Measurement<UnitSpeed> = .init(value: 0, unit: .knots),
    deltaWeight: Measurement<UnitMass> = .init(value: 0, unit: .pounds),
    flapSettingOverride: FlapSetting? = nil,
    contaminationOverride: Contamination? = nil,
    isDryOverride: Bool = false
  ) {
    self.deltaTemperature = deltaTemperature
    self.deltaWindSpeed = deltaWindSpeed
    self.deltaWeight = deltaWeight
    self.flapSettingOverride = flapSettingOverride
    self.contaminationOverride = contaminationOverride
    self.isDryOverride = isDryOverride
  }

  // MARK: - Type Methods

  static func scenarios(for input: PerformanceInput, operation: SF50_Shared.Operation)
    -> [Self]
  {
    switch operation {
      case .landing:
        var scenarios = defaultLandingScenarios

        // When OAT is 10°C or below, add conditional contamination scenarios
        if let temp = input.conditions.temperature,
          temp.converted(to: .celsius).value <= 10.0
        {

          // Get current contamination for each runway
          let currentContaminations = Set(
            input.airport.runways.compactMap { $0.notam?.contamination }
          )

          // Add "Dry" scenario if any runway has contamination
          if !currentContaminations.isEmpty {
            scenarios.append(.init(isDryOverride: true))
          }

          // Add 0.5" water/slush scenario if not currently included
          let hasWaterSlush = currentContaminations.contains { contamination in
            if case .waterOrSlush = contamination { return true }
            return false
          }
          if !hasWaterSlush {
            scenarios.append(
              .init(
                contaminationOverride: .waterOrSlush(depth: .init(value: 0.5, unit: .inches))
              )
            )
          }

          // Add 0.5" slush/wet snow scenario if not currently included
          let hasSlushWetSnow = currentContaminations.contains { contamination in
            if case .slushOrWetSnow = contamination { return true }
            return false
          }
          if !hasSlushWetSnow {
            scenarios.append(
              .init(
                contaminationOverride: .slushOrWetSnow(depth: .init(value: 0.5, unit: .inches))
              )
            )
          }

          // Add dry snow scenario if not currently included
          let hasDrySnow = currentContaminations.contains { contamination in
            if case .drySnow = contamination { return true }
            return false
          }
          if !hasDrySnow {
            scenarios.append(.init(contaminationOverride: .drySnow))
          }

          // Add compact snow scenario if not currently included
          let hasCompactSnow = currentContaminations.contains { contamination in
            if case .compactSnow = contamination { return true }
            return false
          }
          if !hasCompactSnow {
            scenarios.append(.init(contaminationOverride: .compactSnow))
          }
        }

        return scenarios
      case .takeoff:
        return defaultTakeoffScenarios
    }
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
