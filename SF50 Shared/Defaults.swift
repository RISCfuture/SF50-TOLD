import Defaults
import Foundation
import SwiftData
import SwiftNASR

// MARK: - Defaults

nonisolated(unsafe) private let groupDefaults = UserDefaults(suiteName: "group.codes.tim.TOLD")!
public let latestSchemaVersion = 3

extension Defaults.Keys {
  public static let emptyWeight = Key<Measurement<UnitMass>>(
    "SF50/3/emptyWeight",
    default: .init(value: 3550, unit: .pounds),
    suite: groupDefaults
  )
  public static let fuelDensity = Key<Measurement<UnitDensity>>(
    "SF50/3/fuelDensity",
    default: .init(value: 6.71, unit: .poundsPerGallon),
    suite: groupDefaults
  )
  public static let safetyFactor = Key<Double>(
    "SF50/3/safetyFactor",
    default: 1.0,
    suite: groupDefaults
  )
  public static let updatedThrustSchedule = Key<Bool>(
    "SF50/3/updatedThrustSchedule",
    default: false,
    suite: groupDefaults
  )
  public static let useRegressionModel = Key<Bool>(
    "TOLD/3/useRegressionModel",
    default: false,
    suite: groupDefaults
  )

  public static let favoriteAirports = Key<Set<String>>(
    "TOLD/3/favoriteAirports",
    default: []
  )
  public static let recentAirports = Key<[String]>(
    "TOLD/3/recentAirports",
    default: []
  )

  public static let payload = Key<Measurement<UnitMass>>(
    "SF50/3/payload",
    default: .init(value: 0, unit: .pounds),
    suite: groupDefaults
  )
  public static let takeoffFuel = Key<Measurement<UnitVolume>>(
    "SF50/3/takeoffFuel",
    default: .init(value: 0, unit: .gallons),
    suite: groupDefaults
  )
  public static let landingFuel = Key<Measurement<UnitVolume>>(
    "SF50/3/landingFuel",
    default: .init(value: 0, unit: .gallons),
    suite: groupDefaults
  )

  public static let takeoffAirport = Key<String?>(
    "SF50/3/takeoffAirport",
    suite: groupDefaults
  )
  public static let landingAirport = Key<String?>(
    "SF50/3/landingAirport",
    suite: groupDefaults
  )
  public static let takeoffRunway = Key<String?>(
    "SF50/3/takeoffRunway",
    suite: groupDefaults
  )
  public static let landingRunway = Key<String?>(
    "SF50/3/landingRunway",
    suite: groupDefaults
  )

  public static let lastCycleLoaded = Key<Cycle?>(
    "TOLD/3/lastCycleLoaded",
    suite: groupDefaults
  )
  public static let ourAirportsLastUpdated = Key<Date?>(
    "TOLD/3/ourAirportsLastUpdated",
    suite: groupDefaults
  )
  public static let schemaVersion = Key<Int>(
    "TOLD/3/schemaVersion",
    default: latestSchemaVersion,
    suite: groupDefaults
  )
  public static let initialSetupComplete = Key<Bool>(
    "SF50/3/initialSetupComplete",
    default: false,
    suite: groupDefaults
  )
  public static let useAirportLocalTime = Key<Bool>(
    "TOLD/3/useAirportLocalTime",
    default: false,
    suite: groupDefaults
  )
}

// MARK: - Measurement

public protocol DefaultUnitProvider {
  static var defaultUnit: Dimension { get }
}

extension UnitMass: DefaultUnitProvider {
  public static var defaultUnit: Dimension { baseUnit() }
}

extension UnitDensity: DefaultUnitProvider {
  public static var defaultUnit: Dimension { baseUnit() }
}

extension UnitVolume: DefaultUnitProvider {
  public static var defaultUnit: Dimension { baseUnit() }
}

extension Measurement: Defaults.Serializable where UnitType: Dimension & DefaultUnitProvider {
  public static var bridge: MeasurementBridge<UnitType> {
    MeasurementBridge<UnitType>()
  }
}

public struct MeasurementBridge<UnitType: Dimension & DefaultUnitProvider>: Defaults.Bridge,
  Sendable
{
  public typealias Value = Measurement<UnitType>
  public typealias Serializable = Double

  public func serialize(_ value: Value?) -> Double? {
    value?.converted(to: UnitType.defaultUnit as! UnitType).value
  }

  public func deserialize(_ object: Double?) -> Value? {
    object.map { Measurement(value: $0, unit: UnitType.defaultUnit as! UnitType) }
  }
}

// MARK: - Cycle

public struct CycleBridge: Defaults.Bridge, Sendable {
  public typealias Value = Cycle
  public typealias Serializable = String

  public func serialize(_ value: SwiftNASR.Cycle?) -> String? {
    value.map { String(format: "%04d-%02d-%02d", $0.year, $0.month, $0.day) }
  }

  public func deserialize(_ object: String?) -> SwiftNASR.Cycle? {
    guard let object else { return nil }

    let parts = object.components(separatedBy: "-")
    guard parts.count == 3,
      let year = UInt(parts[0]),
      let mon = UInt8(parts[1]),
      let day = UInt8(parts[2])
    else { return nil }

    return Cycle(year: year, month: mon, day: day)
  }
}

extension Cycle: Defaults.Serializable {
  public static let bridge = CycleBridge()
}

// MARK: - SwiftData

extension PersistentIdentifier: Defaults.Serializable {}

public func findAirport(for airportID: String?, in context: ModelContext) throws -> Airport? {
  guard let airportID else { return nil }
  let airportFetchDescriptor = FetchDescriptor<Airport>(
    predicate: #Predicate { $0.recordID == airportID }
  )
  let airports = try context.fetch(airportFetchDescriptor)
  guard airports.count == 1 else { return nil }
  return airports.first
}

public func findAirportAndRunway(airportID: String?, runwayID: String?, in context: ModelContext)
  throws -> (Airport?, Runway?)
{
  guard let airport = try findAirport(for: airportID, in: context) else {
    return (nil, nil)
  }
  guard let runwayID else { return (airport, nil) }
  let runway = airport.runways.first(where: { $0.name == runwayID })
  return (airport, runway)
}
