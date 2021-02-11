import Foundation
import Defaults
import SwiftNASR

extension Defaults.Keys {
    static let emptyWeight = Key<Double>("emptyWeight", default: 3550) // lbs
    static let fuelDensity = Key<Double>("fuelDensity", default: 6.71) // lb/gal
    static let safetyFactor = Key<Double>("safetyFactor", default: 1.0)
    
    static let payload = Key<Double>("payload", default: 0.0) // lbs
    
    static let takeoffAirport = Key<String?>("takeoffAirport") // site #
    static let landingAirport = Key<String?>("landingAirport") // site #
    
    static let lastCycleLoaded = Key<Cycle?>("lastCycleLoaded")
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
let minRunwayLength = 1500 // ft
let minTemperature = -40.0 // °C
let maxTemperature = 50.0 // °C
let tailwindLimit: UInt = 10 // kts
