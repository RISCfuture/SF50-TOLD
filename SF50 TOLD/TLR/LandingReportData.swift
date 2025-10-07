import Foundation
import SF50_Shared

class LandingReportData: BaseReportData<LandingRunwayPerformance, LandingPerformanceScenario> {

  // MARK: - Template Method Overrides

  override func operation() -> SF50_Shared.Operation {
    .landing
  }

  override func maxWeight() -> Measurement<UnitMass> {
    LimitationsG2Plus.maxLandingWeight
  }

  override func createScenario(name: String, runways: [RunwayInput: LandingRunwayPerformance])
    -> LandingPerformanceScenario
  {
    LandingPerformanceScenario(scenarioName: name, runways: runways)
  }

  override func calculatePerformance(
    for runway: RunwayInput,
    conditions: Conditions,
    config: Configuration
  ) throws -> LandingRunwayPerformance {
    let perfModel = performance.createPerformanceModel(
      conditions: conditions,
      configuration: config,
      runway: runway,
      notam: runway.notam,
      useRegressionModel: input.useRegressionModel,
      updatedThrustSchedule: input.updatedThrustSchedule
    )
    let results = try performance.calculateLanding(
      for: perfModel,
      safetyFactor: input.safetyFactor
    )

    let landingRun = results.landingRun.map { value, uncertainty in
      (
        PerformanceDistance(distance: value, availableDistance: runway.length),
        uncertainty.map { PerformanceDistance(distance: $0, availableDistance: runway.length) }
      )
    }
    let landingDistance = results.landingDistance.map { value, uncertainty in
      (
        PerformanceDistance(distance: value, availableDistance: runway.length),
        uncertainty.map { PerformanceDistance(distance: $0, availableDistance: runway.length) }
      )
    }

    // Determine if valid based on landing distance and go-around requirement
    let isValid: Bool = {
      if case .value(let valid) = landingDistance.flatMap({ dist in
        results.meetsGoAroundClimbGradient.map { meetsReq in
          dist.margin.converted(to: UnitLength.feet).value >= 0 && meetsReq
        }
      }) {
        return valid
      }
      return false
    }()

    return LandingRunwayPerformance(
      Vref: results.Vref,
      landingRun: landingRun,
      landingDistance: landingDistance,
      meetsGoAroundRequirement: results.meetsGoAroundClimbGradient,
      isValid: isValid
    )
  }

  override func determineMaxWeight(runway: RunwayInput) throws -> (
    Measurement<UnitMass>, LimitingFactor
  ) {
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
      let results = try performance.calculateLanding(
        for: model,
        safetyFactor: input.safetyFactor
      )

      // Check AFM limits
      if case .offscaleHigh = results.landingDistance {
        return (false, .AFM)
      }
      if case .offscaleLow = results.landingDistance {
        return (false, .AFM)
      }
      if case .value(let dist) = results.landingDistance {
        // Check runway length
        if dist > runway.length {
          return (false, .field)
        }
      }

      // Check go-around climb gradient requirement
      if case .value(let meetsReq) = results.meetsGoAroundClimbGradient {
        if !meetsReq {
          return (false, .climb)
        }
      }

      return (true, .AFM)
    }

    return (result.weight, result.limitingFactor ?? .AFM)
  }
}
