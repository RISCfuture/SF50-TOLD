import Defaults
import Foundation
import Logging
import Observation
import Sentry
import SwiftData

/// Abstract base class for performance view models.
///
/// ``BasePerformanceViewModel`` provides shared infrastructure for takeoff and landing
/// performance calculations, including:
///
/// - Input observation (airport, runway, weight, conditions)
/// - Model initialization based on user settings
/// - NOTAM fetching and caching
/// - Automatic recalculation when inputs change
///
/// ## Subclassing
///
/// Subclasses must override:
/// - ``airportDefaultsKey`` - Which airport setting to observe
/// - ``runwayDefaultsKey`` - Which runway setting to observe
/// - ``fuelDefaultsKey`` - Which fuel setting to observe
/// - ``defaultFlapSetting`` - Default flap setting for the operation
/// - ``recalculate()`` - Perform the actual performance calculation
///
/// ## Observation
///
/// The view model automatically observes changes to:
/// - Selected airport and runway (from Defaults)
/// - Weight components (empty weight, payload, fuel, density)
/// - Model settings (regression vs tabular, thrust schedule)
/// - Safety factor settings
///
/// ## NOTAM Support
///
/// Downloaded NOTAMs from the FAA API are available via ``downloadedNOTAMs``.
/// Call ``fetchNOTAMs(plannedTime:)`` to load NOTAMs for the current airport.
@Observable
@MainActor
open class BasePerformanceViewModel: WithIdentifiableError {
  // MARK: - Properties

  private static let logger = Logger(label: "codes.tim.SF50-TOLD.BasePerformanceViewModel")

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

  // MARK: - Downloaded NOTAMs

  /// NOTAMs downloaded from the API for the current airport
  public private(set) var downloadedNOTAMs: [NOTAMResponse] = []

  /// Whether NOTAMs are currently being loaded
  public private(set) var isLoadingNOTAMs = false

  /// Whether we have attempted to fetch NOTAMs for the current airport
  public private(set) var hasAttemptedNOTAMFetch = false

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
        for await _ in Defaults.updates(.safetyFactorDry, .safetyFactorWet) where !Task.isCancelled
        {
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
      var lastSnapshot = notam.map { NOTAMInput(from: $0) }
      while !Task.isCancelled {
        try? await Task.sleep(for: .milliseconds(500))

        // Access the current NOTAM (SwiftData should automatically fetch latest)
        let currentSnapshot = notam.map { NOTAMInput(from: $0) }

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

  // MARK: - NOTAM Fetching

  /// Fetches NOTAMs for the current airport from the API
  /// - Parameter plannedTime: The planned time for the flight, used to filter relevant NOTAMs
  public func fetchNOTAMs(plannedTime: Date = Date()) async {
    guard let airport else {
      downloadedNOTAMs = []
      return
    }

    // NOTAM API uses 3-letter identifiers (e.g., FAI) not ICAO codes (e.g., PAFA)
    // Try locationID first, fallback to ICAO_ID if locationID unavailable
    let primaryIdentifier = airport.locationID
    let fallbackIdentifier = airport.ICAO_ID

    // Check cache first
    if let cached = await NOTAMCache.shared.get(for: primaryIdentifier) {
      downloadedNOTAMs = filterNOTAMs(cached, relativeTo: plannedTime)
      hasAttemptedNOTAMFetch = true
      return
    }

    // Fetch from API
    isLoadingNOTAMs = true

    do {
      // Fetch NOTAMs from 7 days before planned time to 30 days after
      let startDate = Calendar.current.date(byAdding: .day, value: -7, to: plannedTime)
      let endDate = Calendar.current.date(byAdding: .day, value: 30, to: plannedTime)

      // Try primary identifier first
      var response = try await NOTAMLoader.shared.fetchNOTAMs(
        for: primaryIdentifier,
        startDate: startDate,
        endDate: endDate
      )

      // If no results and we have a fallback identifier, try that
      if response.data.isEmpty, let fallbackIdentifier, fallbackIdentifier != primaryIdentifier {
        response = try await NOTAMLoader.shared.fetchNOTAMs(
          for: fallbackIdentifier,
          startDate: startDate,
          endDate: endDate
        )
      }

      // Invalidate old cache only after successfully downloading new NOTAMs
      await NOTAMCache.shared.invalidate(for: primaryIdentifier)

      // Cache the new results
      await NOTAMCache.shared.set(response.data, for: primaryIdentifier)

      // Filter for relevant NOTAMs
      downloadedNOTAMs = filterNOTAMs(response.data, relativeTo: plannedTime)

      // Mark that we've attempted to fetch NOTAMs
      hasAttemptedNOTAMFetch = true
    } catch {
      // Log error but don't show to user - NOTAMs are supplementary
      Self.logger.error("Failed to fetch NOTAMs: \(error)")
      downloadedNOTAMs = []
      hasAttemptedNOTAMFetch = true
    }

    isLoadingNOTAMs = false
  }

  /// Filters NOTAMs to show only currently active or upcoming ones
  private func filterNOTAMs(_ notams: [NOTAMResponse], relativeTo date: Date) -> [NOTAMResponse] {
    notams.filter { notam in
      // Include if no end time (permanent) or end time is in the future
      guard let endTime = notam.effectiveEnd else { return true }
      return endTime > date
    }
    .sorted { lhs, rhs in
      // Sort by effective start, earliest first
      lhs.effectiveStart < rhs.effectiveStart
    }
  }

  // MARK: - Model Initialization

  internal func initializeModel() -> (any PerformanceModel)? {
    guard let runway, let airport else { return nil }

    let runwaySnapshot = RunwayInput(from: runway, airport: airport)
    let notamInput = notam.map { NOTAMInput(from: $0) }

    return if Defaults[.useRegressionModel] {
      if Defaults[.updatedThrustSchedule] {
        RegressionPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamInput
        )
      } else {
        RegressionPerformanceModelG1(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamInput
        )
      }
    } else {
      if Defaults[.updatedThrustSchedule] {
        TabularPerformanceModelG2Plus(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamInput
        )
      } else {
        TabularPerformanceModelG1(
          conditions: conditions,
          configuration: configuration,
          runway: runwaySnapshot,
          notam: notamInput
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
