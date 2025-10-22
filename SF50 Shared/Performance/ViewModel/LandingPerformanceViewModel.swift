import Defaults
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
public final class LandingPerformanceViewModel: BasePerformanceViewModel {
  // MARK: Outputs

  public private(set) var Vref: Value<Measurement<UnitSpeed>>
  public private(set) var landingRun: Value<Measurement<UnitLength>>
  public private(set) var landingDistance: Value<Measurement<UnitLength>>
  public private(set) var meetsGoAroundClimbGradient: Value<Bool>

  // MARK: Computed Properties

  public var NOTAMCount: Int {
    guard let notam, !notam.isEmpty else { return 0 }
    var count = 0
    if notam.contamination != nil { count += 1 }
    if notam.landingDistanceShortening.value > 0 { count += 1 }
    return count
  }

  public var requiredClimbGradient: Measurement<UnitSlope>? {
    guard let availableLandingRun,
      let obstacleHeight = runway?.notam?.obstacleHeight,
      let obstacleDistance = runway?.notam?.obstacleDistance
    else { return nil }

    let distanceFromRunwayStart = obstacleDistance + availableLandingRun

    let slope = (obstacleHeight / distanceFromRunwayStart)
    return .init(value: slope, unit: .gradient)
  }

  public var offscaleLow: Bool {
    // Check if any values are offscale low
    let valuesOffscaleLow =
      Vref == .offscaleLow || landingRun == .offscaleLow || landingDistance == .offscaleLow

    // For regression models, also check if inputs are outside AFM bounds
    if let regressionModel = model as? BaseRegressionPerformanceModel {
      return valuesOffscaleLow || regressionModel.landingInputsOffscaleLow
    }

    return valuesOffscaleLow
  }

  public var offscaleHigh: Bool {
    // Check if any values are offscale high
    let valuesOffscaleHigh =
      Vref == .offscaleHigh || landingRun == .offscaleHigh || landingDistance == .offscaleHigh

    // For regression models, also check if inputs are outside AFM bounds
    if let regressionModel = model as? BaseRegressionPerformanceModel {
      return valuesOffscaleHigh || regressionModel.landingInputsOffscaleHigh
    }

    return valuesOffscaleHigh
  }

  public var availableLandingRun: Measurement<UnitLength>? { runway?.notamedLandingDistance }

  // MARK: Overrides

  override public var airportDefaultsKey: Defaults.Key<String?> { .landingAirport }
  override public var runwayDefaultsKey: Defaults.Key<String?> { .landingRunway }
  override public var fuelDefaultsKey: Defaults.Key<Measurement<UnitVolume>> { .landingFuel }
  override public var defaultFlapSetting: FlapSetting { .flaps100 }

  // MARK: Initializers

  public init(
    container: ModelContainer,
    calculationService: PerformanceCalculationService = DefaultPerformanceCalculationService.shared
  ) {
    Vref = .notAvailable
    landingRun = .notAvailable
    landingDistance = .notAvailable
    meetsGoAroundClimbGradient = .notAvailable

    super.init(
      container: container,
      calculationService: calculationService,
      defaultFlapSetting: .flaps100
    )
  }

  // MARK: Calculation

  override public func recalculate() {
    guard let model else {
      Vref = .notAvailable
      landingRun = .notAvailable
      landingDistance = .notAvailable
      meetsGoAroundClimbGradient = .notAvailable
      return
    }

    do {
      let safetyFactor =
        notam?.contamination != nil ? Defaults[.safetyFactorWet] : Defaults[.safetyFactorDry]
      let results = try calculationService.calculateLanding(
        for: model,
        safetyFactor: safetyFactor
      )
      Vref = results.Vref
      landingRun = results.landingRun
      landingDistance = results.landingDistance
      meetsGoAroundClimbGradient = results.meetsGoAroundClimbGradient
    } catch {
      // Handle calculation errors gracefully
      Vref = .invalid
      landingRun = .invalid
      landingDistance = .invalid
      meetsGoAroundClimbGradient = .invalid
    }
  }
}
