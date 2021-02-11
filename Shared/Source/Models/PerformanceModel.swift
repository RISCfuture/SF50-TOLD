import Foundation
import SwiftMETAR
import Combine
import Defaults

struct PerformanceModel {
    var runway: Runway?
    var weather: Weather
    var weight: Double
    var flaps: FlapSetting? = nil
    
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
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffRollModel(weight: weight, pressureAlt: pa, temp: temp)
            
            distance *= (1 - 0.007*headwind) // 7% for every 10 knots of headwind
            distance *= (1 + 0.04*tailwind) // 40% for every 10 knots of tailwind
            
            distance *= (1 - 2*downhillGradient) // 2% for every 1% of downhill gradient
            distance *= (1 + 14*uphillGradient) // 14% for every 1% of uphill gradient
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 5000 { offscaleLow = true }
            if weight > 6000 { offscaleHigh = true }
            if pa < 0 { offscaleLow = true }
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
            
            distance *= (1 - 0.006*headwind) // 6% for every 10 knots of headwind
            distance *= (1 + 0.035*tailwind) // 35% for every 10 knots of tailwind
            
            if runway.turf { distance *= 1.21 } // 21% for unpaved runway
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 5000 { offscaleLow = true }
            if weight > 6000 { offscaleHigh = true }
            if pa < 0 { offscaleLow = true }
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
            if pa < 0 { offscaleLow = true }
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
            if pa < 0 { offscaleLow = true }
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
            var gradient = takeoffClimbGradientModel(weight: weight, pressureAlt: pa, temp: temp)
            
            gradient *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 4500 { offscaleLow = true }
            if weight > 6000 { offscaleHigh = true }
            if pa < 0 { offscaleLow = true }
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
            var rate = takeoffClimbRateModel(weight: weight, pressureAlt: pa, temp: temp)
            
            rate *= Defaults[.safetyFactor]
            
            rate *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 4500 { offscaleLow = true }
            if weight > 6000 { offscaleHigh = true }
            if pa < 0 { offscaleLow = true }
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
        -197.275 + 0.399234*weight - 9.45585e-6*pow(weight, 2)
            - 0.21092*pressureAlt + 0.0000324229*pressureAlt*weight
            + 0.0000217183*pow(pressureAlt, 2) - 50.0514*temp
            + 0.00855754*weight*temp + 0.00847911*pressureAlt*temp
            - 3.57985e-7*weight*pressureAlt*temp + 0.950821*pow(temp, 2)
    }
    
    private func takeoffDistanceModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        714.938 + 0.0402663*weight + 0.0000535694*pow(weight, 2)
            - 0.489578*pressureAlt + 0.0000772696*weight*pressureAlt
            + 0.0000358613*pow(pressureAlt, 2) - 111.079*temp
            + 0.0188733*weight*temp + 0.0108537*pressureAlt*temp
            + 3.7521e-8*weight*pressureAlt*temp + 1.62572*pow(temp, 2)
    }
    
    private func landingRollModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1294.13 + 0.104398*weight - 0.0000102682*pow(weight, 2)
            + 0.0402938*pressureAlt - 3.69751e-7*weight*pressureAlt
            + 3.99551e-6*pow(pressureAlt, 2) + 5.98559*temp
            - 0.0000611486*weight*temp + 0.000205449*pressureAlt*temp
            + 8.86236e-9*weight*pressureAlt*temp - 0.00163661*pow(temp, 2)
    }
    
    private func landingRollModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1844.73 + 0.144565*weight - 0.0000146011*pow(weight, 2) +
            0.049307*pressureAlt + 2.41878e-7*weight*pressureAlt
            + 5.9718e-6*pow(pressureAlt, 2) + 7.04726*temp
            + 0.000145488*weight*temp + 0.000548356*pressureAlt*temp
            - 3.12059e-8*weight*pressureAlt*temp - 8.39093e-6*pow(temp, 2)
    }
    
    private func landingRollModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        2470.86 + 0.191851*weight - 0.0000191851*pow(weight, 2)
            + 0.0732799*pressureAlt + 5.72651e-20*weight*pressureAlt
            + 7.4831e-6*pow(pressureAlt, 2) + 10.3618*temp
            + 3.06076e-17*weight*temp + 0.000544*pressureAlt*temp
            - 2.54158e-21*weight*pressureAlt*temp - 4.20536e-15*pow(temp, 2)
    }
    
    private func landingDistanceModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        745.258 + 0.175659*weight + 0.0000393569*pow(weight, 2)
            - 0.018141*pressureAlt + 0.0000136696*weight*pressureAlt
            + 6.11232e-6*pow(pressureAlt, 2) + 2.58291*temp
            + 0.00104391*weight*temp + 0.00046088*pressureAlt*temp
            - 2.03208e-8*weight*pressureAlt*temp + 0.000239866*pow(temp, 2)
    }
    
    private func landingDistanceModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1408.02 + 0.200707*weight + 0.0000235989*pow(weight, 2)
            + 0.0172962*pressureAlt + 7.97491e-6*weight*pressureAlt
            + 7.70576e-6*pow(pressureAlt, 2) + 6.08067*temp
            + 0.0006374*weight*temp + 0.000574651*pressureAlt*temp
            - 1.60863e-8*weight*pressureAlt*temp + 0.000942593*pow(temp, 2)
    }
    
    private func landingDistanceModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1395.53 + 0.322528*weight + 0.0000707841*pow(weight, 2)
            - 0.083997*pressureAlt + 0.0000372718*weight*pressureAlt
            + 0.0000117844*pow(pressureAlt, 2) + 3.60932*temp
            + 0.00229182*weight*temp - 0.0000174545*pressureAlt*temp
            + 1.73455e-7*weight*pressureAlt*temp + 0.00306818*pow(temp, 2)
    }
    
    private func takeoffClimbGradientModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        5208.88 - 0.0889881*pressureAlt - 1.13082e-6*pow(pressureAlt, 2)
            - 0.957868*weight + 8.73354e-6*pressureAlt*weight
            + 0.0000505919*pow(weight, 2) - 14.4936*temp
            - 0.00099401*pressureAlt*temp + 0.00165187*weight*temp
            + 4.96139e-8*pressureAlt*weight*temp - 0.175661*pow(temp, 2)

    }
    
    private func takeoffClimbRateModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        8477.18 - 0.0770992*pressureAlt - 2.73029e-6*pow(pressureAlt, 2)
            - 1.60472*weight + 7.16136e-6*pressureAlt*weight
            + 0.0000880764*pow(weight, 2) - 32.1438*temp
            - 0.00196259*pressureAlt*temp + 0.00368127*weight*temp
            + 1.18543e-7*pressureAlt*weight*temp - 0.251046*pow(temp, 2)
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
}

fileprivate func deg2rad(_ degrees: Double) -> Double {
    return degrees * .pi/180
}

fileprivate func offscale(low: Bool, high: Bool) -> Offscale {
    if high { return .high }
    else if low { return .low }
    else { return .none }
}
