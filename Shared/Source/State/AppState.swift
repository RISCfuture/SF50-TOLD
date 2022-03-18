import Foundation
import Combine
import CoreData
import Dispatch
import OSLog
import Network

class AppState: ObservableObject {
    @Published private(set) var payload = 0.0
    
    @Published private(set) var error: Error? = nil
    
    @Published private(set) var loadingAirports = false
    @Published private(set) var needsLoad = true
    @Published private(set) var canSkipLoad = false
    @Published private(set) var networkIsExpensive = false
    
    @Published private(set) var takeoff: SectionState!
    @Published private(set) var landing: SectionState!
    @Published private(set) var settings = SettingsState()
        
    let persistentContainer: NSPersistentContainer
    var airportLoadingService: AirportLoadingService!
    
    let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "MainViewController")
    
    private let weightFormatter = ValueFormatter(precision: 0)
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "codes.tim.SF50-Told.networkMonitorQueue")
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        persistentContainer = NSPersistentContainer(name: "Airports")
        configurePersistentContainer()

        airportLoadingService = AirportLoadingService(container: persistentContainer)
        configureLoadingService()
        
        takeoff = SectionState(operation: .takeoff, persistentContainer: persistentContainer)
        landing = SectionState(operation: .landing, persistentContainer: persistentContainer)
        handleNestedChanges()
        
        networkMonitor.pathUpdateHandler = { path in
            RunLoop.main.perform {
                self.networkIsExpensive = (path.isConstrained || path.isExpensive)
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
    
    private func configurePersistentContainer() {
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.codes.tim.TOLD") else {
            fatalError("Shared file container couild not be created.")
        }
        let storeURL = containerURL.appendingPathComponent("Airports.sqlite")
        
        persistentContainer.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        persistentContainer.loadPersistentStores { description, error in
            if let error = error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
    }
    
    private func configureLoadingService() {
        airportLoadingService.$error.receive(on: RunLoop.main).assign(to: &$error)
        airportLoadingService.$progress.receive(on: RunLoop.main).map { $0 != nil }.assign(to: &$loadingAirports)
        airportLoadingService.$needsLoad.receive(on: RunLoop.main).assign(to: &$needsLoad)
        airportLoadingService.$canSkip.receive(on: RunLoop.main).assign(to: &$canSkipLoad)
    }
    
    private func handleNestedChanges() {
        takeoff.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        landing.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
        settings.objectWillChange.receive(on: RunLoop.main).sink { [weak self] _ in self?.objectWillChange.send() }.store(in: &cancellables)
    }
}
