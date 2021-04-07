import Foundation
import Combine
import CoreData
import OSLog
import SwiftMETAR

class SectionState: ObservableObject {
    @Published var performance: PerformanceState
    @Published var error: Swift.Error? = nil
        
    private let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "SectionState")
    private var cancellables = Set<AnyCancellable>()
    
    init(operation: Operation) {
        performance = PerformanceState(operation: operation)
        
        Publishers.CombineLatest3(
            performance.$airport,
            performance.$runway,
            performance.$date
        ).sink { airport, runway, date in
            if self.performance.weatherState.source != .entered {
                self.downloadWeather(airport: airport, runway: runway, date: date, force: false)
            }
        }.store(in: &cancellables)
        
        // handle nested changes
        performance.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
    
    func downloadWeather(airport: Airport?, runway: Runway?, date: Date, force: Bool) {
        guard let airport = airport else {
            RunLoop.main.perform {
                self.performance.weatherState.resetToISA()
            }
            return
        }
        
        WeatherService.instance.conditionsFor(airport: airport, runway: runway, date: date, force: force)
            .sink { state in
                switch state {
                    case .loading:
                        RunLoop.main.perform { self.performance.weatherState.loading = true }
                    case .finished(let pair):
                        self.performance.weatherState.updateFrom(date: date,
                                                                 observationResult: pair.0,
                                                                 forecastResult: pair.1)
                        RunLoop.main.perform { self.performance.weatherState.loading = false }
                }
            }
            .store(in: &cancellables)
    }
}
