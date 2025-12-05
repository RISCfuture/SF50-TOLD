import Defaults
import Foundation

/// Protocol for services that calculate aircraft takeoff and landing performance.
///
/// Implementations of ``PerformanceCalculationService`` take a configured
/// ``PerformanceModel`` and compute the resulting distances, speeds, and climb
/// performance with optional safety factors applied.
public protocol PerformanceCalculationService: Sendable {
  /**
   * Calculates takeoff performance for the given model.
   *
   * - Parameters:
   *   - model: The performance model configured with conditions, configuration, and runway.
   *   - safetyFactor: A multiplier applied to distance results (e.g., 1.15 for 15% safety margin).
   * - Returns: Takeoff performance results including run, distance, and climb gradient.
   */
  func calculateTakeoff(for model: PerformanceModel, safetyFactor: Double) throws -> TakeoffResults

  /**
   * Calculates landing performance for the given model.
   *
   * - Parameters:
   *   - model: The performance model configured with conditions, configuration, and runway.
   *   - safetyFactor: A multiplier applied to distance results (e.g., 1.15 for 15% safety margin).
   * - Returns: Landing performance results including Vref, run, distance, and go-around capability.
   */
  func calculateLanding(for model: PerformanceModel, safetyFactor: Double) throws -> LandingResults
}

extension Value where T == Double {
  fileprivate func toMeasurement<U: Dimension>(_ unit: U) -> Value<Measurement<U>> {
    self.map { value, uncertainty in
      (
        Measurement(value: value, unit: unit),
        uncertainty.map { Measurement(value: $0, unit: unit) }
      )
    }
  }
}

/// Results of a takeoff performance calculation.
///
/// ``TakeoffResults`` contains the computed takeoff distances and climb performance
/// for a given set of conditions. All values are wrapped in ``Value`` to handle
/// uncertainty and error states.
///
/// ## Topics
///
/// ### Distances
/// - ``takeoffRun``
/// - ``takeoffDistance``
///
/// ### Climb Performance
/// - ``takeoffClimbGradient``
/// - ``takeoffClimbRate``
public struct TakeoffResults {
  /// Ground run distance from brake release to liftoff.
  public let takeoffRun: Value<Measurement<UnitLength>>

  /// Total distance from brake release to 35 feet AGL.
  public let takeoffDistance: Value<Measurement<UnitLength>>

  /// Climb gradient in feet per nautical mile at Vx.
  public let takeoffClimbGradient: Value<Measurement<UnitSlope>>

  /// Climb rate in feet per minute at Vx.
  public let takeoffClimbRate: Value<Measurement<UnitSpeed>>
}

/// Results of a landing performance calculation.
///
/// ``LandingResults`` contains the computed landing distances, reference speed,
/// and go-around capability for a given set of conditions.
///
/// ## Topics
///
/// ### Speeds
/// - ``Vref``
///
/// ### Distances
/// - ``landingRun``
/// - ``landingDistance``
///
/// ### Go-Around Performance
/// - ``meetsGoAroundClimbGradient``
public struct LandingResults {
  /// Reference approach speed for the landing configuration.
  public let Vref: Value<Measurement<UnitSpeed>>

  /// Ground run distance from touchdown to stop.
  public let landingRun: Value<Measurement<UnitLength>>

  /// Total distance from 50 feet AGL to full stop.
  public let landingDistance: Value<Measurement<UnitLength>>

  /// Whether the aircraft can achieve the required go-around climb gradient.
  public let meetsGoAroundClimbGradient: Value<Bool>
}

/// Default implementation of ``PerformanceCalculationService``.
///
/// ``DefaultPerformanceCalculationService`` is a singleton service that creates
/// performance models and calculates takeoff/landing results. It selects the
/// appropriate performance model implementation based on aircraft generation
/// and user preferences.
///
/// ## Topics
///
/// ### Singleton Access
/// - ``shared``
///
/// ### Creating Models
/// - ``createPerformanceModel(conditions:configuration:runway:notam:useRegressionModel:aircraftType:)``
///
/// ### Calculating Performance
/// - ``calculateTakeoff(for:safetyFactor:)``
/// - ``calculateLanding(for:safetyFactor:)``
public final class DefaultPerformanceCalculationService: PerformanceCalculationService,
  @unchecked Sendable
{
  /// Shared singleton instance.
  public static let shared = DefaultPerformanceCalculationService()

  private init() {}

  /**
   * Creates a performance model appropriate for the aircraft type and preferences.
   *
   * - Parameters:
   *   - conditions: Atmospheric conditions (temperature, pressure, wind).
   *   - configuration: Aircraft configuration (weight, flaps).
   *   - runway: Runway data snapshot.
   *   - notam: Active NOTAM data if present.
   *   - useRegressionModel: Whether to use regression model (more accurate) vs tabular.
   *   - aircraftType: The user's configured aircraft type.
   * - Returns: A configured performance model ready for calculation.
   */
  public func createPerformanceModel(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMInput?,
    useRegressionModel: Bool,
    aircraftType: AircraftType
  ) -> PerformanceModel {
    if useRegressionModel {
      if aircraftType.usesUpdatedThrustSchedule {
        return RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: runway,
          notam: notam,
          aircraftType: aircraftType
        )
      }
      return RegressionPerformanceModelG1(
        conditions: conditions,
        configuration: configuration,
        runway: runway,
        notam: notam,
        aircraftType: aircraftType
      )
    }
    if aircraftType.usesUpdatedThrustSchedule {
      return TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: configuration,
        runway: runway,
        notam: notam,
        aircraftType: aircraftType
      )
    }
    return TabularPerformanceModelG1(
      conditions: conditions,
      configuration: configuration,
      runway: runway,
      notam: notam,
      aircraftType: aircraftType
    )
  }

  public func calculateTakeoff(for model: PerformanceModel, safetyFactor: Double) throws
    -> TakeoffResults
  {
    let takeoffRun = (model.takeoffRunFt * safetyFactor).toMeasurement(UnitLength.feet)
    let takeoffDistance = (model.takeoffDistanceFt * safetyFactor).toMeasurement(UnitLength.feet)
    let takeoffClimbGradient = model.takeoffClimbGradientFtNmi.toMeasurement(
      UnitSlope.feetPerNauticalMile
    )
    let takeoffClimbRate = model.takeoffClimbRateFtMin.toMeasurement(UnitSpeed.feetPerMinute)

    return TakeoffResults(
      takeoffRun: takeoffRun,
      takeoffDistance: takeoffDistance,
      takeoffClimbGradient: takeoffClimbGradient,
      takeoffClimbRate: takeoffClimbRate
    )
  }

  public func calculateLanding(for model: PerformanceModel, safetyFactor: Double) throws
    -> LandingResults
  {
    let landingRun = (model.landingRunFt * safetyFactor).toMeasurement(UnitLength.feet)
    let landingDistance = (model.landingDistanceFt * safetyFactor).toMeasurement(
      UnitLength.feet
    )
    let Vref = model.VrefKts.toMeasurement(UnitSpeed.knots)
    let meetsGoAroundClimbGradient = model.meetsGoAroundClimbGradient

    return LandingResults(
      Vref: Vref,
      landingRun: landingRun,
      landingDistance: landingDistance,
      meetsGoAroundClimbGradient: meetsGoAroundClimbGradient
    )
  }
}
