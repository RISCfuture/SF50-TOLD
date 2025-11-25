import Defaults
import Foundation
import SF50_Shared
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
      for: SF50_Shared.Airport.self,
      SF50_Shared.Runway.self,
      SF50_Shared.NOTAM.self,
      SF50_Shared.Scenario.self,
      configurations: .init(isStoredInMemoryOnly: true)
    )
  }

  @MainActor
  public func reset() throws {
    Defaults.removeAll(suite: .init(suiteName: "group.codes.tim.TOLD")!)

    try mainContext.delete(model: SF50_Shared.Runway.self)
    try mainContext.delete(model: SF50_Shared.Airport.self)
    try mainContext.delete(model: SF50_Shared.NOTAM.self)
    try mainContext.delete(model: SF50_Shared.Scenario.self)
    try mainContext.save()
  }

  @MainActor
  public func useMetricUnits() {
    Defaults[.fuelVolumeUnit] = .liters
    Defaults[.heightUnit] = .meters
    Defaults[.speedUnit] = .kilometersPerHour
    Defaults[.temperatureUnit] = .celsius
  }

  @MainActor
  public func insert(airport: AirportBuilder) throws {
    // Create fresh instances from the builder factories
    let airportInstance = airport.airport
    let runwayInstances = airport.runwaysFactory(airportInstance)

    mainContext.insert(airportInstance)
    for runway in runwayInstances {
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
  public func load(locationID: String) throws -> SF50_Shared.Airport? {
    let predicate = #Predicate<SF50_Shared.Airport> { $0.locationID == locationID }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try mainContext.fetch(descriptor).first
  }

  @MainActor
  public func load(airportID: String, runway: String) throws -> SF50_Shared.Runway? {
    guard let airport = try load(locationID: airportID) else { return nil }
    let airportID = airport.persistentModelID
    let predicate = #Predicate<SF50_Shared.Runway> {
      $0.airport.persistentModelID == airportID && $0.name == runway
    }
    var descriptor = FetchDescriptor(predicate: predicate)
    descriptor.fetchLimit = 1
    return try mainContext.fetch(descriptor).first
  }

  @MainActor
  @discardableResult
  public func addNOTAM(
    to runway: SF50_Shared.Runway,
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

  public func setTakeoff(runway: SF50_Shared.Runway) {
    Defaults[.payload] = .init(value: 400, unit: .pounds)
    Defaults[.takeoffFuel] = .init(value: 220, unit: .gallons)
    Defaults[.takeoffAirport] = runway.airport.recordID
    Defaults[.takeoffRunway] = runway.name
  }

  public func setLanding(runway: SF50_Shared.Runway) {
    Defaults[.payload] = .init(value: 400, unit: .pounds)
    Defaults[.landingFuel] = .init(value: 70, unit: .gallons)
    Defaults[.landingAirport] = runway.airport.recordID
    Defaults[.landingRunway] = runway.name
  }

  public func newBackgroundContext() -> ModelContext { .init(container) }

  /// Generates sample NOTAMResponse objects for preview purposes
  /// - Parameters:
  ///   - count: Number of NOTAMs to generate
  ///   - icaoLocation: ICAO code for the airport (default: "KOAK")
  ///   - baseTime: Reference time for generating effective dates (default: now)
  /// - Returns: Array of NOTAMResponse objects with varied statuses and lengths
  public func generateNOTAMs(
    count: Int,
    icaoLocation: String = "KOAK",
    baseTime: Date = .now
  ) -> [NOTAMResponse] {
    let loremTexts = [
      "RWY CLSD",
      "THR DISPLACED 320M. EFFECTIVE OPR LENGTH 1420M",
      "THR RWY 30 DISPLACED 320M. RWY 12/30 EFFECTIVE OPR LENGTH 1420M.\nDISPLACED THR LIGHT OPR",
      "RWY 12/30 CLSD DUE WIP. AVBL FOR HOSP FLIGHTS WITH 60 MIN PN",
      "PAPI U/S",
      "LIGHTING SYSTEM UPGRADE IN PROGRESS. EXPECT REDUCED VISIBILITY OF THR LIGHTS",
      "OBST CRANE 1200FT AMSL 0.3NM E OF THR RWY 30",
      "NAVAID VOR OUT OF SERVICE. USE GPS APPROACH ONLY",
      "TWY A CLSD BTN TWY B AND TWY C. USE ALT ROUTING VIA TWY D",
      "BIRD ACTIVITY REPORTED IN VICINITY OF AIRPORT. EXERCISE CAUTION",
      "FUEL AVBL H24",
      "PPR FOR ACF WINGSPAN GREATER THAN 80FT. CONTACT AIRPORT OPS 48HR IN ADVANCE",
      "RWY SURFACE TREATMENT IN PROGRESS 0800-1600 LOCAL. EXPECT DELAYS",
      "APRON REPAINTING. TAXI WITH CAUTION. FOLLOW MARSHALLER INSTRUCTIONS",
      "ILS RWY 30 GLIDESLOPE U/S. LOC ONLY APPROACH AVAILABLE"
    ]

    let purposes = ["N", "B", "M", "O"]
    let scopes = ["A", "E", "W", nil]
    let trafficTypes = ["I", "IV", "K", nil]

    return (0..<count).map { index in
      let id = index + 1
      let letter = String(UnicodeScalar(65 + index % 26)!)
      let notamId = "\(letter)\(String(format: "%04d", 8000 + index))/2025"

      // Vary the effective times for different statuses
      let hourOffset: TimeInterval
      switch index % 5 {
        case 0:  // Active - started 1 hour ago, ends in 2 hours
          hourOffset = -3600
        case 1:  // Warning - starts in 2 hours
          hourOffset = 7200
        case 2:  // Expired - started 1 day ago, ended 2 hours ago
          hourOffset = -86400
        case 3:  // Future - starts in 1 day
          hourOffset = 86400
        default:  // Active - started 30 min ago, ends in 4 hours
          hourOffset = -1800
      }

      let effectiveStart = baseTime.addingTimeInterval(hourOffset)

      // Vary end times
      let effectiveEnd: Date?
      switch index % 5 {
        case 2:  // Expired
          effectiveEnd = baseTime.addingTimeInterval(-7200)
        case 3, 4:  // Some have end times
          effectiveEnd = effectiveStart.addingTimeInterval(14400)
        default:  // Some are permanent
          effectiveEnd = index % 3 == 0 ? nil : effectiveStart.addingTimeInterval(10800)
      }

      // Vary NOTAM text lengths
      let textIndex = index % loremTexts.count
      let notamText = loremTexts[textIndex]

      // Some NOTAMs have schedules
      let schedule = index % 7 == 0 ? "0800-1800" : nil

      return NOTAMResponse(
        id: id,
        notamId: notamId,
        icaoLocation: icaoLocation,
        effectiveStart: effectiveStart,
        effectiveEnd: effectiveEnd,
        schedule: schedule,
        notamText: notamText,
        qLine: nil,
        purpose: purposes[index % purposes.count],
        scope: scopes[index % scopes.count],
        trafficType: trafficTypes[index % trafficTypes.count]
      )
    }
  }
}

@MainActor
public struct AirportBuilder {
  let airportFactory: () -> SF50_Shared.Airport
  let runwaysFactory: (SF50_Shared.Airport) -> [SF50_Shared.Runway]

  init(airport: @escaping @autoclosure () -> SF50_Shared.Airport, runways: @escaping (SF50_Shared.Airport) -> [SF50_Shared.Runway]) {
    self.airportFactory = airport
    self.runwaysFactory = runways
  }

  var airport: SF50_Shared.Airport {
    airportFactory()
  }

  var runways: [SF50_Shared.Runway] {
    let airport = airportFactory()
    return runwaysFactory(airport)
  }

  public func unsaved() -> SF50_Shared.Airport {
    let airport = airportFactory()
    airport.runways = runwaysFactory(airport)
    return airport
  }
}
