import CoreLocation
import Foundation
import Gzip
import Logging
@preconcurrency import WeatherKit

/// Protocol defining the weather loading interface.
///
/// ``WeatherLoaderProtocol`` provides a testable abstraction for loading weather data
/// from METAR/TAF sources and Apple WeatherKit. Implementations must be actors to
/// ensure thread-safe access to cached data.
public protocol WeatherLoaderProtocol: Actor {
  /// Loads weather data, optionally forcing a refresh.
  /// - Parameter force: If true, ignores cache and reloads from network.
  func load(force: Bool) async

  /// Cancels any in-progress loading operation.
  func cancelLoading()

  /// Creates a stream of conditions updates for the given key.
  /// - Parameter key: Identifies the airport and time to monitor.
  /// - Returns: Async stream yielding conditions as they become available.
  func streamConditions(for key: WeatherLoader.Key) async -> AsyncStream<Loadable<Conditions>>

  /// Creates a stream of raw METAR text updates.
  /// - Parameter key: Identifies the airport to monitor.
  /// - Returns: Async stream yielding METAR text as it becomes available.
  func streamMETAR(for key: WeatherLoader.Key) async -> AsyncStream<Loadable<String?>>

  /// Creates a stream of raw TAF text updates.
  /// - Parameter key: Identifies the airport to monitor.
  /// - Returns: Async stream yielding TAF text as it becomes available.
  func streamTAF(for key: WeatherLoader.Key) async -> AsyncStream<Loadable<String?>>
}

/**
 * Actor responsible for loading and caching weather data from multiple sources.
 *
 * ``WeatherLoader`` downloads METAR observations and TAF forecasts from Aviation Weather
 * (aviationweather.gov) and supplements them with Apple WeatherKit data. It provides
 * reactive streams of weather conditions that update when new data is loaded.
 *
 * ## Data Sources
 *
 * Weather data is combined from:
 * - **Aviation Weather**: METAR observations and TAF forecasts (primary source for airports)
 * - **WeatherKit**: Current conditions and hourly forecasts (fills gaps in aviation data)
 *
 * ## Time-Based Conditions
 *
 * The loader automatically selects the appropriate data source based on time:
 * - **Current** (within 1 hour): Uses METAR observation, augmented with WeatherKit
 * - **Future**: Uses TAF forecast period covering the requested time
 *
 * ## Subscription Model
 *
 * Weather data is delivered via `AsyncStream`:
 * - ``streamConditions(for:)`` - Complete ``Conditions`` objects
 * - ``streamMETAR(for:)`` - Raw METAR text
 * - ``streamTAF(for:)`` - Raw TAF text
 */
