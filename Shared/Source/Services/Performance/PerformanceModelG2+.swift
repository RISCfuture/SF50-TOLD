import Foundation
import SwiftMETAR
import Combine
import Defaults

struct PerformanceModelG2Plus: PerformanceModel {
    var runway: Runway?
    var weather: Weather
    var weight: Double
    var flaps: FlapSetting? = nil
    
    // feet
    var takeoffRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffRollModel(weight: weight, pressureAlt: pa, temp: temp)
            
            distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
            distance *= (1 + 0.044*tailwind) // 44% for every 10 knots of tailwind
            
            distance *= (1 - downhillGradientGroundRunFactorModel(weight: weight)*downhillGradient)
            distance *= (1 + uphillGradientGroundRunFactorModel(weight: weight)*uphillGradient)
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 5000 { offscaleLow = true }
            if weight > 6000 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -20 { offscaleLow = true }
            if temp > 50 { offscaleHigh = true }
            
            if let takeoffPermitted = takeoffPermitted {
                if !takeoffPermitted { offscaleHigh = true }
            }
            
            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // feet
    var takeoffDistance: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffDistanceModel(weight: weight, pressureAlt: pa, temp: temp)
            
            distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
            distance *= (1 + tailwindTotalDistanceModel(weight: weight)*tailwind)
            
            if runway.turf { distance *= 1.21 } // 21% for unpaved runway
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 5000 { offscaleLow = true }
            if weight > 6000 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -20 { offscaleLow = true }
            if temp > 50 { offscaleHigh = true }
            
            if let takeoffPermitted = takeoffPermitted {
                if !takeoffPermitted { offscaleHigh = true }
            }
            
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
            
            distance *= (1 - 0.008*headwind) // 8% for every 10 knots of headwind
            distance *= (1 + 0.046*tailwind) // 46% for every 10 knots of tailwind
            
            distance *= (1 + 10*downhillGradient) // 10% for every 1% of downhill gradient
            distance *= (1 - 5*uphillGradient) // 5% for every 1% of uphill gradient
            
            if let contamination = runway.contamination {
                switch contamination {
                    case let .waterOrSlush(depth):
                        distance += landingDistanceIncrease_waterSlush(distance, depth: Double(depth))
                    case .slushOrWetSnow(let depth):
                        distance += landingDistanceIncrease_slushWetSnow(distance, depth: Double(depth))
                    case .drySnow:
                        distance += landingDistanceIncrease_drySnow(distance)
                    case .compactSnow:
                        distance += landingDistanceIncrease_compactSnow(distance)
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
            
            distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
            distance *= (1 + 0.041*tailwind) // 41% for every 10 knots of tailwind
            
            if runway.turf { distance *= 1.2 } // 20% for unpaved runway
            
            if let contamination = runway.contamination,
               case let .value(roll, _) = landingRoll {
                
                switch contamination {
                    case let .waterOrSlush(depth):
                        distance += landingDistanceIncrease_waterSlush(roll, depth: Double(depth))
                    case .slushOrWetSnow(let depth):
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
            if weight > 6000 { offscaleHigh = true }
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
            if weight > 6000 { offscaleHigh = true }
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
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > 6000))
                case .flapsUpIce: return .value(136)
                case .flaps50:
                    let speed = vrefModel_flaps50(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > 6000))
                case .flaps50Ice:
                    let speed = vrefModel_flaps50Ice(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > 6000))
                case .flaps100:
                    let speed = vrefModel_flaps100(weight: weight)
                    return .value(speed, offscale: offscale(low: weight < 4000, high: weight > 6000))
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
        guard let runway = runway else { return nil }
        
