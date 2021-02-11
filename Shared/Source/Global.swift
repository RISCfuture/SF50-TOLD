import Foundation
import Defaults
import SwiftNASR

fileprivate let groupDefaults = UserDefaults(suiteName: "group.codes.tim.TOLD")!

extension Defaults.Keys {
    static let emptyWeight = Key<Double>("SR22G2_emptyWeight", default: 2250) // lbs
    static let fuelDensity = Key<Double>("SR22G2_fuelDensity", default: 6.01) // lb/gal
    static let safetyFactor = Key<Double>("SR22G2_safetyFactor", default: 1.0)
    static let g3Wing = Key<Bool>("g3Wing", default: false)
    
    static let favoriteAirports = Key<Set<String>>("favoriteAirports", default: [])
    static let recentAirports = Key<Array<String>>("recentAirports", default: [])
    
    static let payload = Key<Double>("SR22G2_payload", default: 0.0) // lbs
    static let takeoffFuel = Key<Double>("SR22G2_takeoffFuel", default: 0.0, suite: groupDefaults) // gal
    static let landingFuel = Key<Double>("SR22G2_landingFuel", default: 0.0, suite: groupDefaults) // gal
    static let airConditioning = Key<Bool>("SR22G2_airConditioning", default: false, suite: groupDefaults)
    
    static let takeoffAirport = Key<String?>("SR22G2_takeoffAirport", suite: groupDefaults) // site #
    static let landingAirport = Key<String?>("SR22G2_landingAirport", suite: groupDefaults) // site #
    
    static let lastCycleLoaded = Key<Cycle?>("lastCycleLoaded", suite: groupDefaults)
    static let schemaVersion = Key<Int>("schemaVersion", default: 0, suite: groupDefaults)
    static let initialSetupComplete = Key<Bool>("SR22G2_initialSetupComplete", default: false, suite: groupDefaults)
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

let g2MaxFuel = 81.0 // gal
let g3MaxFuel = 92.0 // gal
let maxTakeoffWeight = 3400.0 // lbs
let maxLandingWeight = 3400.0 // lbs
let minRunwayLength = 600 // ft
let minTemperature = -20.0 // °C
let maxTemperature = 40.0 // °C
let tailwindLimit: UInt = 10 // kts
let crosswindLimit: UInt = 20 // kts
let vref = 77 // kts

var standardTemperature = 15.04
var standardSLP = 29.921

let latestSchemaVersion = 2