public actor WeatherLoader: WeatherLoaderProtocol {
  /// Shared singleton instance for app-wide weather loading.
  public static let shared = WeatherLoader()

  private static let reloadInterval = 60.0 * 15
  private static let METARsURL = URL(
    string: "https://aviationweather.gov/data/cache/metars.cache.xml.gz"
  )!
  private static let TAFsURL = URL(
    string: "https://aviationweather.gov/data/cache/tafs.cache.xml.gz"
  )!
  private static let logger = Logger(label: "codes.tim.SF50-TOLD.WeatherLoader")
  private static let weatherService = WeatherService()

  private var observations: Loadable<[String: Observation]> = .notLoaded {
    didSet { Task { await notifySubscribers() } }
  }
  private var forecasts: Loadable<[String: Forecast]> = .notLoaded {
    didSet { Task { await notifySubscribers() } }
  }
  private var lastLoaded: Date?
  private var conditionsSubscribers = [
    UUID: (Key, AsyncStream<Loadable<Conditions>>.Continuation)
  ]()
  private var metarSubscribers = [UUID: (Key, AsyncStream<Loadable<String?>>.Continuation)]()
  private var tafSubscribers = [UUID: (Key, AsyncStream<Loadable<String?>>.Continuation)]()
  private var loadingTask: Task<Void, Never>?

  private var session: URLSession { .init(configuration: .ephemeral) }

  private init() {}

  public func load(force: Bool = false) async {
    if !force, let lastLoaded, lastLoaded.timeIntervalSinceNow > -Self.reloadInterval {
      return
    }
    loadingTask?.cancel()
    loadingTask = Task {
      await loadMETARs()
      await loadTAFs()
    }
    await loadingTask?.value
    lastLoaded = .now
  }

  public func cancelLoading() {
    loadingTask?.cancel()
    loadingTask = nil
  }

  public func streamConditions(for key: Key) async -> AsyncStream<Loadable<Conditions>> {
    let id = UUID()
    let initialConditions = await conditions(for: key)

    return AsyncStream { continuation in
      conditionsSubscribers[id] = (key, continuation)

      // Send initial value
      continuation.yield(initialConditions)

      continuation.onTermination = { @Sendable _ in
        Task { [weak self] in
          await self?.removeConditionsSubscriber(id: id)
        }
      }
    }
  }

  public func streamMETAR(for key: Key) -> AsyncStream<Loadable<String?>> {
    let id = UUID()
    let initialRaw = observations.map { $0[key.id]?.raw }

    return AsyncStream { continuation in
      metarSubscribers[id] = (key, continuation)

      // Send initial value
      continuation.yield(initialRaw)

      continuation.onTermination = { @Sendable _ in
        Task { [weak self] in
          await self?.removeMetarSubscriber(id: id)
        }
      }
    }
  }

  public func streamTAF(for key: Key) -> AsyncStream<Loadable<String?>> {
    let id = UUID()
    let initialRaw = forecasts.map { $0[key.id]?.raw }

    return AsyncStream { continuation in
      tafSubscribers[id] = (key, continuation)

      // Send initial value
      continuation.yield(initialRaw)

      continuation.onTermination = { @Sendable _ in
        Task { [weak self] in
          await self?.removeTafSubscriber(id: id)
        }
      }
    }
  }

  private func removeConditionsSubscriber(id: UUID) {
    conditionsSubscribers.removeValue(forKey: id)
  }

  private func removeMetarSubscriber(id: UUID) {
    metarSubscribers.removeValue(forKey: id)
  }

  private func removeTafSubscriber(id: UUID) {
    tafSubscribers.removeValue(forKey: id)
  }

  private func notifySubscribers() async {
    // Notify conditions subscribers
    for (_, (key, continuation)) in conditionsSubscribers {
      let conditions = await conditions(for: key)
      continuation.yield(conditions)
    }

    // Notify METAR subscribers
    for (_, (key, continuation)) in metarSubscribers {
      let raw = observations.map { $0[key.id]?.raw }
      continuation.yield(raw)
    }

    // Notify TAF subscribers
    for (_, (key, continuation)) in tafSubscribers {
      let raw = forecasts.map { $0[key.id]?.raw }
      continuation.yield(raw)
    }
  }

  private func conditions(for key: Key) async -> Loadable<Conditions> {
    let weather: WeatherKit.Weather?
    do {
      weather = try await Self.weatherService.weather(for: key.location)
    } catch {
      Self.logger.error(
        "WeatherKit error",
        metadata: [
          "error": "\(error)",
          "location": "\(key.location)",
          "id": "\(key.id)"
        ]
      )
      weather = nil
    }

    if key.time.timeIntervalSinceNow < 3600 {
      return observations.map { observations in
        if let conditions = observations[key.id]?.conditions {
          if let weather {
            return conditions.adding(weather: weather.currentWeather)
          }
          return conditions
        }
        if let weather {
          return .init(weather: weather.currentWeather)
        }
        return .init()
      }
    }
    return forecasts.map { forecasts in
      let forecast = forecasts[key.id]
      if let conditions = forecast?.conditions.first(where: { $0.validTime.contains(key.time) }) {
        if let weather, let hourly = weather.hourlyForecast.for(date: key.time) {
          return conditions.adding(weather: hourly)
        }
        return conditions
      }
      if let weather, let hourly = weather.hourlyForecast.for(date: key.time) {
        return .init(weather: hourly)
      }
      return .init()
    }
  }

  private func loadMETARs() async {
    observations = .loading
    await notifySubscribers()

    do {
      try Task.checkCancellation()
      let data = try await load(url: Self.METARsURL)
      try Task.checkCancellation()

      let newMETARs = try await withThrowingTaskGroup(of: (String, Observation)?.self) { group in
        let xmlData: Data
        do {
          xmlData = try data.gunzipped()
        } catch {
          let prefix = data.prefix(20).map { String(format: "%02x", $0) }.joined(separator: " ")
          Self.logger.error(
            "Failed to decompress METAR data",
            metadata: [
              "error": "\(error)",
              "dataSize": "\(data.count)",
              "dataPrefix": "\(prefix)"
            ]
          )
          throw Errors.gzipDecompressionFailed(
            url: Self.METARsURL,
            dataSize: data.count,
            dataPrefix: prefix,
            underlyingError: error
          )
        }

        // Parse XML and stream observations
        for try await (stationID, observation) in METARXMLParser.parse(data: xmlData) {
          try Task.checkCancellation()

          group.addTask {
            let conditions = Conditions(observation: observation)
            return (stationID, .init(conditions: conditions, raw: observation.rawText))
          }
        }

        return try await group.compactMap(\.self).reduce(into: [:]) { result, pair in
          result[pair.0] = pair.1
        }
      }

      observations = .value(newMETARs)
    } catch is CancellationError {
      // Don't update observations if cancelled
    } catch {
      observations = .error(error)
    }
  }

  private func loadTAFs() async {
    forecasts = .loading
    await notifySubscribers()

    do {
      try Task.checkCancellation()
      let data = try await load(url: Self.TAFsURL)
      try Task.checkCancellation()

      let newTAFs = try await withThrowingTaskGroup(of: (String, Forecast)?.self) { group in
        let xmlData: Data
        do {
          xmlData = try data.gunzipped()
        } catch {
          let prefix = data.prefix(20).map { String(format: "%02x", $0) }.joined(separator: " ")
          Self.logger.error(
            "Failed to decompress TAF data",
            metadata: [
              "error": "\(error)",
              "dataSize": "\(data.count)",
              "dataPrefix": "\(prefix)"
            ]
          )
          throw Errors.gzipDecompressionFailed(
            url: Self.TAFsURL,
            dataSize: data.count,
            dataPrefix: prefix,
            underlyingError: error
          )
        }

        // Parse XML and stream TAFs
        for try await (stationID, tafData) in TAFXMLParser.parse(data: xmlData) {
          try Task.checkCancellation()

          group.addTask {
            let conditions = tafData.forecasts.compactMap { Conditions(forecast: $0) }
            return (stationID, .init(conditions: conditions, raw: tafData.rawText))
          }
        }

        return try await group.compactMap(\.self)
          .reduce(into: [:]) { result, pair in result[pair.0] = pair.1 }
      }

      forecasts = .value(newTAFs)
    } catch is CancellationError {
      // Don't update forecasts if cancelled
    } catch {
      forecasts = .error(error)
    }
  }

  private func load(url: URL) async throws -> Data {
    Self.logger.info("Loading weather data from URL", metadata: ["url": "\(url)"])

    let (data, response) = try await session.data(from: url)
    if let response = response as? HTTPURLResponse {
      guard (200..<300).contains(response.statusCode) else {
        Self.logger.error(
          "Bad HTTP response",
          metadata: [
            "statusCode": "\(response.statusCode)",
            "url": "\(url)"
          ]
        )
        throw Errors.badResponse(response)
      }
    }

    Self.logger.info(
      "Downloaded weather data",
      metadata: [
        "size": "\(data.count)",
        "url": "\(url)"
      ]
    )

    return data
  }

  /// Errors that can occur during weather loading.
  public enum Errors: Swift.Error {
    /// HTTP response was not successful.
    case badResponse(_ response: HTTPURLResponse)

    /// Failed to decompress GZIP data.
    case gzipDecompressionFailed(
      url: URL,
      dataSize: Int,
      dataPrefix: String,
      underlyingError: Error
    )
  }

  /// Key identifying a weather data request by airport and time.
  public struct Key: Hashable, Sendable {
    /// Weather station identifier (typically ICAO code).
    let id: String

    /// Geographic location for WeatherKit requests.
    let location: CLLocation

    /// Time for which conditions are requested.
    let time: Date

    /// Creates a key for the specified airport and time.
    /// - Parameters:
    ///   - airport: The airport to fetch weather for.
    ///   - time: The time for which conditions are needed.
    public init(airport: Airport, time: Date) {
      id = airport.weatherID
      location = airport.location
      self.time = time
    }

    public func hash(into hasher: inout Hasher) {
      hasher.combine(id)
      hasher.combine(time)
    }
  }

  private struct Observation {
    let conditions: Conditions
    let raw: String
  }

  private struct Forecast {
    let conditions: [Conditions]
    let raw: String
  }
}

extension Airport {
  fileprivate var weatherID: String {
    if let ICAO_ID { return ICAO_ID }
    if locationID.count == 3 { return "K\(locationID)" }
    return locationID
  }
}

extension HourWeather {
  fileprivate var dateRange: DateInterval {
    .init(start: date, duration: 3600)
  }
}

extension Forecast<HourWeather> {
  fileprivate func `for`(date: Date) -> HourWeather? {
    first(where: { $0.dateRange.contains(date) })
  }
}
