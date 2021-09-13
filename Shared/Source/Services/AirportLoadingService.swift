import Foundation
import Combine
import CoreData
import BackgroundTasks
import Defaults
import SwiftNASR

class AirportLoadingService: ObservableObject {
    @Published private(set) var progress: Progress? = nil
    @Published private(set) var error: Swift.Error? = nil
    
    @Published private(set) var needsLoad = true
    @Published private(set) var canSkip = false
    @Published var skipLoadThisSession = false
    
    private let airportDataLoader: AirportDataLoader
    
    var loading: Bool { progress != nil }
        
    required init(container: NSPersistentContainer) {
        airportDataLoader = .init(container: container)
        airportDataLoader.$progress.receive(on: RunLoop.main).assign(to: &$progress)
        airportDataLoader.$error.receive(on: RunLoop.main).assign(to: &$error)
        
        needsLoad = outOfDate(container: container, cycle: Defaults[.lastCycleLoaded])
        canSkip = ((try? airportCount(container: container)) ?? 0) > 0
        
        Publishers.CombineLatest(
            $skipLoadThisSession,
            Defaults.publisher(.lastCycleLoaded).map { $0.newValue }
        ).map { [weak self] skipLoadThisSession, cycle in
            guard let this = self else { return false }
            if skipLoadThisSession { return false }
            return this.outOfDate(container: container, cycle: cycle)
        }.receive(on: RunLoop.main)
        .assign(to: &$needsLoad)
    }
    
    func loadNASR() {
        airportDataLoader.loadNASR { result in
            switch result {
                case .success(let cycle):
                    Defaults[.lastCycleLoaded] = cycle
                default: return
            }
        }
    }
    
    func loadNASRLater() {
        //AirportLoaderTask.submit()
        RunLoop.main.perform { self.skipLoadThisSession = true }
    }
    
    private func airportCount(container: NSPersistentContainer) throws -> Int {
        let fetchRequest: NSFetchRequest<Airport> = Airport.fetchRequest()
        return try container.viewContext.count(for: fetchRequest)
    }
    
    private func outOfDate(container: NSPersistentContainer, cycle: Cycle?) -> Bool {
        guard let cycle = cycle else { return true }
        if !cycle.isEffective { return true }
        guard let count = try? airportCount(container: container) else { return true }
        if count == 0 { return true }
        return false
    }
}
