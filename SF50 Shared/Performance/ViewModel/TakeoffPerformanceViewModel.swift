import Defaults
import Foundation
import Observation
import SwiftData

@Observable
@MainActor
public final class TakeoffPerformanceViewModel: WithIdentifiableError {
  private let context: ModelContext
  private var model: PerformanceModel?
  private var cancellables: Set<Task<Void, Never>> = []
  private let calculationService: PerformanceCalculationService

  // MARK: Inputs

  public private(set) var flapSetting: FlapSetting {
    didSet {
      model = initializeModel()
      Task { recalculate() }
    }
  }
  public private(set) var weight: Measurement<UnitMass> {
    didSet {
      model = initializeModel()
      Task { recalculate() }
    }
  }
  public private(set) var airport: Airport?
  public private(set) var runway: Runway? {
    didSet {
      model = initializeModel()
      Task { recalculate() }
    }
  }
  public var conditions: Conditions {
    didSet {
      model = initializeModel()
      Task { recalculate() }
    }
  }

  // MARK: Outputs

  public private(set) var takeoffRun: Value<Measurement<UnitLength>>
  public private(set) var takeoffDistance: Value<Measurement<UnitLength>>
  public private(set) var takeoffClimbGradient: Value<Measurement<UnitSlope>>
  public private(set) var takeoffClimbRate: Value<Measurement<UnitSpeed>>
  public var error: Error?

  // MARK: Computed Properties

  private var configuration: Configuration {
    .init(weight: weight, flapSetting: flapSetting)
  }

  public var notam: NOTAM? { runway?.notam }

  public var NOTAMCount: Int {
    var count = 0
    if notam?.contamination != nil { count += 1 }
    if notam?.takeoffDistanceShortening != nil { count += 1 }
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

  // MARK: Initializers

  public init(
    container: ModelContainer,
    calculationService: PerformanceCalculationService = DefaultPerformanceCalculationService.shared
  ) {
    context = .init(container)
    self.calculationService = calculationService

    // temporary values, overwritten by recalculate()
    model = nil
    flapSetting = .flaps50
    weight = .init(value: 3550, unit: .pounds)
    runway = nil
    conditions = .init()

    takeoffRun = .notAvailable
    takeoffDistance = .notAvailable
    takeoffClimbGradient = .notAvailable
    takeoffClimbRate = .notAvailable

    model = initializeModel()
    Task { recalculate() }

    setupObservation()
  }

  // MARK: Functions

  private func setupObservation() {
    addTask(
      Task {
        for await (airportID, runwayID) in Defaults.updates(.takeoffAirport, .takeoffRunway)
        where !Task.isCancelled {
          do {
            let (airport, runway) = try findAirportAndRunway(
              airportID: airportID,
              runwayID: runwayID,
              in: context
            )
            if airport == nil { Defaults[.takeoffAirport] = nil }
            if runway == nil { Defaults[.takeoffRunway] = nil }
            self.airport = airport
            self.runway = runway
          } catch {
            self.error = error
          }
        }
      }
    )

    addTask(
      Task {
        for await (emptyWeight, fuelDensity, payload, takeoffFuel) in Defaults.updates(
          .emptyWeight,
          .fuelDensity,
          .payload,
          .takeoffFuel
        ) where !Task.isCancelled {
          weight = emptyWeight + payload + takeoffFuel * fuelDensity
        }
      }
    )

    addTask(
      Task {
        for await _
          in Defaults
          .updates(.updatedThrustSchedule, .useRegressionModel) where !Task.isCancelled
        {
          model = initializeModel()
          recalculate()
        }
      }
    )

    addTask(
      Task {
        for await _ in Defaults.updates(.safetyFactor) where !Task.isCancelled {
          recalculate()
        }
      }
    )
  }

  private func addTask(_ task: Task<Void, Never>) {
    cancellables.insert(task)
  }

  private func initializeModel() -> (any PerformanceModel)? {
    guard let runway, let airport else { return nil }

    let runwaySnapshot = RunwayInput(from: runway, airport: airport)
    let notamSnapshot = notam.map { NOTAMSnapshot(from: $0) }

    return if Defaults[.useRegressionModel] {
      if Defaults[.updatedThrustSchedule] {
        RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamSnapshot
        )
      } else {
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamSnapshot
        )
      }
    } else {
      if Defaults[.updatedThrustSchedule] {
        TabularPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamSnapshot
        )
      } else {
        TabularPerformanceModelG1(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamSnapshot
        )
      }
    }
  }

  private func recalculate() {
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
