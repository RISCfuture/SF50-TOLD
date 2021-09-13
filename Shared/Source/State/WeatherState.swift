import Foundation
import SwiftMETAR
import Combine


var standardTemperature = 15.04
var standardSLP = 29.921
fileprivate var METARUpdatePeriod: TimeInterval = 3600

class WeatherState: ObservableObject {
    @Published var observation: String?
    @Published var forecast: String?
    
    @Published var windDirection: Double
    @Published var windSpeed: Double
    @Published var temperature: Temperature
    @Published var altimeter: Double
    
    @Published var userEditedTemperature: Double
    
    @Published var source: Source
    @Published var loading = false
    var draft: Bool
    
    var observationError: Swift.Error? = nil
    var forecastError: Swift.Error? = nil
    
    private var cancellables = Set<AnyCancellable>()
    
    var wind: Wind {
        return Wind(direction: windDirection, speed: windSpeed)
    }
    
    var resetDueToError: Bool {
        source == .ISA && (observationError != nil || forecastError != nil)
    }
    
    var weather: Weather {
        Weather(observation: observation,
                forecast: forecast,
                wind: wind,
                temperature: temperature,
                altimeter: altimeter,
                source: source)
    }
    
    convenience init() {
        self.init(wind: .calm, temperature: .ISA, altimeter: standardSLP, source: .ISA)
    }
    
    required init(wind: Wind = .calm, temperature: Temperature = .ISA, altimeter: Double = standardSLP, source: Source, observation: String? = nil, forecast: String? = nil, draft: Bool = false) {
        windDirection = wind.direction
        windSpeed = wind.speed
        self.temperature = temperature
        self.altimeter = altimeter
        self.observation = observation
        self.forecast = forecast
        self.draft = draft
        self.source = source
        
        switch temperature {
            case .ISA: userEditedTemperature = 15
            case .value(let num): userEditedTemperature = num
        }
        
        $userEditedTemperature.receive(on: RunLoop.main).sink { [weak self] temp in self?.temperature = .value(temp) }.store(in: &cancellables)
    }
    
    convenience init(date: Date, observation: METAR?, forecast: TAF?) {
        guard let values = valuesFrom(date: date, observation: observation, forecast: forecast) else {
            self.init()
            return
            
        }
        
        self.init(wind: values.wind,
                  temperature: values.temperature,
                  altimeter: values.altimeter,
                  source: .downloaded,
                  observation: observation?.text,
                  forecast: forecast?.text)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
    
    func resetToISA(observationError: Swift.Error? = nil, forecastError: Swift.Error? = nil) {
        windDirection = 0
        windSpeed = 0
        temperature = .ISA
        userEditedTemperature = standardTemperature
        altimeter = standardSLP
        source = .ISA
        observation = nil
        self.observationError = observationError
        forecast = nil
        self.forecastError = forecastError
    }
    
    func beginLoading() {
        observation = nil
        forecast = nil
        observationError = nil
        forecastError = nil
    }
    
    func updateFrom(date: Date, observationResult: WeatherService.FetchResult<METAR>, forecastResult: WeatherService.FetchResult<TAF>) {
        let observation: METAR?
        let forecast: TAF?
        let rawObservation: String?
        let rawForecast: String?
        let observationError: Swift.Error?
        let forecastError: Swift.Error?
        
        switch observationResult {
            case .some(let value):
                observation = value
                rawObservation = value.text
                observationError = nil
            case .parseError(let error, let raw):
                observation = nil
                rawObservation = raw
                observationError = error
            case .error(let error):
                observation = nil
                rawObservation = nil
                observationError = error
            case .none:
                observation = nil
                rawObservation = nil
                observationError = nil
        }
        switch forecastResult {
            case .some(let value):
                forecast = value
                rawForecast = value.text
                forecastError = nil
            case .parseError(let error, let raw):
                forecast = nil
                rawForecast = raw
                forecastError = error
            case .error(let error):
                forecast = nil
                rawForecast = nil
                forecastError = error
            case .none:
                forecast = nil
                rawForecast = nil
                forecastError = nil
        }

        guard let values = valuesFrom(date: date, observation: observation, forecast: forecast) else {
            RunLoop.main.perform { self.resetToISA(observationError: observationError, forecastError: forecastError) }
            return
        }
        
        RunLoop.main.perform {
            self.windDirection = values.wind.direction
            self.windSpeed = values.wind.speed
            self.temperature = values.temperature
            switch values.temperature {
                case .value(let num): self.userEditedTemperature = num
                case .ISA: self.userEditedTemperature = standardTemperature
            }
            self.altimeter = values.altimeter
            self.source = .downloaded
            
            self.observation = rawObservation
            self.forecast = rawForecast
            self.observationError = observationError
            self.forecastError = forecastError

        }
    }
}

fileprivate func windFromEnum(_ wind: SwiftMETAR.Wind) -> Wind {
    switch wind {
        case let .direction(heading, speed, _):
            return .init(direction: Double(heading), speed: Double(speed.knots))
        case let .directionRange(heading, _, speed, _):
            return .init(direction: Double(heading), speed: Double(speed.knots))
        default: return .calm
    }
}

fileprivate struct WeatherValues {
    var wind: Wind
    var temperature: Temperature
    var altimeter: Double
}

fileprivate func valuesFrom(date: Date, observation: METAR?, forecast: TAF?) -> WeatherValues? {
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
            altimeter = Double(observedAlt.inHg)
        }
        
        if sinceMETAR > METARUpdatePeriod {
            if let forecast = forecast {
                if let group = forecast.during(date) {
                    if let forecastWind = group.wind {
                        wind = windFromEnum(forecastWind)
                    }
                    if let forecastAlt = group.altimeter {
                        altimeter = Double(forecastAlt.inHg)
                    }
                }
            }
        }
    }
    
    return WeatherValues(wind: wind,
                         temperature: temperature,
                         altimeter: altimeter)
}
