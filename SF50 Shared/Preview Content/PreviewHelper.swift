import Defaults
import Foundation
import SwiftData
import SwiftNASR
import WeatherKit

public final class PreviewHelper: Sendable {
  public let container: ModelContainer

  @MainActor public var mainContext: ModelContext { container.mainContext }

  public var ISA: Conditions { .init() }

  public var lightWinds: Conditions {
    .init(
      windDirection: .init(value: 280, unit: .degrees),
      windSpeed: .init(value: 12, unit: .knots),
      temperature: .init(value: 28, unit: .celsius),
      seaLevelPressure: .init(value: 30.12, unit: .inchesOfMercury)
    )
  }

  public var strongWinds: Conditions {
    .init(
      windDirection: .init(value: 90, unit: .degrees),
      windSpeed: .init(value: 28, unit: .knots),
      temperature: .init(value: 7, unit: .celsius),
      seaLevelPressure: .init(value: 29.12, unit: .inchesOfMercury)
    )
  }

  public var veryCold: Conditions {
    .init(
      windDirection: .init(value: 120, unit: .degrees),
      windSpeed: .init(value: 7, unit: .knots),
      temperature: .init(value: -56, unit: .celsius),
      seaLevelPressure: .init(value: 28.99, unit: .inchesOfMercury)
    )
  }

  public var veryHot: Conditions {
    .init(
      windDirection: .init(value: 340, unit: .degrees),
      windSpeed: .init(value: 17, unit: .knots),
      temperature: .init(value: 51, unit: .celsius),
      seaLevelPressure: .init(value: 31.17, unit: .inchesOfMercury)
    )
  }

  public var NWS: Conditions {
    // Create a mock observation from METAR string
    let observation = METAR(
      stationID: "KSFO",
      observationTime: Date(),
      temperature: 18.0,
      dewpoint: 13.0,
      windDirection: nil,  // Calm
      windSpeed: 0,
      windGust: nil,
      altimeter: 30.10,
      seaLevelPressure: 1019.2,
      rawText: METARString
    )
    return .init(observation: observation)
  }

  public var METARString: String {
    "KSFO 191514Z 00000KT 10SM BKN180 18/13 A3010 RMK AO2 SLP192 T01830128 VISNO $"
  }
  public var TAFString: String {
    "KSFO 191514Z 1721/1824 VRB04KT P6SM SKC WS020/02025KT FM172200 31008KT P6SM SKC FM180100 28013KT P6SM FEW200 FM180800 28006KT P6SM FEW200 FM181000 VRB05KT P6SM SKC WS020/02030KT FM181500 36008KT P6SM SKC WS015/03030KT FM182000 36012KT P6SM SKC WS015/03035KT"
  }
  public var hourWeather: HourWeather {
    get async throws {
      try await WeatherService().weather(for: .init(latitude: 37, longitude: -121)).hourlyForecast
        .first!
    }
  }

  public init() throws {
    container = try .init(
      for: Airport.self,
      Runway.self,
      NOTAM.self,
      Scenario.self,
      configurations: .init(isStoredInMemoryOnly: true)
    )
  }

  @MainActor
  public func reset() throws {
    Defaults.removeAll(suite: .init(suiteName: "group.codes.tim.TOLD")!)

    try mainContext.delete(model: Runway.self)
    try mainContext.delete(model: Airport.self)
    try mainContext.delete(model: NOTAM.self)
    try mainContext.delete(model: Scenario.self)
    try mainContext.save()
  }

  @MainActor
  public func insert(airport: AirportBuilder) throws {
    mainContext.insert(airport.airport)
    for runway in airport.runways {
      mainContext.insert(runway)
    }
    try mainContext.save()
  }

