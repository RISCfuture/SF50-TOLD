import Defaults
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
public final class TakeoffPerformanceViewModel: BasePerformanceViewModel {
  // MARK: Outputs

  public private(set) var takeoffRun: Value<Measurement<UnitLength>>
  public private(set) var takeoffDistance: Value<Measurement<UnitLength>>
  public private(set) var takeoffClimbGradient: Value<Measurement<UnitSlope>>
  public private(set) var takeoffClimbRate: Value<Measurement<UnitSpeed>>

  // MARK: Computed Properties

  public var NOTAMCount: Int {
    guard let notam, !notam.isEmpty else { return 0 }
    var count = 0
    if notam.contamination != nil { count += 1 }
    if notam.takeoffDistanceShortening.value > 0 { count += 1 }
    if notam.obstacleHeight.value > 0 || notam.obstacleDistance.value > 0 { count += 1 }
    return count
  }

  public var requiredClimbGradient: Measurement<UnitSlope>? {
    guard case .value(let takeoffRun) = takeoffRun,
      let availableTakeoffRun,
      let obstacleHeight = runway?.notam?.obstacleHeight,
      let obstacleDistance = runway?.notam?.obstacleDistance
    else { return nil }

    let distanceFromRunwayStart = obstacleDistance + availableTakeoffRun
    let distanceFromLiftoffPoint = distanceFromRunwayStart - takeoffRun

    let slope = (obstacleHeight / distanceFromLiftoffPoint)
    return .init(value: slope, unit: .gradient)
  }

  public var offscaleLow: Bool {
    return takeoffRun == .offscaleLow || takeoffDistance == .offscaleLow
      || takeoffClimbRate == .offscaleLow || takeoffClimbRate == .offscaleLow
  }

  public var offscaleHigh: Bool {
    return takeoffRun == .offscaleHigh || takeoffDistance == .offscaleHigh
      || takeoffClimbRate == .offscaleHigh || takeoffClimbRate == .offscaleHigh
  }

  public var availableTakeoffRun: Measurement<UnitLength>? { runway?.notamedTakeoffRun }
  public var availableTakeoffDistance: Measurement<UnitLength>? { runway?.notamedTakeoffDistance }

  // MARK: Overrides

  override public var airportDefaultsKey: Defaults.Key<String?> { .takeoffAirport }
  override public var runwayDefaultsKey: Defaults.Key<String?> { .takeoffRunway }
  override public var fuelDefaultsKey: Defaults.Key<Measurement<UnitVolume>> { .takeoffFuel }
  override public var defaultFlapSetting: FlapSetting { .flaps50 }

  // MARK: Initializers

  public init(
    container: ModelContainer,
    calculationService: PerformanceCalculationService = DefaultPerformanceCalculationService.shared
  ) {
    takeoffRun = .notAvailable
    takeoffDistance = .notAvailable
    takeoffClimbGradient = .notAvailable
    takeoffClimbRate = .notAvailable

    super.init(
      container: container,
      calculationService: calculationService,
      defaultFlapSetting: .flaps50
    )
  }

  // MARK: Calculation

  override public func recalculate() {
    guard let model else {
      takeoffRun = .notAvailable
      takeoffDistance = .notAvailable
      takeoffClimbGradient = .notAvailable
      takeoffClimbRate = .notAvailable
      return
    }

    do {
      let safetyFactor = Defaults[.safetyFactor]
      let results = try calculationService.calculateTakeoff(
        for: model,
        safetyFactor: safetyFactor
      )
      takeoffRun = results.takeoffRun
      takeoffDistance = results.takeoffDistance
      takeoffClimbGradient = results.takeoffClimbGradient
      takeoffClimbRate = results.takeoffClimbRate
    } catch {
      // Handle calculation errors gracefully
      takeoffRun = .invalid
      takeoffDistance = .invalid
      takeoffClimbGradient = .invalid
      takeoffClimbRate = .invalid
    }
  }
}
