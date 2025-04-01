import Combine
import Defaults
import Foundation
import SwiftMETAR

struct PerformanceModelG2Plus: PerformanceModel {
    var runway: Runway?
    var weather: Weather
    var weight: Double
    var flaps: FlapSetting?

    // feet
    var takeoffRoll: Interpolation? {
        return ifInitialized { runway, weather, weight in
            let pa = weather.pressureAltitude(elevation: Double(runway.elevation))
            let temp = weather.temperature(at: Double(runway.elevation))
            var distance = takeoffRollModel(weight: weight, pressureAlt: pa, temp: temp)

            print("slope \(downhillGradient) \(uphillGradient)")

            distance *= (1 - 0.007 * headwind) // 7% for every 10 knots of headwind
            distance *= (1 + 0.04 * tailwind) // 40% for every 10 knots of tailwind

            distance *= (1 - takeoffRollModel_downhillGradientFactor(weight) * downhillGradient)
            distance *= (1 + takeoffRollModel_uphillGradientFactor(weight: weight) * uphillGradient)

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

            distance *= (1 - 0.006 * headwind) // 6% for every 10 knots of headwind
            distance *= (1 + takeoffDistanceModel_tailwindFactor(weight) * tailwind)

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
                    distance *= (1 - 0.008 * headwind) // 8% for every 10 knots of headwind
                    distance *= (1 + 0.049 * tailwind) // 49% for every 10 knots of tailwind
                case .flaps50, .flapsUp:
                    distance *= (1 - 0.007 * headwind) // 7% for every 10 knots of headwind
                    distance *= (1 + 0.042 * tailwind) // 42% for every 10 knots of tailwind
                case .flaps50Ice, .flapsUpIce:
                    distance *= (1 - 0.007 * headwind) // 7% for every 10 knots of headwind
                    distance *= (1 + 0.037 * tailwind) // 37% for every 10 knots of tailwind
                case .none: return nil
            }

            switch flaps {
                case .flaps100, .flaps50, .flapsUp:
                    distance *= (1 + 0.06 * downhillGradient) // 6% for every 1% of downhill gradient
                    distance *= (1 - 0.05 * uphillGradient) // 5% for every 1% of uphill gradient
                case .flaps50Ice, .flapsUpIce:
                    distance *= (1 + 0.07 * downhillGradient) // 7% for every 1% of downhill gradient
                    distance *= (1 - 0.06 * uphillGradient) // 6% for every 1% of uphill gradient
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
                default: break
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
                    distance *= (1 - 0.007 * headwind) // 7% for every 10 knots of headwind
                    distance *= (1 + landingDistanceModel_flaps100_tailwindFactor(weight) * tailwind)
                case .flaps50, .flapsUp:
                    distance *= (1 - landingDistanceModel_flaps50_headwindFactor(weight) * headwind)
                    distance *= (1 + landingDistanceModel_flaps50_tailwindFactor(weight) * tailwind)
                case .flaps50Ice, .flapsUpIce:
                    distance *= (1 - 0.006 * headwind) // 6% for every 10 knots of headwind
                    distance *= (1 + landingDistanceModel_flaps50Ice_tailwindFactor(weight) * tailwind)
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
        return ifInitialized { _, _, weight in
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

    private var takeoffDistanceModel_tailwindFactor = interpolation(weights: [5000, 5500, 6000], values: [0.036, 0.036, 0.035])
    private var takeoffRollModel_downhillGradientFactor = interpolation(weights: [5000, 5500, 6000], values: [0.02, 0.01, 0.02])

    private var landingDistanceModel_flaps100_tailwindFactor = interpolation(weights: [4500, 5550], values: [0.045, 0.044])
    private var landingDistanceModel_flaps50_headwindFactor = interpolation(weights: [4500, 5550], values: [0.007, 0.006])
    private var landingDistanceModel_flaps50_tailwindFactor = interpolation(weights: [4500, 5550], values: [0.039, 0.038])
    private var landingDistanceModel_flaps50Ice_tailwindFactor = interpolation(weights: [4500, 5550], values: [0.034, 0.033])

    init(runway: Runway?, weather: Weather, weight: Double, flaps: FlapSetting?) {
        self.runway = runway
        self.weather = weather
        self.weight = weight
        self.flaps = flaps
    }

    private func ifInitialized<T>(_ block: (_ runway: Runway, _ weather: Weather, _ weight: Double) -> T?) -> T? {
        runway.flatMap { block($0, weather, weight) }
    }

    private func takeoffRollModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -1.3445e3 +
        (8.2601e-1 * weight) + (-2.2722e-1 * pressureAlt) + (-4.1170e1 * temp) +
        (-5.2201e-5 * pow(weight, 2)) + (3.2405e-5 * weight * pressureAlt) + (6.1544e-3 * weight * temp) +
        (2.0649e-5 * pow(pressureAlt, 2)) + (5.3868e-3 * pressureAlt * temp) + (7.8917e-1 * pow(temp, 2))
    }

    private func takeoffRollModel_uphillGradientFactor(weight: Double) -> Double {
        0.02 + 0.00002 * weight
    }

    private func takeoffDistanceModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        -4.4022e3 +
        (1.9312 * weight) + (-3.4828e-1 * pressureAlt) + (-1.0212e2 * temp) +
        (-1.2960e-4 * pow(weight, 2)) + (5.1123e-5 * weight * pressureAlt) + (1.6013e-2 * weight * temp) +
        (2.8997e-5 * pow(pressureAlt, 2)) + (8.7648e-3 * pressureAlt * temp) + (1.2553 * pow(temp, 2))
    }

    private func landingRollModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        7.2359e2 +
        (2.6203e-9 * weight) + (-3.7197e-2 * pressureAlt) + (-5.6235e-1 * temp) +
        (2.6640e-5 * pow(weight, 2)) + (1.4333e-5 * weight * pressureAlt) + (1.1337e-3 * weight * temp) +
        (3.5930e-6 * pow(pressureAlt, 2)) + (2.2032e-4 * pressureAlt * temp) + (-1.3404e-3 * pow(temp, 2))
    }