  @MainActor
  public func insertBasicScenarios() throws {
    // Takeoff scenarios
    let takeoffScenarios = [
      Scenario(
        name: "OAT +10°C",
        operation: .takeoff,
        deltaTemperature: .init(value: 10, unit: .celsius)
      ),
      Scenario(
        name: "OAT -10°C",
        operation: .takeoff,
        deltaTemperature: .init(value: -10, unit: .celsius)
      ),
      Scenario(
        name: "Wind Speed +10 kts",
        operation: .takeoff,
        deltaWindSpeed: .init(value: 10, unit: .knots)
      ),
      Scenario(
        name: "Weight +200 lbs",
        operation: .takeoff,
        deltaWeight: .init(value: 200, unit: .pounds)
      )
    ]

    // Landing scenarios
    let landingScenarios = [
      Scenario(
        name: "OAT +10°C",
        operation: .landing,
        deltaTemperature: .init(value: 10, unit: .celsius)
      ),
      Scenario(
        name: "Flaps 50",
        operation: .landing,
        flapSettingOverride: "flaps50"
      ),
      Scenario(
        name: "Water/Slush 0.5\"",
        operation: .landing,
        contaminationOverride: "waterOrSlush",
        contaminationDepth: .init(value: 0.5, unit: .inches)
      ),
      Scenario(
        name: "Dry Snow",
        operation: .landing,
        contaminationOverride: "drySnow"
      )
    ]

    for scenario in takeoffScenarios + landingScenarios {
      mainContext.insert(scenario)
    }
    try mainContext.save()
  }

  @MainActor
  public func load(locationID: String) throws -> Airport? {
    let predicate = #Predicate<Airport> { $0.locationID == locationID }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try mainContext.fetch(descriptor).first
  }

  @MainActor
  public func load(airportID: String, runway: String) throws -> Runway? {
    guard let airport = try load(locationID: airportID) else { return nil }
    let airportID = airport.persistentModelID
    let predicate = #Predicate<Runway> {
      $0.airport.persistentModelID == airportID && $0.name == runway
    }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try mainContext.fetch(descriptor).first
  }

  @MainActor
  @discardableResult
  public func addNOTAM(
    to runway: Runway,
    shortenTakeoff: Double? = nil,
    shortenLanding: Double? = nil,
    contamination: Contamination? = nil,
    obstacleHeight: Double? = nil,
    obstacleDistance: Double? = nil
  ) throws -> NOTAM {
    let notam = NOTAM(
      runway: runway,
      contamination: contamination,
      takeoffDistanceShortening: shortenTakeoff.map { .init(value: $0, unit: .feet) },
      landingDistanceShortening: shortenLanding.map { .init(value: $0, unit: .feet) },
      obstacleHeight: obstacleHeight.map { .init(value: $0, unit: .feet) },
      obstacleDistance: obstacleDistance.map { .init(value: $0, unit: .nauticalMiles) }
    )
    runway.notam = notam
    mainContext.insert(notam)
    try mainContext.save()
    return notam
  }

  public func setUpToDate() {
    Defaults[.schemaVersion] = latestSchemaVersion
    Defaults[.lastCycleLoaded] = Cycle.current
  }

  public func setOutOfDate() {
    Defaults[.schemaVersion] = latestSchemaVersion
    Defaults[.lastCycleLoaded] = .current.previous
  }

  public func setTakeoff(runway: Runway) {
    Defaults[.payload] = .init(value: 400, unit: .pounds)
    Defaults[.takeoffFuel] = .init(value: 220, unit: .gallons)
    Defaults[.takeoffAirport] = runway.airport.recordID
    Defaults[.takeoffRunway] = runway.name
  }

  public func setLanding(runway: Runway) {
    Defaults[.payload] = .init(value: 400, unit: .pounds)
    Defaults[.landingFuel] = .init(value: 70, unit: .gallons)
    Defaults[.landingAirport] = runway.airport.recordID
    Defaults[.landingRunway] = runway.name
  }

  public func newBackgroundContext() -> ModelContext { .init(container) }
}

@MainActor
public struct AirportBuilder {
  let airport: Airport
  let runways: [Runway]

  init(airport: Airport, runways: (Airport) -> [Runway]) {
    self.airport = airport
    self.runways = runways(airport)
  }

  public func unsaved() -> Airport {
    airport.runways = runways
    return airport
  }
}
