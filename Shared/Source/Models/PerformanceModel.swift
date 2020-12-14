import Foundation
import SwiftMETAR
import Combine
import Defaults

struct PerformanceModel {
    var runway: Runway?
    var weather: Weather
    var weight: Double
    var flaps: FlapSetting? = nil
    
    private let data = PerformanceData()
    
    private var isInitialized: Bool {
        runway != nil
    }
    
    private var windComponent: Double {
        guard let runwayHeading = runway?.heading else { return weather.wind.speed }
        
        return Double(weather.wind.speed) * cos(deg2rad(weather.wind.direction - Double(runwayHeading)))
    }
    
    private var headwind: Double {
        abs(max(windComponent, 0.0))
    }
    
    private var tailwind: Double {
        abs(min(windComponent, 0.0))
    }
    
    private var gradient: Double {
        runway?.slope?.doubleValue ?? 0
    }
    
    private var uphillGradient: Double {
        abs(max(gradient, 0.0))
    }
    
    private var downhillGradient: Double {
        abs(min(gradient, 0.0))
    }
    
    // feet
    var takeoffRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let distance = data.takeoffGroundRoll.interpolate(dimensions: [weight, weather.densityAltitude(elevation: Double(runway.elevation))])
            return passthroughOffscale(distance) { distance in
                var distance = distance
                distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
                distance *= (1 + 0.04*tailwind) // 40% for every 10 knots of tailwind
                
                distance *= (1 - 2*downhillGradient) // 2% for every 1% of downhill gradient
                distance *= (1 + 14*uphillGradient) // 14% for every 1% of uphill gradient
                
                distance *= Defaults[.safetyFactor]
                return .value(distance)
            }
        }
    }
    
    // feet
    var takeoffDistance: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let distance = data.takeoffOverObstacle.interpolate(dimensions: [weight, weather.densityAltitude(elevation: Double(runway.elevation))])
            return passthroughOffscale(distance) { distance in
                var distance = distance
                distance *= (1 - 0.006*headwind) // 6% for every 10 knots of headwind
                distance *= (1 + 0.035*tailwind) // 35% for every 10 knots of tailwind
                
                if runway.turf { distance *= 1.21 } // 21% for unpaved runway
                
                distance *= Defaults[.safetyFactor]
                return .value(distance)
            }
        }
    }
    
    // feet
    var landingRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let table: Table
            var factor = 1.0
            switch flaps {
                case .flapsUp:
                    table = data.landingGroundRoll_flaps50
                    factor = 1.35
                case .flapsUpIce:
                    table = data.landingGroundRoll_flaps50Ice
                    factor = 1.35
                case .flaps50:
                    table = data.landingGroundRoll_flaps50
                case .flaps50Ice:
                    table = data.landingGroundRoll_flaps50Ice
                case .flaps100:
                    table = data.landingGroundRoll_flaps100
                case .none: return nil
            }
            
            return passthroughOffscale(table.interpolate(dimensions: [weight, weather.densityAltitude(elevation: Double(runway.elevation))])) { distance in
                var distance = distance
                
                distance *= factor
                
                distance *= (1 - 0.008*headwind) // 8% for every 10 knots of headwind
                distance *= (1 + 0.046*tailwind) // 46% for every 10 knots of tailwind
                
                distance *= (1 + 10*downhillGradient) // 10% for every 1% of downhill gradient
                
                distance *= Defaults[.safetyFactor]
                return .value(distance)
            }
        }
    }
    
    // feet
    var landingDistance: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let table: Table
            switch flaps {
                case .flapsUp, .flapsUpIce: return .configNotAuthorized
                case .flaps50:
                    table = data.landingOverObstacle_flaps50
                case .flaps50Ice:
                    table = data.landingOverObstacle_flaps50Ice
                case .flaps100:
                    table = data.landingOverObstacle_flaps100
                case .none: return nil
            }
            
            return passthroughOffscale(table.interpolate(dimensions: [weight, weather.densityAltitude(elevation: Double(runway.elevation))])) { distance in
                var distance = distance
                
                distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
                distance *= (1 + 0.041*tailwind) // 41% for every 10 knots of tailwind
                
                if runway.turf { distance *= 1.2 } // 20% for unpaved runway
                
                distance *= Defaults[.safetyFactor]
                return .value(distance)
            }
        }
    }
    
    // knots
    var vref: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let table: Table
            switch flaps {
                case .flapsUp:
                    table = data.vref_flapsUp
                case .flapsUpIce: return .value(136)
                case .flaps50:
                    table = data.vref_flaps50
                case .flaps50Ice:
                    table = data.vref_flaps50Ice
                case .flaps100:
                    table = data.vref_flaps100
                case .none: return nil
            }
            
            return passthroughOffscale(table.interpolate(dimensions: [weight])) { .value($0) }
        }
    }
    
    var meetsGoAroundClimbGradient: Bool? {
        return ifInitialized { runway, weather, weight in
            let temp = weather.temperature(at: Double(runway.elevation))
            let pressureAlt = weather.pressureAltitude(elevation: Double(runway.elevation))
            
            if weight >= 5550 {
                switch flaps {
                    case .flaps100:
                        if temp >= 20 && pressureAlt >= 10_000 { return false }
                        if temp >= 30 && pressureAlt >= 7000 { return false }
                        if temp >= 40 && pressureAlt >= 3000 { return false }
                        if temp >= 50 { return false }
                    case .flaps50, .flaps50Ice, .flapsUp, .flapsUpIce:
                        if temp >= 40 && pressureAlt >= 10_000 { return false }
                        if temp >= 50 && pressureAlt >= 5000 { return false }
                    case .none: return nil
                }
            } else if weight >= 4500 {
                switch flaps {
                    case .flaps100:
                        if temp >= 40 && pressureAlt >= 9000 { return false }
                        if temp >= 50 && pressureAlt >= 7000 { return false }
                    default: return true
                }
            }
            return true
        }
    }
    
    private func ifInitialized<T>(_ block: (_ runway: Runway, _ weather: Weather, _ weight: Double) -> T?) -> T? {
        guard let runway = runway else { return nil }
        
        return block(runway, weather, weight)
    }
    
    private func passthroughOffscale(_ interpolation: Interpolation, block: (_ value: Double) -> Interpolation) -> Interpolation {
        switch interpolation {
            case .value(let number):
                return block(number)
            default: return interpolation
        }
    }
}

fileprivate func deg2rad(_ degrees: Double) -> Double {
    return degrees * .pi/180
}
