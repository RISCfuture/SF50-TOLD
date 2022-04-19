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
            
            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
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
    
    private func takeoffRollModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -1382.43 - 0.210407*pressureAlt + 0.0000206701*pow(pressureAlt, 2)
            - 34.6806*temp + 0.00403706*pressureAlt*temp + 0.790156*pow(temp, 2)
            + 0.823508*weight + 0.0000293076*pressureAlt*weight
            + 0.00496562*temp*weight + 2.46892e-7*pressureAlt*temp*weight
            - 0.0000504959*pow(weight, 2)
    }
    
    private func takeoffDistanceModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -1501 - 0.425876*pressureAlt + 0.0000319546*pow(pressureAlt, 2)
            - 67.906*temp + 0.00330889*pressureAlt*temp + 1.25352*pow(temp, 2)
            + 0.857987*weight + 0.0000618535*pressureAlt*weight
            + 0.00992476*temp*weight + 9.52756e-7*pressureAlt*temp*weight
            - 0.0000305466*pow(weight, 2)
    }
    
    private func landingRollModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        489.494 - 0.0367061*pressureAlt + 3.59535e-6*pow(pressureAlt, 2)
            - 0.437313*temp + 0.00018658*pressureAlt*temp - 0.00123224*pow(temp, 2)
            + 0.0937324*weight + 0.0000142284*pressureAlt*weight + 0.00110728*temp*weight
            + 6.97652e-9*pressureAlt*temp*weight + 0.0000173626*pow(weight, 2)
    }
    
    private func landingRollModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        653.481 - 0.0534954*pressureAlt + 5.08827e-6*pow(pressureAlt, 2)
            - 0.524595*temp + 0.000216905*pressureAlt*temp - 0.00386111*pow(temp, 2)
            + 0.12391*weight + 0.0000190989*pressureAlt*weight
            + 0.00145229*temp*weight + 2.06111e-8*pressureAlt*temp*weight
            + 0.0000227563*pow(weight, 2)
    }
    
    private func landingRollModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        2470.86 + 0.191851*weight - 0.0000191851*pow(weight, 2)
            + 0.0732799*pressureAlt + 5.72651e-20*weight*pressureAlt
            + 7.4831e-6*pow(pressureAlt, 2) + 10.3618*temp
            + 3.06076e-17*weight*temp + 0.000544*pressureAlt*temp
            - 2.54158e-21*weight*pressureAlt*temp - 4.20536e-15*pow(temp, 2)
    }
    
    private func landingDistanceModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        164.713 - 0.0530245*pressureAlt + 4.94734e-6*pow(pressureAlt, 2)
            - 0.646999*temp + 0.000314351*pressureAlt*temp - 0.0000877975*pow(temp, 2)
            + 0.141972*weight + 0.0000184321*pressureAlt*weight + 0.00136939*temp*weight
            - 4.22073e-9*pressureAlt*temp*weight + 0.0000482159*pow(weight, 2)
    }
    
    private func landingDistanceModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        259.201 - 0.0901406*pressureAlt + 6.91078e-6*pow(pressureAlt, 2)
            - 1.61071*temp + 0.000219209*pressureAlt*temp - 0.00467595*pow(temp, 2)
            + 0.18085*weight + 0.0000277562*pressureAlt*weight
            + 0.00199616*temp*weight + 4.11752e-8*pressureAlt*temp*weight
            + 0.0000588788*pow(weight, 2)
    }
    
    private func landingDistanceModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1395.53 + 0.322528*weight + 0.0000707841*pow(weight, 2)
            - 0.083997*pressureAlt + 0.0000372718*weight*pressureAlt
            + 0.0000117844*pow(pressureAlt, 2) + 3.60932*temp
            + 0.00229182*weight*temp - 0.0000174545*pressureAlt*temp
            + 1.73455e-7*weight*pressureAlt*temp + 0.00306818*pow(temp, 2)
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
    
    private func tailwindTotalDistanceModel(weight: Double) -> Double {
        0.0451667 - 1e-6*weight
    }
    
    private func downhillGradientGroundRunFactorModel(weight: Double) -> Double {
        -1.16667 + 0.001*weight
    }
    
    private func uphillGradientGroundRunFactorModel(weight: Double) -> Double {
        3 + 0.002*weight
    }
}

fileprivate func offscale(low: Bool, high: Bool) -> Offscale {
    if high { return .high }
    else if low { return .low }
    else { return .none }
}
