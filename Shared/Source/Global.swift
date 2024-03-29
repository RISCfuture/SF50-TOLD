import Foundation
import Defaults
import SwiftNASR

fileprivate let groupDefaults = UserDefaults(suiteName: "group.codes.tim.TOLD")!

extension Defaults.Keys {
    static let emptyWeight = Key<Double>("emptyWeight", default: 3550) // lbs
    static let fuelDensity = Key<Double>("fuelDensity", default: 6.71) // lb/gal
    static let safetyFactor = Key<Double>("safetyFactor", default: 1.0)
    static let updatedThrustSchedule = Key<Bool>("updatedThrustSchedule", default: false)
    
    static let favoriteAirports = Key<Set<String>>("favoriteAirports", default: [])
    static let recentAirports = Key<Array<String>>("recentAirports", default: [])
    
    static let payload = Key<Double>("payload", default: 0.0) // lbs
    
    static let takeoffAirport = Key<String?>("takeoffAirport") // site #
    static let landingAirport = Key<String?>("landingAirport") // site #
    
    static let lastCycleLoaded = Key<Cycle?>("lastCycleLoaded", suite: groupDefaults)
    static let schemaVersion = Key<Int>("schemaVersion", default: 0, suite: groupDefaults)
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
    var id: String { self.rawValue }
    
    case flapsUp
    case flapsUpIce
    case flaps50
    case flaps50Ice
    case flaps100
}

enum StepProgress: Equatable {
    case pending
    case inProgress(current: UInt64, total: UInt64)
    case indeterminate
    case complete
    
    var isLoading: Bool {
        switch self {
            case .pending: return false
            case .inProgress(_, _): return true
            case .indeterminate: return true
            case .complete: return false
        }
    }
}

func crosswindLimitForFlapSetting(_ flaps: FlapSetting?) -> UInt? {
    guard let flaps = flaps else { return nil }
    switch flaps {
        case .flapsUp, .flapsUpIce, .flaps50, .flaps50Ice: return 18
        case .flaps100: return 16
    }
}

let maxFuel = 296.0 // gal
let maxTakeoffWeight = 6000.0 // lbs
let maxLandingWeight = 5550.0 // lbs
let minRunwayLength = 1400 // ft
let minTemperature = -40.0 // °C
let maxTemperature = 50.0 // °C
let tailwindLimit: UInt = 10 // kts

let latestSchemaVersion = 2
