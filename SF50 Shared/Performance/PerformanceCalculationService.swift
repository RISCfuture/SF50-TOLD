import Defaults
import Foundation

public protocol PerformanceCalculationService: Sendable {
  func calculateTakeoff(for model: PerformanceModel, safetyFactor: Double) throws -> TakeoffResults
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

public struct TakeoffResults {
  public let takeoffRun: Value<Measurement<UnitLength>>
  public let takeoffDistance: Value<Measurement<UnitLength>>
  public let takeoffClimbGradient: Value<Measurement<UnitSlope>>
  public let takeoffClimbRate: Value<Measurement<UnitSpeed>>
}

public struct LandingResults {
  public let Vref: Value<Measurement<UnitSpeed>>
  public let landingRun: Value<Measurement<UnitLength>>
  public let landingDistance: Value<Measurement<UnitLength>>
  public let meetsGoAroundClimbGradient: Value<Bool>
}

public final class DefaultPerformanceCalculationService: PerformanceCalculationService,
  @unchecked Sendable
{
  public static let shared = DefaultPerformanceCalculationService()

  private init() {}

  public func createPerformanceModel(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMSnapshot?,
    useRegressionModel: Bool,
    updatedThrustSchedule: Bool
  ) -> PerformanceModel {
    if useRegressionModel {
      if updatedThrustSchedule {
        return RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: runway,
          notam: notam
        )
      }
      return RegressionPerformanceModelG1(
        conditions: conditions,
        configuration: configuration,
        runway: runway,
        notam: notam
      )
    }
    if updatedThrustSchedule {
      return TabularPerformanceModelG2Plus(
        conditions: conditions,
        configuration: configuration,
        runway: runway,
        notam: notam
      )
    }
    return TabularPerformanceModelG1(
      conditions: conditions,
      configuration: configuration,
      runway: runway,
      notam: notam
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
