import Defaults
import Foundation
import Observation
import Sentry
import SwiftData

/// View model managing weather data for a specific operation (takeoff or landing).
///
/// ``WeatherViewModel`` provides reactive access to weather conditions including
/// downloaded METAR/TAF data, manual user entries, and loading states. It supports
/// both automatic weather updates and manual weather entry mode.
///
/// ## Weather Modes
///
/// - **Automatic**: Weather loaded from ``WeatherLoader`` and kept in sync
/// - **Manual**: User-entered conditions preserved until explicitly reset
/// - **ISA**: International Standard Atmosphere (used when no data available)
///
/// ## Manual Mode Behavior
///
/// When the user enters custom weather values:
/// - The view model switches to manual mode
/// - Downloaded weather updates are ignored
/// - Manual mode persists until ``load(force:)`` is called with `force: true`
/// - Changing airports resets manual mode
///
/// ## Usage
///
/// ```swift
/// let weatherVM = WeatherViewModel(
///     operation: .takeoff,
///     container: modelContainer
/// )
///
/// // Load weather for current airport
/// await weatherVM.load()
///
/// // Access conditions
/// let temp = weatherVM.conditions.temperature
/// ```
@Observable
@MainActor
public final class WeatherViewModel: WithIdentifiableError {
  private let loader: any WeatherLoaderProtocol

  private let airportKey: Defaults.Key<String?>

  // Track manual weather mode separately to prevent loss during re-subscriptions
  private var isManualMode = false

  // MARK: Inputs

  public var airport: Airport? {
    didSet {
      // Reset manual mode when airport changes to load new airport's weather
      if oldValue?.recordID != airport?.recordID {
        isManualMode = false
      }
      subscribe()
    }
  }
  public var time = Date() {
    didSet { subscribe() }
  }

  // MARK: Inputs/Outputs

  public var conditions = Conditions() {
    didSet {
      // Set manual mode when user enters custom weather
      // Don't reset it here - only reset explicitly when needed
      if conditions.source == .entered {
        isManualMode = true
        // Clear any loading error when user enters custom weather
        error = nil
      }
    }
  }

  // MARK: Outputs

  public private(set) var isLoading = false
  public var error: Error?
  public private(set) var METAR: Loadable<String?> = .notLoaded
  public private(set) var TAF: Loadable<String?> = .notLoaded

  private var subscription: Task<Void, Never>?
  private var defaultsTask: Task<Void, Never>?

  public init(
    operation: Operation,
    container: ModelContainer,
    loader: (any WeatherLoaderProtocol)? = nil
  ) {
    airportKey =
      switch operation {
        case .takeoff: .takeoffAirport
        case .landing: .landingAirport
      }
    self.loader = loader ?? WeatherLoader.shared
    self.airport = airport
    self.time = time
    subscribe()
    setupObservation(container: container)
  }

  //    deinit {
  //        defaultsTask?.cancel()
  //    }

  public func load(force: Bool = false) async {
    // When force is true, it means user clicked "Use Downloaded Weather"
    // Reset manual weather mode in that case
    if force && isManualMode {
      isManualMode = false
      conditions = .init()
    }
    await loader.load(force: force)
  }

  public func cancel() async {
    await loader.cancelLoading()
    useISA()
  }

  public func useISA() {
    isManualMode = false
    conditions = .init()
    isLoading = false
    error = nil
  }

  private func setupObservation(container: ModelContainer) {
    defaultsTask = Task {
      let context = ModelContext(container)

      for await (airportID) in Defaults.updates(airportKey) where !Task.isCancelled {
        do {
          airport = try findAirport(for: airportID, in: context)
        } catch {
          SentrySDK.capture(error: error)
          self.error = error
        }
      }
    }
  }

  private func subscribe() {
    subscription?.cancel()
    guard let airport else {
      // Preserve manual weather even when airport is not set
      if !isManualMode {
        conditions = .init()
      }
      return
    }

    let key = WeatherLoader.Key(airport: airport, time: time)
    subscription = Task { [weak self] in
      guard let self else {
        return
      }
      await MainActor.run { self.error = nil }

      await withTaskGroup(of: Void.self) { group in
        group.addTask { [self] in
          let stream = await loader.streamConditions(for: key)
          for await conditions in stream where !Task.isCancelled {
            await MainActor.run {
              // Preserve manual weather if user has entered custom values
              // Use the tracked state to avoid losing manual mode during re-subscriptions

              switch conditions {
                case .notLoaded:
                  if !self.isManualMode {
                    self.useISA()
                  }
                case .loading:
                  if !self.isManualMode {
                    self.isLoading = true
                    self.conditions = .init()
                    self.error = nil
                  }
                case .value(let conditions):
                  if !self.isManualMode {
                    self.isLoading = false
                    self.conditions = conditions
                    self.error = nil
                  }
                case .error(let error):
                  if !self.isManualMode {
                    SentrySDK.capture(error: error)
                    self.isLoading = false
                    self.conditions = .init()
                    self.error = error
                  }
              }
            }
          }
        }
        group.addTask { [self] in
          let stream = await loader.streamMETAR(for: key)
          for await value in stream where !Task.isCancelled {
            await MainActor.run { self.METAR = value }
          }
        }
        group.addTask { [self] in
          let stream = await loader.streamTAF(for: key)
          for await value in stream where !Task.isCancelled {
            await MainActor.run { self.TAF = value }
          }
        }
      }
    }
  }
}
