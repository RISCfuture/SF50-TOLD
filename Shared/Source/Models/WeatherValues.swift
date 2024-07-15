import Foundation
import SwiftMETAR

fileprivate var METARUpdatePeriod: TimeInterval = 3600

struct WeatherValues {
    var wind: Wind
    var temperature: Temperature
    var altimeter: Double
    
    init?(date: Date, observation: METAR?, forecast: TAF?) {
        if observation == nil && forecast == nil { return nil }
        
        if let observation = observation {
            let sinceMETAR = date.timeIntervalSince(observation.date)
            if sinceMETAR > METARUpdatePeriod {
                guard let forecast = forecast else { return nil }
                if !forecast.covers(date) { return nil }
            }
        }
        
        var wind = Wind.calm
        var temperature = Temperature.ISA
        var altimeter = standardSLP
        
        if let observation = observation {
            let sinceMETAR = date.timeIntervalSince(observation.date)
            
            if let observedWind = observation.wind {
                wind = windFromEnum(observedWind)
            }
            
            if let observedTemp = observation.temperature {
                temperature = .value(Double(observedTemp))
            }
            
            if let observedAlt = observation.altimeter {
                altimeter = Double(observedAlt.measurement.converted(to: .inchesOfMercury).value)
            }
            
            if sinceMETAR > METARUpdatePeriod {
                if let forecast = forecast {
                    if let group = forecast.during(date) {
                        if let forecastWind = group.wind {
                            wind = windFromEnum(forecastWind)
                        }
                        if let forecastAlt = group.altimeter {
                            altimeter = Double(forecastAlt.measurement.converted(to: .inchesOfMercury).value)
                        }
                    }
                }
            }
        }
        
        self.wind = wind
        self.temperature = temperature
        self.altimeter = altimeter
    }
}

fileprivate func windFromEnum(_ wind: SwiftMETAR.Wind) -> Wind {
    switch wind {
        case let .direction(heading, speed, _):
            return .init(direction: Double(heading), speed: Double(speed.measurement.converted(to: .knots).value))
        case let .directionRange(heading, _, speed, _):
            return .init(direction: Double(heading), speed: Double(speed.measurement.converted(to: .knots).value))
        default: return .calm
    }
}
