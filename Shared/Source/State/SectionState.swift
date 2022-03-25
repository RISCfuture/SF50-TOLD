import Foundation
import Combine
import Defaults
import OSLog
import SwiftMETAR

class SectionState: ObservableObject {
    @Published private(set) var performance: PerformanceState
    
    let operation: Operation
    
    private var cancellables = Set<AnyCancellable>()
    private var weatherLoadingCanceled = false
    
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
    }
    
    func downloadWeather(airport: Airport? = nil, date: Date = Date(), force: Bool = false) {
        weatherLoadingCanceled = false
        guard let airport = airport else {
            DispatchQueue.main.async {
                self.performance.weatherState.resetToISA()
                self.performance.weatherState.loading = false
            }
            return
        }
        
        self.performance.weatherState.beginLoading()
        WeatherService.instance.conditionsFor(airport: airport, date: date, force: force)
            .sink { state in
                if self.weatherLoadingCanceled { return }
                switch state {
                    case .loading:
                        DispatchQueue.main.async { self.performance.weatherState.loading = true }
                    case .finished(let pair):
                        self.performance.weatherState.updateFrom(date: date,
                                                                 observationResult: pair.0,
                                                                 forecastResult: pair.1)
                        DispatchQueue.main.async { self.performance.weatherState.loading = false }
                }
            }
            .store(in: &cancellables)
    }
    
    func cancelWeatherDownload() {
        weatherLoadingCanceled = true
        DispatchQueue.main.async {
            self.performance.weatherState.resetToISA()
            self.performance.weatherState.loading = false
        }
    }
}
