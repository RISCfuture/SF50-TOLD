import Defaults
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
public final class ClimbPerformanceViewModel {
  // MARK: Inputs

  public var fuel: Measurement<UnitVolume> {
    didSet {
      recalculate()
    }
  }

  public var altitude: Measurement<UnitLength> {
    didSet {
      recalculate()
    }
  }

  public var ISADeviation: Measurement<UnitTemperature> {
    didSet {
      recalculate()
    }
  }

  public var OAT: Measurement<UnitTemperature> {
    // ISA temperature = 15°C - 1.98°C per 1000 ft
    let altitudeFeet = altitude.converted(to: .feet).value
    let ISATemp = 15.0 - (1.98 * altitudeFeet / 1000.0)
    let OATCelsius = ISATemp + ISADeviation.converted(to: .celsius).value
    return Measurement(value: OATCelsius, unit: .celsius)
  }

  public var iceProtection: Bool {
    didSet {
      recalculate()
    }
  }

  // MARK: Outputs

  public private(set) var climbSpeed: Value<Measurement<UnitSpeed>>
  public private(set) var climbRate: Value<Measurement<UnitSpeed>>
  public private(set) var climbGradient: Value<Measurement<UnitSlope>>

  // MARK: Private

  private var model: PerformanceModel?
  private var cancellables: Set<Task<Void, Never>> = []

  // MARK: Initialization

  public init(container _: ModelContainer) {
    // Initialize with defaults
    fuel = Defaults[.takeoffFuel]
    altitude = .init(value: 0, unit: .feet)
    ISADeviation = .init(value: 0, unit: .celsius)  // Standard ISA conditions
    iceProtection = false

    // Initialize outputs
    climbSpeed = .notAvailable
    climbRate = .notAvailable
    climbGradient = .notAvailable

    setupObservation()
    recalculate()
  }

  // MARK: Observation

  private func setupObservation() {
    // Observe takeoff fuel changes (one-way binding)
    cancellables.insert(
      Task {
        for await newFuel in Defaults.updates(.takeoffFuel) where !Task.isCancelled {
          fuel = newFuel
          // recalculate() will be called by fuel's didSet
        }
      }
    )

    // Observe weight-related changes
    cancellables.insert(
      Task {
        for await (_, _, _) in Defaults.updates(
          .emptyWeight,
          .payload,
          .fuelDensity
        ) where !Task.isCancelled {
          recalculate()
        }
      }
    )

    // Observe model type changes
    cancellables.insert(
      Task {
        for await _ in Defaults.updates(.updatedThrustSchedule, .useRegressionModel)
        where !Task.isCancelled {
          recalculate()
        }
      }
    )
  }

  // MARK: Calculation

  private func recalculate() {
    // Calculate weight
    let weight = Defaults[.emptyWeight] + Defaults[.payload] + fuel * Defaults[.fuelDensity]

    // Create configuration
    let configuration = Configuration(
      weight: weight,
      flapSetting: .flapsUp,
      iceProtection: iceProtection
    )

    // Create conditions
    let conditions = Conditions(
      windDirection: nil,
      windSpeed: nil,
      temperature: OAT,
      seaLevelPressure: nil
    )

    // Create a dummy runway input for climb calculations
    // (not used for enroute climb, but required by model initializer)
    let dummyRunway = RunwayInput(
      id: "CLIMB",
      elevation: altitude,
      trueHeading: Measurement(value: 0, unit: UnitAngle.degrees),
      gradient: 0.0,
      length: Measurement(value: 10_000, unit: UnitLength.feet),
      takeoffRun: nil,
      takeoffDistance: Measurement(value: 10_000, unit: UnitLength.feet),
      landingDistance: nil,
      isTurf: false,
      notam: nil,
      airportVariation: Measurement(value: 0, unit: UnitAngle.degrees)
    )

    // Initialize the appropriate model
    if Defaults[.useRegressionModel] {
      if Defaults[.updatedThrustSchedule] {
        let m = RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: dummyRunway,
          notam: nil
        )
        climbSpeed = m.enrouteClimbSpeedKIAS.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.knots),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.knots) }
          )
        }
        climbRate = m.enrouteClimbRateFtMin.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.feetPerMinute),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.feetPerMinute) }
          )
        }
        climbGradient = m.enrouteClimbGradientFtNmi.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSlope.feetPerNauticalMile),
            uncertainty.map { Measurement(value: $0, unit: UnitSlope.feetPerNauticalMile) }
          )
        }
      } else {
        let m = RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: configuration,
          runway: dummyRunway,
          notam: nil
        )
        climbSpeed = m.enrouteClimbSpeedKIAS.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.knots),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.knots) }
          )
        }
        climbRate = m.enrouteClimbRateFtMin.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.feetPerMinute),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.feetPerMinute) }
          )
        }
        climbGradient = m.enrouteClimbGradientFtNmi.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSlope.feetPerNauticalMile),
            uncertainty.map { Measurement(value: $0, unit: UnitSlope.feetPerNauticalMile) }
          )
        }
      }
    } else {
      if Defaults[.updatedThrustSchedule] {
        let m = TabularPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: dummyRunway,
          notam: nil
        )
        climbSpeed = m.enrouteClimbSpeedKIAS.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.knots),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.knots) }
          )
        }
        climbRate = m.enrouteClimbRateFtMin.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.feetPerMinute),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.feetPerMinute) }
          )
        }
        climbGradient = m.enrouteClimbGradientFtNmi.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSlope.feetPerNauticalMile),
            uncertainty.map { Measurement(value: $0, unit: UnitSlope.feetPerNauticalMile) }
          )
        }
      } else {
        let m = TabularPerformanceModelG1(
          conditions: conditions,
          configuration: configuration,
          runway: dummyRunway,
          notam: nil
        )
        climbSpeed = m.enrouteClimbSpeedKIAS.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.knots),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.knots) }
          )
        }
        climbRate = m.enrouteClimbRateFtMin.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSpeed.feetPerMinute),
            uncertainty.map { Measurement(value: $0, unit: UnitSpeed.feetPerMinute) }
          )
        }
        climbGradient = m.enrouteClimbGradientFtNmi.map { value, uncertainty in
          (
            Measurement(value: value, unit: UnitSlope.feetPerNauticalMile),
            uncertainty.map { Measurement(value: $0, unit: UnitSlope.feetPerNauticalMile) }
          )
        }
      }
    }
  }
}
