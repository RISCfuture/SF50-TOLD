import Foundation
import SwiftMETAR
import Combine
import Defaults

struct PerformanceModelG2: PerformanceModel {
    var runway: Runway?
    var weather: Weather
    var weight: Double
    var ac: Bool
    
    // feet
    var takeoffRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffRollModel(weight: weight, pressureAlt: pa, temp: temp)
            
            distance *= (1 - 0.0083*headwind) // 10% for every 12 knots of headwind
            distance *= (1 + 0.05*tailwind) // 10% for every 2 knots of tailwind
            
            let upslopeCorr = upslopeCorrection(alt: Double(runway.elevation))/100.0
            let downslopeCorr = downslopeCorrection(alt: Double(runway.elevation))/100.0
            distance *= (1 + upslopeCorr*uphillGradient)
            distance *= (1 - downslopeCorr*downhillGradient)
            
            if runway.turf {
                if runway.isWet { distance *= 1.3 }
                else { distance *= 1.2 }
            }
            
            if ac { distance += 100 }
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 2900 { offscaleLow = true }
            if weight > 3400 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < 0 { offscaleLow = true }
            if temp > 40 { offscaleHigh = true }
            
            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // feet
    var takeoffDistance: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffDistanceModel(weight: weight, pressureAlt: pa, temp: temp)
            
            distance *= (1 - 0.0083*headwind) // 10% for every 12 knots of headwind
            distance *= (1 + 0.05*tailwind) // 10% for every 2 knots of tailwind
            
            let upslopeCorr = upslopeCorrection(alt: Double(runway.elevation))/100.0
            let downslopeCorr = downslopeCorrection(alt: Double(runway.elevation))/100.0
            let groundRoll = takeoffRollModel(weight: weight, pressureAlt: pa, temp: temp)
            distance += groundRoll * upslopeCorr*uphillGradient
            distance += groundRoll * downslopeCorr*downhillGradient

            if runway.turf { distance *= 1.21 } // 21% for unpaved runway
            
            if ac { distance += 150 }
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if weight < 2900 { offscaleLow = true }
            if weight > 3400 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < 0 { offscaleLow = true }
            if temp > 40 { offscaleHigh = true }

            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // feet
    var landingRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = landingRollModel(pressureAlt: pa, temp: temp)
                            
            distance *= (1 - 0.00769*headwind) // 10% for every 13 knots of headwind
            distance *= (1 + 0.05*tailwind) // 10% for every 2 knots of tailwind
            
            distance *= (1 + 27*downhillGradient) // 27% for every 1% of downhill gradient
            distance *= (1 - 10*downhillGradient) // 9% for every 1% of uphill gradient
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < 0 { offscaleLow = true }
            if temp > 40 { offscaleHigh = true }

            return .value(distance, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // feet
    var landingDistance: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = landingDistanceModel(pressureAlt: pa, temp: temp)
                
            distance *= (1 - 0.00769*headwind) // 10% for every 13 knots of headwind
            distance *= (1 + 0.05*tailwind) // 10% for every 2 knots of tailwind

            if runway.turf {
                if runway.isWet { distance *= 1.6 }
                else { distance *= 1.2 }
            }
            
            distance *= Defaults[.safetyFactor]
            
            var offscaleLow = false
            var offscaleHigh = false
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < 0 { offscaleLow = true }
            if temp > 40 { offscaleHigh = true }

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
            if weight < 2900 { offscaleLow = true }
            if weight > 3400 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -20 { offscaleLow = true }
            if temp > 40 { offscaleHigh = true }
            
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
            if weight < 2900 { offscaleLow = true }
            if weight > 3400 { offscaleHigh = true }
            if pa < -100 { offscaleLow = true } // add a little slop because the PA equation isn't exact
            if pa > 10000 { offscaleHigh = true }
            if temp < -20 { offscaleLow = true }
            if temp > 40 { offscaleHigh = true }

            return .value(rate, offscale: offscale(low: offscaleLow, high: offscaleHigh))
        }
    }
    
    // kts
    var climbSpeed: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            return .value(climbSpeedModel(pressureAlt: pa))
        }
    }
    
    private func ifInitialized<T>(_ block: (_ runway: Runway, _ weather: Weather, _ weight: Double) -> T?) -> T? {
        guard let runway = runway else { return nil }
        
        return block(runway, weather, weight)
    }
    
    private func upslopeCorrection(alt: Double) -> Double {
        22 + 0.0011*alt + 1e-7*pow(alt, 2)
    }
    
    private func downslopeCorrection(alt: Double) -> Double {
        7 + 0.0005*alt + 2e-8*pow(alt, 2)
    }
    
    private func takeoffRollModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -164.773 + 0.0861505*weight + 0.0000689366*pow(weight, 2) - 0.298454*pressureAlt +
            0.000109538*weight*pressureAlt + 8.75258e-6*pow(pressureAlt, 2) - 10.8358*temp + 0.00495051*weight*temp -
            0.00146685*pressureAlt*temp + 8.32272e-7*weight*pressureAlt*temp + 0.0195952*pow(temp, 2)
    }
    
    private func takeoffDistanceModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -223.256 + 0.134753*weight + 0.000104501*pow(weight, 2) - 0.420776*pressureAlt +
            0.000157026*weight*pressureAlt + 0.0000126094*pow(pressureAlt, 2) - 14.9037*temp + 0.007004*weight*temp -
            0.00188705*pressureAlt*temp + 1.10726e-6*weight*pressureAlt*temp + 0.0245811*pow(temp, 2)
    }
    
    private func landingRollModel(pressureAlt: Double, temp: Double) -> Double {
        1083.55 + 0.0373299*pressureAlt + 1.16104e-6*pow(pressureAlt, 2) + 3.89933*temp +
            0.00018073*pressureAlt*temp - 0.00010501*pow(temp, 2)
    }
    
    private func landingDistanceModel(pressureAlt: Double, temp: Double) -> Double {
        2265.4 + 0.049699*pressureAlt + 2.20131e-6*pow(pressureAlt, 2) + 5.36541*temp +
            0.000364079*pressureAlt*temp + 0.001683*pow(temp, 2)
    }
    
    private func takeoffClimbGradientModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1556.38 + 0.102354*weight - 0.0000871721*pow(weight, 2) - 0.108429*pressureAlt +
            0.0000162652*weight*pressureAlt + 5.77785e-7*pow(pressureAlt, 2) - 4.9594*temp + 0.000827346*weight*temp +
            0.000101996*pressureAlt*temp - 1.87299e-8*weight*pressureAlt*temp + 0.000569573*pow(temp, 2)
    }
    
    private func takeoffClimbRateModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        2275.37 + 0.149654*weight - 0.000127432*pow(weight, 2) - 0.125758*pressureAlt +
            0.0000199756*weight*pressureAlt + 4.02373e-8*pow(pressureAlt, 2) - 2.15982*temp + 0.000478051*weight*temp +
            0.000372012*pressureAlt*temp - 1.65269e-7*weight*pressureAlt*temp - 0.0016434*pow(temp, 2)
    }
    
    private func climbSpeedModel(pressureAlt: Double) -> Double {
        91.0 - 0.000564286*pressureAlt + 1.78571e-8*pow(pressureAlt, 2)
    }
}
