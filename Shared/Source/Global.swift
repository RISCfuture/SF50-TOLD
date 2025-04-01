import Defaults
import Foundation
import SwiftNASR

private let groupDefaults = UserDefaults(suiteName: "group.codes.tim.TOLD")!

extension Defaults.Keys {
    static let emptyWeight = Key<Double>("SF50_emptyWeight", default: 3550, suite: groupDefaults) // lbs
    static let fuelDensity = Key<Double>("SF50_fuelDensity", default: 6.71, suite: groupDefaults) // lb/gal
    static let safetyFactor = Key<Double>("SF50_safetyFactor", default: 1.0, suite: groupDefaults)
    static let updatedThrustSchedule = Key<Bool>("SF50_updatedThrustSchedule", default: false, suite: groupDefaults)

    static let favoriteAirports = Key<Set<String>>("favoriteAirports", default: [])
    static let recentAirports = Key<[String]>("recentAirports", default: [])

    static let payload = Key<Double>("SF50_payload", default: 0.0) // lbs
    static let takeoffFuel = Key<Double>("SF50_takeoffFuel", default: 0.0, suite: groupDefaults) // gal
    static let landingFuel = Key<Double>("SF50_landingFuel", default: 0.0, suite: groupDefaults) // gal

    static let takeoffAirport = Key<String?>("SF50_takeoffAirport", suite: groupDefaults) // site #
    static let landingAirport = Key<String?>("SF50_landingAirport", suite: groupDefaults) // site #

    static let lastCycleLoaded = Key<Cycle?>("lastCycleLoaded", suite: groupDefaults)
    static let schemaVersion = Key<Int>("schemaVersion", default: 0, suite: groupDefaults)
    static let initialSetupComplete = Key<Bool>("SF50_initialSetupComplete", default: false, suite: groupDefaults)
}

enum Offscale {
    case none
    case low
    case high
}

enum Interpolation {
    case value(_ number: Double, offscale: Offscale = .none)
    case configNotAuthorized
}

enum Operation {
    case takeoff
    case landing
}

enum FlapSetting: String, CaseIterable, Identifiable {
    case flapsUp
    case flapsUpIce
    case flaps50
    case flaps50Ice
    case flaps100

    var id: String { self.rawValue }
}

enum StepProgress: Equatable {
    case pending
    case inProgress(current: UInt64, total: UInt64)
    case indeterminate
    case complete

    var isLoading: Bool {
        switch self {
            case .pending: return false
            case .inProgress: return true
            case .indeterminate: return true
            case .complete: return false
        }
    }
}

func crosswindLimitForFlapSetting(_ flaps: FlapSetting?) -> UInt? {
    switch flaps {
        case .flapsUp, .flapsUpIce, .flaps50, .flaps50Ice: 18
        case .flaps100: 16
        case .none: nil
    }
}

let maxFuel = 296.0 // gal
let maxTakeoffWeight = 6000.0 // lbs
let maxLandingWeight = 5550.0 // lbs
let minRunwayLength = 1400 // ft
let minTemperature = -40.0 // °C
let maxTemperature = 50.0 // °C
let tailwindLimit: UInt = 10 // kts

var standardTemperature = 15.04
var standardSLP = 29.921

let latestSchemaVersion = 2
