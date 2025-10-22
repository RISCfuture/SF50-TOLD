import Defaults
import Foundation
import SwiftData
import SwiftNASR

// MARK: - Defaults

nonisolated(unsafe) private let groupDefaults = UserDefaults(suiteName: "group.codes.tim.TOLD")!
public let latestSchemaVersion = 4

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
  public static let defaultScenariosSeeded = Key<Bool>(
    "SF50/3/defaultScenariosSeeded",
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

  // MARK: Unit Preferences

  public static let weightUnit = Key<UnitMass>(
    "TOLD/3/weightUnit",
    default: .pounds,
    suite: groupDefaults
  )
  public static let fuelVolumeUnit = Key<UnitVolume>(
    "TOLD/3/fuelVolumeUnit",
    default: .gallons,
    suite: groupDefaults
  )
  public static let fuelDensityUnit = Key<UnitDensity>(
    "TOLD/3/fuelDensityUnit",
    default: .poundsPerGallon,
    suite: groupDefaults
  )
  public static let runwayLengthUnit = Key<UnitLength>(
    "TOLD/3/runwayLengthUnit",
    default: .feet,
    suite: groupDefaults
  )
  public static let distanceUnit = Key<UnitLength>(
    "TOLD/3/distanceUnit",
    default: .nauticalMiles,
    suite: groupDefaults
  )
  public static let heightUnit = Key<UnitLength>(
    "TOLD/3/heightUnit",
    default: .feet,
    suite: groupDefaults
  )
  public static let speedUnit = Key<UnitSpeed>(
    "TOLD/3/speedUnit",
    default: .knots,
    suite: groupDefaults
  )
  public static let temperatureUnit = Key<UnitTemperature>(
    "TOLD/3/temperatureUnit",
    default: .celsius,
    suite: groupDefaults
  )
  public static let pressureUnit = Key<UnitPressure>(
    "TOLD/3/pressureUnit",
    default: .inchesOfMercury,
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

extension UnitLength: DefaultUnitProvider {
  public static var defaultUnit: Dimension { baseUnit() }
}

extension UnitSpeed: DefaultUnitProvider {
  public static var defaultUnit: Dimension { baseUnit() }
}

extension UnitTemperature: DefaultUnitProvider {
  public static var defaultUnit: Dimension { baseUnit() }
}

extension UnitPressure: DefaultUnitProvider {
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

// MARK: - Unit Types

public struct UnitMassBridge: Defaults.Bridge, Sendable {
  public typealias Value = UnitMass
  public typealias Serializable = String

  public func serialize(_ value: UnitMass?) -> String? {
    value?.symbol
  }

  public func deserialize(_ object: String?) -> UnitMass? {
    switch object {
      case "lb": return .pounds
      case "kg": return .kilograms
      default: return nil
    }
  }
}

public struct UnitVolumeBridge: Defaults.Bridge, Sendable {
  public typealias Value = UnitVolume
  public typealias Serializable = String

  public func serialize(_ value: UnitVolume?) -> String? {
    value?.symbol
  }

  public func deserialize(_ object: String?) -> UnitVolume? {
    switch object {
      case "gal": return .gallons
      case "L": return .liters
      default: return nil
    }
  }
}

public struct UnitDensityBridge: Defaults.Bridge, Sendable {
  public typealias Value = UnitDensity
  public typealias Serializable = String

  public func serialize(_ value: UnitDensity?) -> String? {
    value?.symbol
  }

  public func deserialize(_ object: String?) -> UnitDensity? {
    switch object {
      case "lb/gal": return .poundsPerGallon
      case "kg/L": return .kilogramsPerLiter
      default: return nil
    }
  }
}

public struct UnitLengthBridge: Defaults.Bridge, Sendable {
  public typealias Value = UnitLength
  public typealias Serializable = String

  public func serialize(_ value: UnitLength?) -> String? {
    value?.symbol
  }

  public func deserialize(_ object: String?) -> UnitLength? {
    switch object {
      case "ft": return .feet
      case "m": return .meters
      case "nmi": return .nauticalMiles
      case "km": return .kilometers
      case "mi": return .miles
      default: return nil
    }
  }
}

public struct UnitSpeedBridge: Defaults.Bridge, Sendable {
  public typealias Value = UnitSpeed
  public typealias Serializable = String

  public func serialize(_ value: UnitSpeed?) -> String? {
    value?.symbol
  }

  public func deserialize(_ object: String?) -> UnitSpeed? {
    switch object {
      case "kn", "kt": return .knots
      case "km/h": return .kilometersPerHour
      case "mph": return .milesPerHour
      default: return nil
    }
  }
}

public struct UnitTemperatureBridge: Defaults.Bridge, Sendable {
  public typealias Value = UnitTemperature
  public typealias Serializable = String

  public func serialize(_ value: UnitTemperature?) -> String? {
    value?.symbol
  }

  public func deserialize(_ object: String?) -> UnitTemperature? {
    switch object {
      case "°C": return .celsius
      case "°F": return .fahrenheit
      default: return nil
    }
  }
}

public struct UnitPressureBridge: Defaults.Bridge, Sendable {
  public typealias Value = UnitPressure
  public typealias Serializable = String

  public func serialize(_ value: UnitPressure?) -> String? {
    value?.symbol
  }

  public func deserialize(_ object: String?) -> UnitPressure? {
    switch object {
      case "inHg": return .inchesOfMercury
      case "hPa": return .hectopascals
      default: return nil
    }
  }
}

extension UnitMass: Defaults.Serializable {
  public static let bridge = UnitMassBridge()
}

extension UnitVolume: Defaults.Serializable {
  public static let bridge = UnitVolumeBridge()
}

extension UnitDensity: Defaults.Serializable {
  public static let bridge = UnitDensityBridge()
}

extension UnitLength: Defaults.Serializable {
  public static let bridge = UnitLengthBridge()
}

extension UnitSpeed: Defaults.Serializable {
  public static let bridge = UnitSpeedBridge()
}

extension UnitTemperature: Defaults.Serializable {
  public static let bridge = UnitTemperatureBridge()
}

extension UnitPressure: Defaults.Serializable {
  public static let bridge = UnitPressureBridge()
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
