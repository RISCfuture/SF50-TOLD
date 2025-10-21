import Defaults
import Foundation
import Observation
import Sentry
import SwiftData

/// Abstract base class for performance view models (Takeoff and Landing)
@Observable
@MainActor
open class BasePerformanceViewModel: WithIdentifiableError {
  // MARK: - Properties

  internal let context: ModelContext
  internal var model: PerformanceModel?
  private var cancellables: Set<Task<Void, Never>> = []
  private var runwayNOTAMObservationTask: Task<Void, Never>?
  internal let calculationService: PerformanceCalculationService

  // MARK: - Inputs (to be overridden or used by subclasses)

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

      // Set up observation for NOTAM changes on this runway
      setupRunwayNOTAMObservation()
    }
  }

  public var conditions: Conditions {
    didSet {
      model = initializeModel()
      Task { recalculate() }
    }
  }

  public var error: Error?

  // MARK: - Computed Properties

  internal var configuration: Configuration {
    .init(weight: weight, flapSetting: flapSetting)
  }

  public var notam: NOTAM? { runway?.notam }

  // MARK: - Abstract Properties (must be overridden)

  /// The Defaults key for the airport
  open var airportDefaultsKey: Defaults.Key<String?> {
    fatalError("Subclasses must override airportDefaultsKey")
  }

  /// The Defaults key for the runway
  open var runwayDefaultsKey: Defaults.Key<String?> {
    fatalError("Subclasses must override runwayDefaultsKey")
  }

  /// The Defaults key for the fuel amount
  open var fuelDefaultsKey: Defaults.Key<Measurement<UnitVolume>> {
    fatalError("Subclasses must override fuelDefaultsKey")
  }

  /// The default flap setting for this operation
  open var defaultFlapSetting: FlapSetting {
    fatalError("Subclasses must override defaultFlapSetting")
  }

  // MARK: - Initialization

  public init(
    container: ModelContainer,
    calculationService: PerformanceCalculationService = DefaultPerformanceCalculationService.shared,
    defaultFlapSetting: FlapSetting
  ) {
    context = .init(container)
    self.calculationService = calculationService

    // temporary values, overwritten by recalculate()
    model = nil
    flapSetting = defaultFlapSetting
    weight = .init(value: 3550, unit: .pounds)
    runway = nil
    conditions = .init()

    model = initializeModel()
    Task { recalculate() }

    setupObservation()
  }

  // MARK: - Observation Setup

  private func setupObservation() {
    // Observe airport and runway changes
    addTask(
      Task {
        for await (airportID, runwayID) in Defaults.updates(airportDefaultsKey, runwayDefaultsKey)
        where !Task.isCancelled {
          do {
            let (airport, runway) = try findAirportAndRunway(
              airportID: airportID,
              runwayID: runwayID,
              in: context
            )
            if airport == nil { Defaults[airportDefaultsKey] = nil }
            if runway == nil { Defaults[runwayDefaultsKey] = nil }
            self.airport = airport
            self.runway = runway
          } catch {
            SentrySDK.capture(error: error)
            self.error = error
          }
        }
      }
    )

    // Observe weight changes
    addTask(
      Task {
        for await (emptyWeight, fuelDensity, payload, fuel) in Defaults.updates(
          .emptyWeight,
          .fuelDensity,
          .payload,
          fuelDefaultsKey
        ) where !Task.isCancelled {
          weight = emptyWeight + payload + fuel * fuelDensity
        }
      }
    )

    // Observe thrust schedule and model type changes
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

    // Observe safety factor changes
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

  // MARK: - NOTAM Observation

  private func setupRunwayNOTAMObservation() {
    // Cancel any existing observation
    runwayNOTAMObservationTask?.cancel()
    runwayNOTAMObservationTask = nil

    guard runway != nil else { return }

    // Poll for changes to the NOTAM's snapshot
    runwayNOTAMObservationTask = Task { @MainActor in
      var lastSnapshot = notam.map { NOTAMSnapshot(from: $0) }
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(500))

        // Access the current NOTAM (SwiftData should automatically fetch latest)
        let currentSnapshot = notam.map { NOTAMSnapshot(from: $0) }

        // Compare snapshots to detect changes
        if let last = lastSnapshot, let current = currentSnapshot {
          if last != current {
            lastSnapshot = currentSnapshot
            model = initializeModel()
            recalculate()
          }
        } else if lastSnapshot != nil || currentSnapshot != nil {
          // NOTAM added or removed
          lastSnapshot = currentSnapshot
          model = initializeModel()
          recalculate()
        }
      }
    }
  }

  // MARK: - Model Initialization

  internal func initializeModel() -> (any PerformanceModel)? {
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

  // MARK: - Abstract Methods (must be overridden)

  /// Recalculates performance values. Must be overridden by subclasses.
  open func recalculate() {  // swiftlint:disable:this unavailable_function
    fatalError("Subclasses must override recalculate()")
  }
}
