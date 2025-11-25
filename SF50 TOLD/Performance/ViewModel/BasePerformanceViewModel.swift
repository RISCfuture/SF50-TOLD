import SF50_Shared
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

  /// Tracks the previous airport ICAO for detecting changes
  private var previousAirportICAO: String?

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

  /// NOTAMs downloaded from API for current airport/runway
  public private(set) var downloadedNOTAMs: [NOTAMResponse] = []

  /// Loading state for NOTAM network request
  public private(set) var isLoadingNOTAMs = false

  /// Loading state for NOTAM intelligence parsing
  public private(set) var isParsingNOTAMs = false

  /// Whether NOTAMs have been fetched at least once for the current airport
  public private(set) var hasAttemptedNOTAMFetch = false

  // MARK: - Computed Properties

  internal var configuration: Configuration {
    .init(weight: weight, flapSetting: flapSetting)
  }

  public var notam: NOTAM? { runway?.notam }

  // MARK: - Abstract Properties (must be overridden)

  /// The operation type (takeoff or landing)
  open var operation: SF50_Shared.Operation {
    fatalError("Subclasses must override operation")
  }

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

            // Track airport changes for cache invalidation
            let newICAO = airport?.ICAO_ID ?? airport?.locationID
            if let newICAO, newICAO != self.previousAirportICAO {
              self.previousAirportICAO = newICAO
              // Reset fetch flag when airport changes
              self.hasAttemptedNOTAMFetch = false
              // Cache will be invalidated in fetchNOTAMs after successful download
            }
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

    // Also fetch NOTAMs from API (will be called by view with planned time)
  }

  /// Fetches NOTAMs from the API for the current airport/runway.
  ///
  /// - Parameter plannedTime: The planned departure/arrival time to filter NOTAMs
  @MainActor
  public func fetchNOTAMs(plannedTime: Date = Date()) async {
    guard let airport else {
      downloadedNOTAMs = []
      return
    }

    // NOTAM API uses 3-letter identifiers (e.g., FAI) not ICAO codes (e.g., PAFA)
    // Try locationID first, fallback to ICAO_ID if locationID unavailable
    let primaryIdentifier = airport.locationID
    let fallbackIdentifier = airport.ICAO_ID

    // Check cache first - try both identifiers
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

      // Clear loading state BEFORE starting parsing to ensure states are mutually exclusive
      isLoadingNOTAMs = false

      // Parse and auto-create NOTAM if needed
      await parseAndCreateNOTAMIfNeeded()
    } catch {
      // Log error but don't show to user (non-critical feature)
      SentrySDK.capture(error: error)
      downloadedNOTAMs = []
      hasAttemptedNOTAMFetch = true
      isLoadingNOTAMs = false
    }
  }

  /// Parses downloaded NOTAMs and creates/updates runway NOTAM if user hasn't manually configured one.
  @MainActor
  private func parseAndCreateNOTAMIfNeeded() async {
    guard let runway, !downloadedNOTAMs.isEmpty else { return }

    // Skip if user has manually edited the NOTAM AND it's not empty
    // Empty user-edited NOTAMs can be auto-filled
    if let existingNOTAM = runway.notam, existingNOTAM.isManuallyEdited && !existingNOTAM.isEmpty {
      return
    }

    // Parse NOTAMs using AI/keyword matching
    if #available(iOS 18.2, macOS 15.2, *) {
      isParsingNOTAMs = true
      defer { isParsingNOTAMs = false }

      do {
        let parser = NOTAMParser.shared
        if let parsed = try await parser.parse(notams: downloadedNOTAMs, for: runway.name) {
          // Create or update NOTAM, filtering by operation type
          if let existingNOTAM = runway.notam {
            // Update existing auto-created NOTAM
            parsed.apply(to: existingNOTAM, for: operation, appendSource: false)
            existingNOTAM.automaticallyCreated = true
          } else {
            // Create new NOTAM
            let newNOTAM = parsed.createNOTAM(for: runway, operation: operation)
            runway.notam = newNOTAM
            context.insert(newNOTAM)
          }

          // Save changes
          try context.save()
        }
      } catch {
        // Log parsing errors but don't show to user
        SentrySDK.capture(error: error)
      }
    }
  }

  /// Manually applies auto-fill, overriding user-edit protection.
  /// This is called when the user explicitly taps the "Auto-fill from downloaded NOTAMs?" button.
  @MainActor
  public func applyAutoFillNOTAM() async {
    guard let runway else { return }
    guard !downloadedNOTAMs.isEmpty else { return }

    // Parse NOTAMs using AI/keyword matching
    do {
      let parser = NOTAMParser.shared
      if let parsed = try await parser.parse(notams: downloadedNOTAMs, for: runway.name) {
        // Create or update NOTAM, filtering by operation type
        if let existingNOTAM = runway.notam {
          // Update existing, clearing manual edit flag
          parsed.apply(to: existingNOTAM, for: operation, appendSource: false)
          existingNOTAM.automaticallyCreated = true
          existingNOTAM.isManuallyEdited = false
        } else {
          // Create new NOTAM
          let newNOTAM = parsed.createNOTAM(for: runway, operation: operation)
          newNOTAM.automaticallyCreated = true
          runway.notam = newNOTAM
          context.insert(newNOTAM)
        }

        // Save changes
        try context.save()
      }
    } catch {
      // Log parsing errors but don't show to user
      SentrySDK.capture(error: error)
    }
  }

  /// Returns true if auto-fill is available but blocked by user edits.
  @MainActor
  public var autoFillAvailable: Bool {
    guard let runway else { return false }
    guard !downloadedNOTAMs.isEmpty else { return false }
    guard let existingNOTAM = runway.notam else { return false }

    return existingNOTAM.isManuallyEdited && !existingNOTAM.isEmpty
  }

  /// Filters NOTAMs to only those relevant for runway performance.
  ///
  /// - Parameters:
  ///   - notams: NOTAMs to filter
  ///   - plannedTime: The planned departure/arrival time
  /// - Returns: Filtered NOTAMs relevant to the planned time
  private func filterNOTAMs(_ notams: [NOTAMResponse], relativeTo plannedTime: Date)
    -> [NOTAMResponse]
  {
    let sevenDaysBefore =
      Calendar.current.date(byAdding: .day, value: -7, to: plannedTime)
      ?? plannedTime
    let thirtyDaysAfter =
      Calendar.current.date(byAdding: .day, value: 30, to: plannedTime)
      ?? plannedTime

    return notams.filter { notam in
      // Include NOTAMs that will be effective within the planning window
      // Exclude NOTAMs that expired before the window
      if let end = notam.effectiveEnd, end < sevenDaysBefore {
        return false
      }

      // Exclude NOTAMs that start too far in the future
      if notam.effectiveStart > thirtyDaysAfter {
        return false
      }

      // Include if it mentions relevant keywords
      let text = notam.notamText.uppercased()
      let keywords = [
        "RWY", "RUNWAY", "THR", "THRESHOLD", "OBST", "OBSTACLE",
        "CLSD", "CLOSED", "ICE", "SNOW", "SLUSH", "WATER", "CONTAM"
      ]
      return keywords.contains { text.contains($0) }
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
