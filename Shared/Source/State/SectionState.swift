import Foundation
import Combine
import CoreData
import Defaults
import OSLog
import SwiftMETAR

class SectionState: ObservableObject {
    @Published var performance = PerformanceState()
    @Published var airportID: String? = nil
    @Published var airportFilterText = ""
    @Published var matchingAirports = Array<Airport>()
    
    @Published var error: Swift.Error? = nil
    
    let operation: Operation
    private var defaultKey: Defaults.Key<String?> {
        switch operation {
            case .takeoff: return .takeoffAirport
            case .landing: return .landingAirport
        }
    }
    
    private let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "SectionState")
    
    private let persistentContainer: NSPersistentContainer
    lazy private var airportStorage = AirportStorage(context: persistentContainer.newBackgroundContext())
    
    private var cancellables = Set<AnyCancellable>()
    
    private var weatherLoadingCanceled = false
    
    init(operation: Operation, persistentContainer: NSPersistentContainer) {
        self.operation = operation
        self.persistentContainer = persistentContainer
        
        $airportFilterText.tryMap { text in
            try self.airportStorage.findAirports(query: text)
        }.replaceError(with: [])
        .receive(on: RunLoop.main)
        .assign(to: &$matchingAirports)
        
        airportID = Defaults[defaultKey]
        $airportID.receive(on: RunLoop.main).sink { Defaults[self.defaultKey] = $0 }.store(in: &cancellables)
        $airportID.tryMap { ID -> Airport? in
            guard let ID = ID else { return nil }
            return try self.airportStorage.airport(id: ID)
        }.catch { error -> AnyPublisher<Airport?, Never> in
            self.error = error
            return Just(nil).eraseToAnyPublisher()
        }.receive(on: RunLoop.main)
        .assign(to: &performance.$airport)
        
        Publishers.CombineLatest(
            performance.$airport,
            performance.$date
        ).sink { airport, date in
            self.downloadWeather(airport: airport, date: date, force: false)
        }.store(in: &cancellables)
        
        // handle nested changes
        performance.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
    
    func downloadWeather(airport: Airport? = nil, date: Date = Date(), force: Bool = false) {
        weatherLoadingCanceled = false
        guard let airport = airport else {
            RunLoop.main.perform { self.performance.weatherState.resetToISA() }
            return
        }
        
        self.performance.weatherState.beginLoading()
        WeatherService.instance.conditionsFor(airport: airport, date: date, force: force)
            .sink { state in
                if self.weatherLoadingCanceled { return }
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
    
    func cancelWeatherDownload() {
        weatherLoadingCanceled = true
        RunLoop.main.perform {
            self.performance.weatherState.resetToISA()
            self.performance.weatherState.loading = false
        }
    }
}
