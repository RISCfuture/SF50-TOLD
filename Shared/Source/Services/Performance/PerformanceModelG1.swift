import Foundation
import SwiftMETAR
import Combine
import Defaults

struct PerformanceModelG1: PerformanceModel {
    var runway: Runway?
    var weather: Weather
    var weight: Double
    var flaps: FlapSetting? = nil
    
    init(runway: Runway?, weather: Weather, weight: Double, flaps: FlapSetting?) {
        self.runway = runway
        self.weather = weather
        self.weight = weight
        self.flaps = flaps
    }
    
    // feet
    var takeoffRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffRollModel(weight: weight, pressureAlt: pa, temp: temp)
            
            distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
            distance *= (1 + 0.04*tailwind) // 40% for every 10 knots of tailwind
            
            distance *= (1 - takeoffRollModel_downhillGradientFactor(weight)*downhillGradient)
            distance *= (1 + takeoffRollModel_uphillGradientFactor(weight: weight)*uphillGradient)
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 5000 { offscaleLow = true }
            if weight > maxTakeoffWeight { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -20 { offscaleLow = true }
            if temp > 50 { offscaleHigh = true }
            
            if let takeoffPermitted, !takeoffPermitted { offscaleHigh = true }
            
            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // feet
    var takeoffDistance: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffDistanceModel(weight: weight, pressureAlt: pa, temp: temp)
            
            distance *= (1 - 0.006*headwind) // 6% for every 10 knots of headwind
            distance *= (1 + takeoffDistanceModel_tailwindFactor(weight)*tailwind)
            
            if runway.turf { distance *= 1.21 } // 21% for unpaved runway
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 5000 { offscaleLow = true }
            if weight > maxTakeoffWeight { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -20 { offscaleLow = true }
            if temp > 50 { offscaleHigh = true }
            
            if let takeoffPermitted, !takeoffPermitted { offscaleHigh = true }
            
            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    var takeoffPermitted: Bool? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            
            let maxPA = takeoffMaxPAModel(weight: weight, temp: temp)
            return pa <= maxPA
        }
    }
    
    // feet
    var landingRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance: Double
            var factor = 1.0
            
            switch flaps {
                case .flapsUp:
                    distance = landingRollModel_flaps50(weight: weight, pressureAlt: pa, temp: temp)
                    factor = 1.35
                case .flapsUpIce:
                    distance = landingRollModel_flaps50Ice(weight: weight, pressureAlt: pa, temp: temp)
                    factor = 1.35
                case .flaps50:
                    distance = landingRollModel_flaps50(weight: weight, pressureAlt: pa, temp: temp)
                case .flaps50Ice:
                    distance = landingRollModel_flaps50Ice(weight: weight, pressureAlt: pa, temp: temp)
                case .flaps100:
                    distance = landingRollModel_flaps100(weight: weight, pressureAlt: pa, temp: temp)
                case .none: return nil
            }
            
            distance *= factor
            
            switch flaps {
                case .flaps100:
                    distance *= (1 - 0.008*headwind) // 8% for every 10 knots of headwind
                    distance *= (1 + 0.049*tailwind) // 49% for every 10 knots of tailwind
                case .flaps50, .flapsUp:
                    distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
                    distance *= (1 + 0.042*tailwind) // 42% for every 10 knots of tailwind
                case .flaps50Ice, .flapsUpIce:
                    distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
                    distance *= (1 + 0.037*tailwind) // 37% for every 10 knots of tailwind
                case .none: return nil
            }
            
            switch flaps {
                case .flaps100, .flaps50, .flapsUp:
                    distance *= (1 + 0.06*downhillGradient) // 6% for every 1% of downhill gradient
                    distance *= (1 - 0.05*uphillGradient) // 5% for every 1% of uphill gradient
                case .flaps50Ice, .flapsUpIce:
                    distance *= (1 + 0.07*downhillGradient) // 7% for every 1% of downhill gradient
                    distance *= (1 - 0.06*uphillGradient) // 6% for every 1% of uphill gradient
                case .none: return nil
            }
            
