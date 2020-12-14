import Foundation
import Combine
import CoreData
import OSLog

class AppState: ObservableObject {
    @Published var payload = 0.0
    @Published var error: Error? = nil
    @Published var loadingAirports = false
    @Published var needsLoad = true
    
    @Published var takeoff: SectionState
    @Published var landing: SectionState
    @Published var settings: SettingsState
        
    let persistentContainer: NSPersistentContainer
    let airportLoadingService: AirportLoadingService
    
    let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "MainViewController")
    
    private let weightFormatter = ValueFormatter(precision: 0)
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        persistentContainer = NSPersistentContainer(name: "Airports")
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
        
        airportLoadingService = AirportLoadingService(container: persistentContainer)
        
        takeoff = SectionState(operation: .takeoff, persistentContainer: persistentContainer)
        landing = SectionState(operation: .landing, persistentContainer: persistentContainer)
        settings = SettingsState()
        
        // propogate errors up
        airportLoadingService.$error.receive(on: RunLoop.main).assign(to: &$error)
        takeoff.$error.receive(on: RunLoop.main).assign(to: &$error)
        landing.$error.receive(on: RunLoop.main).assign(to: &$error)
        
        // handle nested changes
        takeoff.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        landing.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        settings.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        
        // airport loading state
        airportLoadingService.$progress.receive(on: RunLoop.main).map { $0 != nil }.assign(to: &$loadingAirports)
        airportLoadingService.$needsLoad.receive(on: RunLoop.main).assign(to: &$needsLoad)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
}
