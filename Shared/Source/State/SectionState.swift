import Foundation
import Combine
import Defaults
import OSLog
import SwiftMETAR

class SectionState: ObservableObject {
    fileprivate static let weatherLoadDebounce: TimeInterval = 60 // once per minute, tops
    
    @Published private(set) var performance: PerformanceState
    
    let operation: Operation
    
    private var cancellables = Set<AnyCancellable>()
    private var airportChangeCancellables = Set<AnyCancellable>()
    
    private var weatherLoadingCanceled = false
    private var lastWeatherLoad: Date? = nil
    
    private let weatherQueue = DispatchQueue(label: "weatherQueue", qos: .utility, attributes: .concurrent)
    
    init(operation: Operation) {
        self.operation = operation
        self.performance = PerformanceState(operation: operation)
        
        Publishers.CombineLatest(
            performance.$airport,
            performance.$date
        ).sink { airport, date in
            self.downloadWeather(airport: airport, date: date, force: false)
        }.store(in: &cancellables)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
        for c in airportChangeCancellables { c.cancel() }
    }
    
    func downloadWeather(airport: Airport? = nil, date: Date = Date(), force: Bool = false) {
        for c in airportChangeCancellables { c.cancel() }
        airportChangeCancellables.removeAll()
        
        weatherLoadingCanceled = false
        guard let airport = airport else {
            DispatchQueue.main.async {
                self.performance.weatherState.resetToISA()
                self.performance.weatherState.loading = false
            }
            return
        }
        
        self.performance.weatherState.beginLoading()
        if force { reloadWeather() }
        WeatherService.instance.cachedConditionsFor(airport: airport, date: date)
            .receive(on: weatherQueue)
            .sink { state in
                guard !self.weatherLoadingCanceled else { return }
                
                switch state {
                    case .notLoaded:
                        self.reloadWeather()
                        fallthrough
                    case .loading:
                        DispatchQueue.main.async { self.performance.weatherState.loading = true }
                    case let .error(error):
                        DispatchQueue.main.async {
                            self.performance.weatherState.loading = false
                            self.performance.weatherState.observationError = error
                        }
                    case let .finished((metarResult, tafResult)):
                        self.performance.weatherState.updateFrom(date: date,
                                                                 observationResult: metarResult,
                                                                 forecastResult: tafResult)
                        DispatchQueue.main.async { self.performance.weatherState.loading = false }
                }
            }
            .store(in: &airportChangeCancellables)
        
        WeatherService.instance.cachedConditionsFor(airport: airport, date: date)
            .receive(on: weatherQueue)
            .sink { state in
                guard !self.weatherLoadingCanceled else { return }
                
                switch state {
                    case let .finished((metarResult, tafResult)):
                        if case let .some(metar) = metarResult {
                            if isExpired(metar: metar) {
                                self.reloadWeather(debounce: true)
                            }
                        }
                        if case let .some(taf) = tafResult {
                            if isExpired(taf: taf) {
                                self.reloadWeather(debounce: true)
                            }
                        }
                        
                    default: break
                }
            }
            .store(in: &airportChangeCancellables)
    }
    
    func cancelWeatherDownload() {
        weatherLoadingCanceled = true
        DispatchQueue.main.async {
            self.performance.weatherState.resetToISA()
            self.performance.weatherState.loading = false
        }
    }
    
    private func reloadWeather(debounce: Bool = false) {
        guard let lastWeatherLoad = lastWeatherLoad else {
            WeatherService.instance.reload()
            self.lastWeatherLoad = Date()
            return
        }
        guard !debounce || -lastWeatherLoad.timeIntervalSinceNow > Self.weatherLoadDebounce else { return }
        
        WeatherService.instance.reload()
        self.lastWeatherLoad = Date()
    }
}

fileprivate let METARTimeout: TimeInterval = 5400 // METARs valid until 1.5 hours old
fileprivate let TAFTimeout: TimeInterval = 43200 // TAFs valid until 12 hours old

func isExpired(metar: METAR) -> Bool {
    -metar.date.timeIntervalSinceNow > METARTimeout
}

func isExpired(taf: TAF) -> Bool {
    -taf.originDateOrToday.timeIntervalSinceNow > TAFTimeout
}