            switch runway.contamination {
                case let .waterOrSlush(depth):
                    distance += landingDistanceIncrease_waterSlush(distance, depth: Double(depth))
                case let .slushOrWetSnow(depth):
                    distance += landingDistanceIncrease_slushWetSnow(distance, depth: Double(depth))
                case .drySnow:
                    distance += landingDistanceIncrease_drySnow(distance)
                case .compactSnow:
                    distance += landingDistanceIncrease_compactSnow(distance)
                case .none: break
            }
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 4500 { offscaleLow = true }
            if weight > 5550 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            switch flaps {
                case .flaps50Ice, .flapsUpIce:
                    if temp < -20 { offscaleLow = true }
                    if temp > 10 { offscaleHigh = true }
                default:
                    if temp < 0 { offscaleLow = true }
                    if temp > 50 { offscaleHigh = true }
            }
            
            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // feet
    var landingDistance: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance: Double
            
            switch flaps {
                case .flapsUp, .flapsUpIce: return .configNotAuthorized
                case .flaps50:
                    distance = landingDistanceModel_flaps50(weight: weight, pressureAlt: pa, temp: temp)
                case .flaps50Ice:
                    distance = landingDistanceModel_flaps50Ice(weight: weight, pressureAlt: pa, temp: temp)
                case .flaps100:
                    distance = landingDistanceModel_flaps100(weight: weight, pressureAlt: pa, temp: temp)
                case .none: return nil
            }
            
            switch flaps {
                case .flaps100:
                    distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
                    distance *= (1 + landingDistanceModel_flaps100_tailwindFactor(weight)*tailwind)
                case .flaps50, .flapsUp:
                    distance *= (1 - landingDistanceModel_flaps50_headwindFactor(weight)*headwind)
                    distance *= (1 + landingDistanceModel_flaps50_tailwindFactor(weight)*tailwind)
                case .flaps50Ice, .flapsUpIce:
                    distance *= (1 - 0.006*headwind) // 6% for every 10 knots of headwind
                    distance *= (1 + landingDistanceModel_flaps50Ice_tailwindFactor(weight)*tailwind)
                case .none: return nil
            }
            
            if runway.turf { distance *= 1.2 } // 20% for unpaved runway

