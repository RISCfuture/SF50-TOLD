import Defaults
import Foundation
import Observation
import Sentry
import SwiftData

@Observable
@MainActor
public final class LandingPerformanceViewModel: WithIdentifiableError {
  private let context: ModelContext
  private var model: PerformanceModel?
  private var cancellables: Set<Task<Void, Never>> = []
  private let calculationService: PerformanceCalculationService

  // MARK: Inputs

  public var flapSetting: FlapSetting {
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

  public private(set) var Vref: Value<Measurement<UnitSpeed>>
  public private(set) var landingRun: Value<Measurement<UnitLength>>
  public private(set) var landingDistance: Value<Measurement<UnitLength>>
  public private(set) var meetsGoAroundClimbGradient: Value<Bool>
  public var error: Error?

  // MARK: Computed Properties

  private var configuration: Configuration {
    .init(weight: weight, flapSetting: flapSetting)
  }

  public var notam: NOTAM? { runway?.notam }

  public var NOTAMCount: Int {
    var count = 0
    if notam?.contamination != nil { count += 1 }
    if notam?.landingDistanceShortening != nil { count += 1 }
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
    return Vref == .offscaleLow || landingRun == .offscaleLow || landingDistance == .offscaleLow
  }

  public var offscaleHigh: Bool {
    return Vref == .offscaleHigh || landingRun == .offscaleHigh || landingDistance == .offscaleHigh
  }

  public var availableLandingRun: Measurement<UnitLength>? { runway?.notamedLandingDistance }

  // MARK: Initializers

  public init(
    container: ModelContainer,
    calculationService: PerformanceCalculationService = DefaultPerformanceCalculationService.shared
  ) {
    context = .init(container)
    self.calculationService = calculationService

    // temporary values, overwritten by recalculate()
    model = nil
    flapSetting = .flaps100
    weight = .init(value: 3550, unit: .pounds)
    runway = nil
    conditions = .init()

    Vref = .notAvailable
    landingRun = .notAvailable
    landingDistance = .notAvailable
    meetsGoAroundClimbGradient = .notAvailable

    model = initializeModel()
    Task { recalculate() }

    setupObservation()
  }

  // MARK: Functions

  private func setupObservation() {
    addTask(
      Task {
        for await (airportID, runwayID) in Defaults.updates(.landingAirport, .landingRunway)
        where !Task.isCancelled {
          do {
            let (airport, runway) = try findAirportAndRunway(
              airportID: airportID,
              runwayID: runwayID,
              in: context
            )
            if airport == nil { Defaults[.landingAirport] = nil }
            if runway == nil { Defaults[.landingRunway] = nil }
            self.airport = airport
            self.runway = runway
          } catch {
            SentrySDK.capture(error: error)
            self.error = error
          }
        }
      }
    )

    addTask(
      Task {
        for await (emptyWeight, fuelDensity, payload, landingFuel) in Defaults.updates(
          .emptyWeight,
          .fuelDensity,
          .payload,
          .landingFuel
        ) where !Task.isCancelled {
          weight = emptyWeight + payload + landingFuel * fuelDensity
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
      Vref = .notAvailable
      landingRun = .notAvailable
      landingDistance = .notAvailable
      meetsGoAroundClimbGradient = .notAvailable
      return
    }

    do {
      let safetyFactor = Defaults[.safetyFactor]
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
