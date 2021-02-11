import Foundation
import SwiftMETAR
import Combine


fileprivate var METARUpdatePeriod: TimeInterval = 3600

class WeatherState: ObservableObject {
    @Published private(set) var observation: String?
    @Published private(set) var forecast: String?
    
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
    
    required init(wind: Wind = .calm, temperature: Temperature = .ISA, altimeter: Double = standardSLP, wet: Bool = false, source: Source, observation: String? = nil, forecast: String? = nil, draft: Bool = false) {
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
            case let .value(num): userEditedTemperature = num
        }
        
        $userEditedTemperature.receive(on: DispatchQueue.main).sink { [weak self] temp in self?.temperature = .value(temp) }.store(in: &cancellables)
    }
    
    convenience init(date: Date, observation: METAR?, forecast: TAF?) {
        guard let values = WeatherValues(date: date, observation: observation, forecast: forecast) else {
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
    
    func updateFrom(date: Date, observationResult: WeatherResult<METAR>, forecastResult: WeatherResult<TAF>) {
        let observation: METAR?
        let forecast: TAF?
        let rawObservation: String?
        let rawForecast: String?
        let observationError: Swift.Error?
        let forecastError: Swift.Error?
        
        switch observationResult {
            case let .some(value):
                observation = value
                rawObservation = value.text
                observationError = nil
            case let .error(error, raw):
                observation = nil
                rawObservation = raw
                observationError = error
            case .none:
                observation = nil
                rawObservation = nil
                observationError = nil
        }
        switch forecastResult {
            case let .some(value):
                forecast = value
                rawForecast = value.text
                forecastError = nil
            case let .error(error, raw):
                forecast = nil
                rawForecast = raw
                forecastError = error
            case .none:
                forecast = nil
                rawForecast = nil
                forecastError = nil
        }

        guard let values = WeatherValues(date: date, observation: observation, forecast: forecast) else {
            DispatchQueue.main.async { self.resetToISA(observationError: observationError, forecastError: forecastError) }
            return
        }
        
        DispatchQueue.main.async {
            self.windDirection = values.wind.direction
            self.windSpeed = values.wind.speed
            self.temperature = values.temperature
            switch values.temperature {
                case let .value(num): self.userEditedTemperature = num
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
