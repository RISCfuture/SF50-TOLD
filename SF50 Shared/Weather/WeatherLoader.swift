import CoreLocation
import Foundation
import Gzip
import Logging
@preconcurrency import WeatherKit

public protocol WeatherLoaderProtocol: Actor {
  func load(force: Bool) async
  func cancelLoading()
  func streamConditions(for key: WeatherLoader.Key) async -> AsyncStream<Loadable<Conditions>>
  func streamMETAR(for key: WeatherLoader.Key) async -> AsyncStream<Loadable<String?>>
  func streamTAF(for key: WeatherLoader.Key) async -> AsyncStream<Loadable<String?>>
}

public actor WeatherLoader: WeatherLoaderProtocol {
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
        let xmlData = try data.gunzipped()

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
        let xmlData = try data.gunzipped()

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

  public enum Errors: Swift.Error {
    case badResponse(_ response: HTTPURLResponse)
  }

  public struct Key: Hashable, Sendable {
    let id: String
    let location: CLLocation
    let time: Date

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
