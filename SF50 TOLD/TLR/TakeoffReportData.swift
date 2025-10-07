import Foundation
import SF50_Shared

class TakeoffReportData: BaseReportData<TakeoffRunwayPerformance, TakeoffPerformanceScenario> {

  // MARK: - Template Method Overrides

  override func operation() -> SF50_Shared.Operation {
    .takeoff
  }

  override func maxWeight() -> Measurement<UnitMass> {
    LimitationsG2Plus.maxTakeoffWeight
  }

  override func createScenario(name: String, runways: [RunwayInput: TakeoffRunwayPerformance])
    -> TakeoffPerformanceScenario
  {
    TakeoffPerformanceScenario(scenarioName: name, runways: runways)
  }

  override func calculatePerformance(
    for runway: RunwayInput,
    conditions: Conditions,
    config: Configuration
  ) throws -> TakeoffRunwayPerformance {
    let perfModel = performance.createPerformanceModel(
      conditions: conditions,
      configuration: config,
      runway: runway,
      notam: runway.notam,
      useRegressionModel: input.useRegressionModel,
      updatedThrustSchedule: input.updatedThrustSchedule
    )
    let results = try performance.calculateTakeoff(
      for: perfModel,
      safetyFactor: input.safetyFactor
    )

    let groundRun = results.takeoffRun.map { value, uncertainty in
      (
        PerformanceDistance(distance: value, availableDistance: runway.length),
        uncertainty.map { PerformanceDistance(distance: $0, availableDistance: runway.length) }
      )
    }
    let totalDistance = results.takeoffDistance.map { value, uncertainty in
      (
        PerformanceDistance(distance: value, availableDistance: runway.length),
        uncertainty.map { PerformanceDistance(distance: $0, availableDistance: runway.length) }
      )
    }
    let climbRate = results.takeoffClimbGradient

    // Determine if valid based on total distance
    let isValid: Bool = {
      switch totalDistance {
        case .value(let dist), .valueWithUncertainty(let dist, _):
          return dist.margin.converted(to: UnitLength.feet).value >= 0
        default:
          return false
      }
    }()

    return TakeoffRunwayPerformance(
      groundRun: groundRun,
      totalDistance: totalDistance,
      climbRate: climbRate,
      isValid: isValid
    )
  }

  override func determineMaxWeight(runway: RunwayInput) throws -> (
    Measurement<UnitMass>, LimitingFactor
  ) {
    let runwayLength = runway.length.converted(to: .feet).value

    let result = try binarySearchMaxWeight(
      runway: runway,
      min: input.emptyWeight,
      max: maxWeight()
    ) { weight -> (valid: Bool, factor: LimitingFactor) in
      let config = Configuration(
        weight: weight,
        flapSetting: input.flapSetting
      )

      let model = performance.createPerformanceModel(
        conditions: input.conditions,
        configuration: config,
        runway: runway,
        notam: runway.notam,
        useRegressionModel: input.useRegressionModel,
        updatedThrustSchedule: input.updatedThrustSchedule
      )
      let results = try performance.calculateTakeoff(
        for: model,
        safetyFactor: input.safetyFactor
      )

      // Check AFM limits
      if case .offscaleHigh = results.takeoffDistance {
        return (false, .AFM)
      }
      if case .offscaleLow = results.takeoffDistance {
        return (false, .AFM)
      }
      if case .value(let dist) = results.takeoffDistance {
        // Check runway length
        if dist.converted(to: .feet).value > runwayLength {
          return (false, .field)
        }
      }

      // Check obstacle clearance if NOTAM present
      if let obstacleHeight = runway.notam?.obstacleHeight,
        let obstacleDistance = runway.notam?.obstacleDistance,
        case .value(let takeoffRun) = results.takeoffRun
      {
        let distanceFromRunwayStart =
          obstacleDistance.converted(to: .feet).value
          + (runway.notam?.takeoffDistanceShortening.converted(to: .feet).value ?? 0)
        let distanceFromLiftoff = distanceFromRunwayStart - takeoffRun.converted(to: .feet).value

        if distanceFromLiftoff > 0 {
          let requiredGradient = obstacleHeight.converted(to: .feet).value / distanceFromLiftoff

          if case .value(let climbGradient) = results.takeoffClimbGradient {
            let actualGradient =
              climbGradient.converted(to: .feetPerNauticalMile).value / 6076.12
            if actualGradient < requiredGradient {
              return (false, .obstacle)
            }
          }
        }
      }

      return (true, .AFM)
    }

    return (result.weight, result.limitingFactor ?? .AFM)
  }
}
