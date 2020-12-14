import Foundation
import Combine
import CoreData
import Defaults
import SwiftNASR

class AirportLoadingService: ObservableObject {
    @Published private(set) var progress: Progress? = nil
    @Published private(set) var error: Swift.Error? = nil
    
    @Published private(set) var needsLoad = true
    @Published var skipLoadThisSession = false
    
    private let airportDataLoader: AirportDataLoader
    
    var loading: Bool { progress != nil }
    
    required init(container: NSPersistentContainer) {
        airportDataLoader = .init(container: container)
        airportDataLoader.$progress.receive(on: RunLoop.main).assign(to: &$progress)
        airportDataLoader.$error.receive(on: RunLoop.main).assign(to: &$error)
        
        needsLoad = !(Defaults[.lastCycleLoaded]?.isEffective ?? false)
        Publishers.CombineLatest(
            $skipLoadThisSession,
            Defaults.publisher(.lastCycleLoaded).map { $0.newValue }
        ).map { skipLoadThisSession, cycle in
            if skipLoadThisSession { return false }
            guard let cycle = cycle else { return true }
            return !cycle.isEffective
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
}