    private func landingRollModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        9.6721e2 +
        (3.4688e-9 * weight) + (-5.5645e-2 * pressureAlt) + (-1.0444 * temp) +
        (3.4853e-5 * pow(weight, 2)) + (1.9537e-5 * weight * pressureAlt) + (1.5577e-3 * weight * temp) +
        (5.0850e-6 * pow(pressureAlt, 2)) + (3.1936e-4 * pressureAlt * temp) + (-3.9919e-3 * pow(temp, 2))
    }

    private func landingRollModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        1.3444e3 +
        (4.7428e-9 * weight) + (-6.4257e-2 * pressureAlt) + (-2.4290 * temp) +
        (5.0316e-5 * pow(weight, 2)) + (2.5805e-5 * weight * pressureAlt) + (2.3255e-3 * weight * temp) +
        (6.6757e-6 * pow(pressureAlt, 2)) + (4.8327e-4 * pressureAlt * temp) + (-2.2727e-4 * pow(temp, 2))
    }

    private func landingDistanceModel_flaps100(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        5.1682e2 +
        (6.1753e-9 * weight) + (-5.2724e-2 * pressureAlt) + (-5.7138e-1 * temp) +
        (6.2372e-5 * pow(weight, 2)) + (1.8369e-5 * weight * pressureAlt) + (1.3532e-3 * weight * temp) +
        (4.9489e-6 * pow(pressureAlt, 2)) + (2.9380e-4 * pressureAlt * temp) + (-2.2968e-6 * pow(temp, 2))
    }

    private func landingDistanceModel_flaps50(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        7.2022e2 +
        (7.6050e-9 * weight) + (-9.4436e-2 * pressureAlt) + (-2.6488 * temp) +
        (7.6408e-5 * pow(weight, 2)) + (2.8631e-5 * weight * pressureAlt) + (2.2067e-3 * weight * temp) +
        (6.9041e-6 * pow(pressureAlt, 2)) + (4.2395e-4 * pressureAlt * temp) + (-4.9497e-3 * pow(temp, 2))
    }

    private func landingDistanceModel_flaps50Ice(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        9.0058e2 +
        (1.0586e-8 * weight) + (-1.6374e-1 * pressureAlt) + (-9.5898 * temp) +
        (1.1685e-4 * pow(weight, 2)) + (4.9574e-5 * weight * pressureAlt) + (4.3879e-3 * weight * temp) +
        (9.5954e-6 * pow(pressureAlt, 2)) + (6.9168e-4 * pressureAlt * temp) + (1.1364e-3 * pow(temp, 2))
    }

    private func landingDistanceIncrease_waterSlush(_ dist: Double, depth: Double) -> Double {
        9.1011e2 +
        (-7.1383e3 * depth) + (1.8952 * dist) +
        (1.1439e4 * pow(depth, 2)) + (-1.3195 * depth * dist) + (-9.6834e-8 * pow(dist, 2))
    }

    private func landingDistanceIncrease_slushWetSnow(_ dist: Double, depth: Double) -> Double {
        6.8375e1 +
        (-4.7883e2 * depth) + (1.6923 * dist) +
        (7.6518e2 * pow(depth, 2)) + (-6.2368e-1 * depth * dist) + (3.3037e-7 * pow(dist, 2))
    }

    // 1 in
    private func landingDistanceIncrease_drySnow(_ dist: Double) -> Double {
        4.4607 + (1.3301 * dist) + (-5.6961e-8 * pow(dist, 2))
    }

    private func landingDistanceIncrease_compactSnow(_ dist: Double) -> Double {
        5.6159 + (1.5774 * dist) + (2.2784e-7 * pow(dist, 2))
    }

    private func takeoffClimbGradientModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        5.5529e3 +
        (-1.0618 * weight) + (-8.9972e-2 * pressureAlt) + (-1.2330e1 * temp) +
        (5.9118e-5 * pow(weight, 2)) + (9.8820e-6 * weight * pressureAlt) + (1.6283e-3 * weight * temp) +
        (-1.4734e-6 * pow(pressureAlt, 2)) + (-7.3941e-4 * pressureAlt * temp) + (-1.6823e-1 * pow(temp, 2))
    }

    private func takeoffClimbRateModel(weight: Double, pressureAlt: Double, temp: Double) -> Double {
        8.9312e3 +
        (-1.7359 * weight) + (-7.8554e-2 * pressureAlt) + (-3.0068e1 * temp) +
        (9.8482e-5 * pow(weight, 2)) + (8.8509e-6 * weight * pressureAlt) + (3.8467e-3 * weight * temp) +
        (-3.0587e-6 * pow(pressureAlt, 2)) + (-1.2844e-3 * pressureAlt * temp) + (-2.4104e-1 * pow(temp, 2))
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
        75000 - 400 * temp - 8 * weight
    }

    private func landingMaxPAModel_flaps100(weight: Double, temp: Double) -> Double {
        43228.6 - 340 * temp - 4.31746 * weight
    }

    private func landingMaxPAModel_flaps50(weight: Double, temp: Double) -> Double {
        19285.7 - 100 * temp - 0.952381 * weight
    }
}
