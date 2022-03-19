import Foundation
import Combine
import CoreData
import BackgroundTasks
import Defaults
import SwiftNASR

fileprivate func resetProgress(finished: Bool = false) -> Progress {
    let progress = Progress(totalUnitCount: 1)
    if finished { progress.completedUnitCount = 1 }
    progress.localizedDescription = ""
    progress.localizedAdditionalDescription = ""
    return progress
}

class AirportLoadingService: ObservableObject {
    @Published private(set) var progress = { resetProgress(finished: true) }()
    @Published private(set) var error: Swift.Error? = nil
    
    @Published private(set) var needsLoad = true
    @Published private(set) var canSkip = false
    @Published var skipLoadThisSession = false
    
    private let airportDataLoader: AirportDataLoader
    
    var loading: Bool { !progress.isFinished }
        
    required init() {
        airportDataLoader = .init()
        airportDataLoader.$error.receive(on: RunLoop.main).assign(to: &$error)
        
        needsLoad = outOfDate(cycle: Defaults[.lastCycleLoaded])
        canSkip = ((try? airportCount()) ?? 0) > 0
        
        Publishers.CombineLatest(
            $skipLoadThisSession,
            Defaults.publisher(.lastCycleLoaded).map { $0.newValue }
        ).map { [weak self] skipLoadThisSession, cycle in
            guard let this = self else { return false }
            if skipLoadThisSession { return false }
            return this.outOfDate(cycle: cycle)
        }.receive(on: RunLoop.main)
        .assign(to: &$needsLoad)
        
        progress.completedUnitCount = 1
    }
    
    func loadNASR() {
        progress = resetProgress()
        
        Task {
            guard let cycle = try! await self.airportDataLoader.loadNASR(withProgress: { self.progress.addChild($0, withPendingUnitCount: 1) }) else { return }
            RunLoop.main.perform {
                Defaults[.lastCycleLoaded] = cycle
                self.progress = resetProgress(finished: true)
            }
        }
    }
    
    func loadNASRLater() {
        //AirportLoaderTask.submit()
        RunLoop.main.perform { self.skipLoadThisSession = true }
    }
    
    private func airportCount() throws -> Int {
        let fetchRequest: NSFetchRequest<Airport> = Airport.fetchRequest()
        return try PersistentContainer.shared.viewContext.count(for: fetchRequest)
    }
    
    private func outOfDate(cycle: Cycle?) -> Bool {
        guard let cycle = cycle else { return true }
        if !cycle.isEffective { return true }
        guard let count = try? airportCount() else { return true }
        if count == 0 { return true }
        return false
    }
}