            if let contamination = runway.contamination,
               case let .value(roll, _) = landingRoll {

                switch contamination {
                    case let .waterOrSlush(depth):
                        distance += landingDistanceIncrease_waterSlush(roll, depth: Double(depth))
                    case let .slushOrWetSnow(depth):
                        distance += landingDistanceIncrease_slushWetSnow(roll, depth: Double(depth))
                    case .drySnow:
                        distance += landingDistanceIncrease_drySnow(roll)
                    case .compactSnow:
                        distance += landingDistanceIncrease_compactSnow(roll)
                }
            }

            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 4500 { offscaleLow = true }
            if weight > 5550 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            switch flaps {
                case .flaps50Ice, .flapsUpIce:
                    if temp < -20 { offscaleLow = true }
                    if temp > 10 { offscaleHigh = true }
                default:
                    if temp < 0 { offscaleLow = true }
                    if temp > 50 { offscaleHigh = true }
            }
            
            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // ft/NM
    var takeoffClimbGradient: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            let gradient = takeoffClimbGradientModel(weight: weight, pressureAlt: pa, temp: temp)
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 4500 { offscaleLow = true }
            if weight > maxTakeoffWeight { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -40 { offscaleLow = true }
            if temp > 50 { offscaleHigh = true }
            
            return .value(gradient, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // ft/min
    var takeoffClimbRate: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            let rate = takeoffClimbRateModel(weight: weight, pressureAlt: pa, temp: temp)
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 4500 { offscaleLow = true }
            if weight > maxTakeoffWeight { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -40 { offscaleLow = true }
            if temp > 50 { offscaleHigh = true }
            
            return .value(rate, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // knots
    var vref: Interpolation? {
        return ifInitialized { runway, _, weight in
            switch flaps {
                case .flapsUp:
                    let speed = vrefModel_flapsUp(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > maxTakeoffWeight))
                case .flapsUpIce:
                    let speed = vrefModel_flapsUpIce(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > maxTakeoffWeight))
                case .flaps50:
                    let speed = vrefModel_flaps50(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > maxTakeoffWeight))
                case .flaps50Ice:
                    let speed = vrefModel_flaps50Ice(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > maxTakeoffWeight))
                case .flaps100:
                    let speed = vrefModel_flaps100(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > maxTakeoffWeight))
                case .none: return nil
            }
        }
    }
    
    var meetsGoAroundClimbGradient: Bool? {
        return ifInitialized { runway, weather, weight in
            let temp = weather.temperature(at: Double(runway.elevation))
            let pressureAlt = weather.pressureAltitude(elevation: Double(runway.elevation))
            
            switch flaps {
                case.flaps100:
                    return pressureAlt <= landingMaxPAModel_flaps100(weight: weight, temp: temp)
                case .flaps50:
                    return pressureAlt <= landingMaxPAModel_flaps50(weight: weight, temp: temp)
                default: return nil
            }
        }
    }
    
    private func ifInitialized<T>(_ block: (_ runway: Runway, _ weather: Weather, _ weight: Double) -> T?) -> T? {
        runway.flatMap { block($0, weather, weight) }
    }
    
    private func takeoffRollModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -2.0436e2 +
        (3.8053e-1 * weight) + (-1.8965e-1 * pressureAlt) + (-4.1193e1 * temp) +
        (-5.8280e-6 * pow(weight, 2)) + (2.8427e-5 * weight*pressureAlt) + (6.9222e-3 * weight*temp) +
        (2.1791e-5 * pow(pressureAlt, 2)) + (6.5349e-3 * pressureAlt*temp) + (9.5348e-1 * pow(temp, 2))
    }
    
    private func takeoffDistanceModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        7.1574e2 +
        (4.2206e-2 * weight) + (-4.9182e-1 * pressureAlt) + (-1.1200e2 * temp) +
        (5.3191e-5 * pow(weight, 2)) + (7.7690e-5 * weight*pressureAlt) + (1.9044e-2 * weight*temp) +
        (3.5855e-5 * pow(pressureAlt, 2)) + (1.1057e-2 * pressureAlt*temp) + (1.6254 * pow(temp, 2))
    }
    
    private func landingRollModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        7.2020e2 +
        (2.6738e-9 * weight) + (-3.5169e-2 * pressureAlt) + (-5.6797e-1 * temp) +
        (2.6761e-5 * pow(weight, 2)) + (1.4003e-5 * weight*pressureAlt) + (1.1366e-3 * weight*temp) +
        (3.5464e-6 * pow(pressureAlt, 2)) + (2.1973e-4 * pressureAlt*temp) + (-1.8795e-3 * pow(temp, 2))
    }
    
    private func landingRollModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        9.6659e2 +
        (3.4451e-9 * weight) + (-5.3996e-2 * pressureAlt) + (-1.3803 * temp) +
        (3.4856e-5 * pow(weight, 2)) + (1.9392e-5 * weight*pressureAlt) + (1.5984e-3 * weight*temp) +
        (4.9831e-6 * pow(pressureAlt, 2)) + (3.1874e-4 * pressureAlt*temp) + (-7.5959e-4 * pow(temp, 2))
    }
    
    private func landingRollModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1.3444e3 +
        (4.7428e-9 * weight) + (-6.4257e-2 * pressureAlt) + (-2.429 * temp) +
        (5.0316e-5 * pow(weight, 2)) + (2.5805e-5 * weight*pressureAlt) + (2.3255e-3 * weight*temp) +
        (6.6757e-6 * pow(pressureAlt, 2)) + (4.8327e-4 * pressureAlt*temp) + (-2.2727e-4 * pow(temp, 2))
    }
    
    private func landingDistanceModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        5.1171e2 +
        (6.2355e-9 * weight) + (-4.9637e-2 * pressureAlt) + (-5.8964e-1 * temp) +
        (6.2552e-5 * pow(weight, 2)) + (1.7868e-5 * weight*pressureAlt) + (1.3606e-3 * weight*temp) +
        (4.8777e-6 * pow(pressureAlt, 2)) + (2.9182e-4 * pressureAlt*temp) + (-8.2664e-4 * pow(temp, 2))
    }
    
    private func landingDistanceModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        7.1788e2 +
        (7.5566e-9 * weight) + (-9.1626e-2 * pressureAlt) + (-3.0478 * temp) +
        (7.6459e-5 * pow(weight, 2)) + (2.8356e-5 * weight*pressureAlt) + (2.2528e-3 * weight*temp) +
        (6.7495e-6 * pow(pressureAlt, 2)) + (4.2044e-4 * pressureAlt*temp) + (-5.8716e-4 * pow(temp, 2))
    }
    
    private func landingDistanceModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        9.0058e2 +
        (1.0586e-8 * weight) + (-1.6374e-1 * pressureAlt) + (-9.5898 * temp) +
        (1.1685e-4 * pow(weight, 2)) + (4.9574e-5 * weight*pressureAlt) + (4.3879e-3 * weight*temp) +
        (9.5954e-6 * pow(pressureAlt, 2)) + (6.9168e-4 * pressureAlt*temp) + (1.1364e-3 * pow(temp, 2))
    }
    
    private func landingDistanceIncrease_waterSlush(_ dist: Double, depth: Double) -> Double {
        9.1011e2 +
        (-7.1383e3 * depth) + (1.8952 * dist) +
        (1.1439e4 * pow(depth, 2)) + (-1.3195 * depth*dist) + (-9.6834e-8 * pow(dist, 2))
    }
    
    private func landingDistanceIncrease_slushWetSnow(_ dist: Double, depth: Double) -> Double {
        6.8375e1 +
        (-4.7883e2 * depth) + (1.6923 * dist) +
        (7.6518e2 * pow(depth, 2)) + (-6.2368e-1 * depth*dist) + (3.3037e-7 * pow(dist, 2))
    }
    
    // 1 in
    private func landingDistanceIncrease_drySnow(_ dist: Double) -> Double {
        4.4607 + (1.3301 * dist) + (-5.6961e-8 * pow(dist, 2))
    }
    
    private func landingDistanceIncrease_compactSnow(_ dist: Double) -> Double {
        5.6159 + (1.5774 * dist) + (2.2784e-7 * pow(dist, 2))
    }
    
    private func takeoffClimbGradientModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        5.2226e3 +
        (-9.5451e-1 * weight) + (-1.0627e-1 * pressureAlt) + (-1.7494e1 * temp) +
        (4.9366e-5 * pow(weight, 2)) + (1.1535e-5 * weight*pressureAlt) + (2.1734e-3 * weight*temp) +
        (-7.4200e-7 * pow(pressureAlt, 2)) + (-6.5195e-4 * pressureAlt*temp) + (-1.6899e-1 * pow(temp, 2))
    }
    
    private func takeoffClimbRateModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        8.4228e3 +
        (-1.5693 * weight) + (-1.0703e-1 * pressureAlt) + (-3.8023e1 * temp) +
        (8.3187e-5 * pow(weight, 2)) + (1.1791e-5 * weight*pressureAlt) + (4.7010e-3 * weight*temp) +
        (-1.9026e-6 * pow(pressureAlt, 2)) + (-1.1778e-3 * pressureAlt*temp) + (-2.3833e-1 * pow(temp, 2))
    }
    
    private func vrefModel_flapsUp(weight: Double) -> Double {
        2.94e1 + (1.8371e-2 * weight) + (-8.5714e-7 * pow(weight, 2))
    }
    
    private func vrefModel_flapsUpIce(weight: Double) -> Double {
        4.4e1 + (2.1171e-2 * weight) + (-8.5714e-7 * pow(weight, 2))
    }
    
    private func vrefModel_flaps50(weight: Double) -> Double {
        3.92e1 + (1.1857e-2 * weight) + (-2.8571e-7 * pow(weight, 2))
    }
    
    private func vrefModel_flaps50Ice(weight: Double) -> Double {
        3.34e1 + (1.9571e-2 * weight) + (-8.5714e-7 * pow(weight, 2))
    }
    
    private func vrefModel_flaps100(weight: Double) -> Double {
        1.4400e1 + (1.7571e-2 * weight) + (-8.5714e-7 * pow(weight, 2))
    }
    
    private func takeoffMaxPAModel(weight: Double, temp: Double) -> Double {
        49000 - 400*temp - 4*weight
    }
    
    private func landingMaxPAModel_flaps100(weight: Double, temp: Double) -> Double {
        38792.2 - 354.545*temp - 3.85281*weight
    }
    
    private func landingMaxPAModel_flaps50(weight: Double, temp: Double) -> Double {
        56428.6 - 500*temp - 4.7619*weight
    }
    
    private var takeoffDistanceModel_tailwindFactor = interpolation(weights: [5000, 5500, 6000], values: [0.036, 0.036, 0.035])
    private var takeoffRollModel_downhillGradientFactor = interpolation(weights: [5000, 5500, 6000], values: [0.01, 0.01, 0.02])
    private func takeoffRollModel_uphillGradientFactor(weight: Double) -> Double {
        0.02 + 0.00002*weight
    }
    
    private var landingDistanceModel_flaps100_tailwindFactor = interpolation(weights: [4500, 5550], values: [0.045, 0.044])
    private var landingDistanceModel_flaps50_headwindFactor = interpolation(weights: [4500, 5550], values: [0.007, 0.006])
    private var landingDistanceModel_flaps50_tailwindFactor = interpolation(weights: [4500, 5550], values: [0.039, 0.038])
    private var landingDistanceModel_flaps50Ice_tailwindFactor = interpolation(weights: [4500, 5550], values: [0.034, 0.033])
}