        return block(runway, weather, weight)
    }
    
    private func takeoffRollModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -1344.43 - 0.22722*pressureAlt + 0.0000206482*pow(pressureAlt, 2)
        - 41.1706*temp + 0.00538691*pressureAlt*temp + 0.789187*pow(temp, 2)
        + 0.826*weight + 0.000032405*pressureAlt*weight
        + 0.00615447*temp*weight - 0.0000521995*pow(weight, 2)
    }
    
    private func takeoffDistanceModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -1354.36 - 0.490758*pressureAlt + 0.00003187*pow(pressureAlt, 2)
        - 92.9508*temp + 0.00851798*pressureAlt*temp + 1.24978*pow(temp, 2)
        + 0.867605*weight + 0.0000738065*pressureAlt*weight
        + 0.0145125*temp*weight - 0.000037121*pow(weight, 2)
    }
    
    private func landingRollModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        490.68 - 0.0371989*pressureAlt + 3.59292e-6*pow(pressureAlt, 2)
        - 0.562332*temp + 0.000220394*pressureAlt*temp
        - 0.00135126*pow(temp, 2) + 0.0937236*weight
        + 0.0000143332*pressureAlt*weight + 0.0011338*temp*weight
        + 0.0000173141*pow(weight, 2)
    }
    
    private func landingRollModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        659.367 - 0.0556462*pressureAlt + 5.08485e-6*pow(pressureAlt, 2)
        - 1.04399*temp + 0.000319443*pressureAlt*temp
        - 0.00400895*pow(temp, 2) + 0.123878*weight
        + 0.0000195365*pressureAlt*weight + 0.00155772*temp*weight
        + 0.0000225265*pow(weight, 2)
    }
    
    private func landingRollModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        2470.86 + 0.191851*weight - 0.0000191851*pow(weight, 2)
            + 0.0732799*pressureAlt + 5.72651e-20*weight*pressureAlt
            + 7.4831e-6*pow(pressureAlt, 2) + 10.3618*temp
            + 3.06076e-17*weight*temp + 0.000544*pressureAlt*temp
            - 2.54158e-21*weight*pressureAlt*temp - 4.20536e-15*pow(temp, 2)
    }
    
    private func landingDistanceModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        163.996 - 0.0527264*pressureAlt + 4.94881e-6*pow(pressureAlt, 2)
        - 0.571363*temp + 0.000293894*pressureAlt*temp
        - 0.000015794*pow(temp, 2) + 0.141978*weight
        + 0.0000183687*pressureAlt*weight + 0.00135334*temp*weight
        + 0.0000482451*pow(weight, 2)
    }
    
    private func landingDistanceModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        270.96 - 0.0944373*pressureAlt + 6.90394e-6*pow(pressureAlt, 2)
        - 2.6483*temp + 0.000424051*pressureAlt*temp
        - 0.00497128*pow(temp, 2) + 0.180785*weight
        + 0.0000286303*pressureAlt*weight + 0.00220679*temp*weight
        + 0.0000584197*pow(weight, 2)
    }
    
    private func landingDistanceModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1395.53 + 0.322528*weight + 0.0000707841*pow(weight, 2)
            - 0.083997*pressureAlt + 0.0000372718*weight*pressureAlt
            + 0.0000117844*pow(pressureAlt, 2) + 3.60932*temp
            + 0.00229182*weight*temp - 0.0000174545*pressureAlt*temp
            + 1.73455e-7*weight*pressureAlt*temp + 0.00306818*pow(temp, 2)
    }
    
    private func landingDistanceIncrease_waterSlush(_ dist: Double, depth: Double) -> Double {
        -2.57617 + 83.3163*depth - 275.465*pow(depth, 2) + 280.945*pow(depth, 3)
        + 1.64345*dist - 9.23756*depth*dist + 23.6016*pow(depth, 2)*dist
        - 21.1688*pow(depth, 3)*dist
    }
    
    private func landingDistanceIncrease_slushWetSnow(_ dist: Double, depth: Double) -> Double {
        65.6394 - 478.829*depth + 765.179*pow(depth, 2) + 0.694343*dist
        - 0.623682*depth*dist
    }
    
    // 1 in
    private func landingDistanceIncrease_drySnow(_ dist: Double) -> Double {
        4.93233 + 0.329699*dist
    }
    
    private func landingDistanceIncrease_compactSnow(_ dist: Double) -> Double {
        3.72932 + 0.578797*dist
    }
    
    private func takeoffClimbGradientModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        5539.56 - 0.0873634*pressureAlt - 1.47337e-6*pow(pressureAlt, 2)
            - 9.5197*temp - 0.00131228*pressureAlt*temp - 0.168227*pow(temp, 2)
            - 1.05924*weight + 9.38506e-6*pressureAlt*weight
            + 0.00109303*temp*weight + 1.09117e-7*pressureAlt*temp*weight
            + 0.0000591182*pow(weight, 2)

    }
    
    private func takeoffClimbRateModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        8906.38 - 0.073698*pressureAlt - 3.05868e-6*pow(pressureAlt, 2)
            - 24.838*temp - 0.00235051*pressureAlt*temp - 0.241037*pow(temp, 2)
            - 1.73114*weight + 7.92607e-6*pressureAlt*weight
            + 0.00285048*temp*weight + 2.03076e-7*pressureAlt*temp*weight
            + 0.0000984818*pow(weight, 2)
    }
    
    private func vrefModel_flapsUp(weight: Double) -> Double {
        31.7702 + 0.0174768*weight - 7.78149e-7*pow(weight, 2)
    }
    
    private func vrefModel_flaps50(weight: Double) -> Double {
        42.5451 + 0.0105481*weight - 1.6364e-7*pow(weight, 2)
    }
    
    private func vrefModel_flaps50Ice(weight: Double) -> Double {
        36.7496 + 0.0182773*weight - 7.3871e-7*pow(weight, 2)
    }
    
    private func vrefModel_flaps100(weight: Double) -> Double {
        17.0545 + 0.016547*weight - 7.6355e-7*pow(weight, 2)
    }
    
    private func takeoffMaxPAModel(weight: Double, temp: Double) -> Double {
        75000 - 400*temp - 8*weight
    }
    
    private func landingMaxPAModel_flaps100(weight: Double, temp: Double) -> Double {
        43228.6 - 340*temp - 4.31746*weight
    }
    
    private func landingMaxPAModel_flaps50(weight: Double, temp: Double) -> Double {
        19285.7 - 100*temp - 0.952381*weight
    }
    
    private func tailwindTotalDistanceModel(weight: Double) -> Double {
        0.451667 - 0.00001*weight
    }
    
    private func downhillGradientGroundRunFactorModel(weight: Double) -> Double {
        -0.0116667 + 0.00001*weight
    }
    
    private func uphillGradientGroundRunFactorModel(weight: Double) -> Double {
        0.03 + 0.00002*weight
    }
}
