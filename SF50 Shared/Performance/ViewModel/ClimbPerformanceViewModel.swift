import Defaults
import Foundation
import Observation
import SwiftData

/// View model for en route climb performance calculations.
///
/// ``ClimbPerformanceViewModel`` provides reactive climb performance values
/// for planning cruise climbs. Unlike takeoff/landing view models, this
/// calculates en route performance at arbitrary altitudes and temperatures.
///
/// ## Inputs
///
/// - ``fuel`` - Fuel quantity (linked to takeoff fuel by default)
/// - ``altitude`` - Target altitude for climb performance
/// - ``ISADeviation`` - Temperature deviation from standard atmosphere
/// - ``iceProtection`` - Whether ice protection systems are active
///
/// ## Outputs
///
/// - ``climbSpeed`` - Recommended climb speed (KIAS)
/// - ``climbRate`` - Expected climb rate (ft/min)
/// - ``climbGradient`` - Expected climb gradient (ft/nm)
///
/// ## OAT Calculation
///
/// The ``OAT`` property computes outside air temperature from altitude and
/// ISA deviation using the standard lapse rate of 1.98°C per 1000 feet.
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

  /// Approximates TAS from IAS using altitude (pressure ratio)
  public var climbSpeedTAS: Value<Measurement<UnitSpeed>> {
    climbSpeed.map { IAS, uncertainty in
      let altFeet = altitude.converted(to: .feet).value
      // TAS ≈ IAS / sqrt(σ), where σ ≈ (1 - altFeet/145442)^4.255876
      let sigma = pow(1.0 - altFeet / 145442.0, 4.255876)
      let TASMultiplier = 1.0 / sqrt(sigma)
      let TAS = Measurement(value: IAS.value * TASMultiplier, unit: IAS.unit)
      let uncert = uncertainty.map { Measurement(value: $0.value * TASMultiplier, unit: $0.unit) }
      return (TAS, uncert)
    }
  }

  /// Mach number for current climb speed
  public var climbMach: Value<Double> {
    climbSpeedTAS.flatMap { TAS in
      let tempKelvin = OAT.converted(to: .kelvin).value
      let speedOfSound = 38.967854 * sqrt(tempKelvin)
      let TASKnots = TAS.converted(to: .knots).value
      return .value(TASKnots / speedOfSound)
    }
  }

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
    let aircraftType = Defaults.Keys.aircraftType
    if Defaults[.useRegressionModel] {
      if aircraftType.usesUpdatedThrustSchedule {
        let m = RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: dummyRunway,
          notam: nil,
          aircraftType: aircraftType
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
          notam: nil,
          aircraftType: aircraftType
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
      if aircraftType.usesUpdatedThrustSchedule {
        let m = TabularPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: dummyRunway,
          notam: nil,
          aircraftType: aircraftType
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
          notam: nil,
          aircraftType: aircraftType
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
