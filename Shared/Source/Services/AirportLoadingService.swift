import Foundation
import Combine
import CoreData
import BackgroundTasks
import Defaults
import SwiftNASR
import Network

class AirportLoadingService: ObservableObject {
    @Published private(set) var downloadProgress = StepProgress.pending
    @Published private(set) var decompressProgress = StepProgress.pending
    @Published private(set) var processingProgress = StepProgress.pending
    @Published private(set) var error: Error? = nil
    @Published private(set) var loading = false
    
    @Published private(set) var needsLoad = true
    @Published private(set) var canSkip = false
    @Published var skipLoadThisSession = false
    @Published private(set) var networkIsExpensive = false
    
    private let airportDataLoader: AirportDataLoader
    
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "codes.tim.SF50-TOLD.networkMonitorQueue")
    
    private var noData: Bool { ((try? airportCount()) ?? 0) == 0 }
    
    required init() {
        airportDataLoader = .init()
        airportDataLoader.$error.receive(on: DispatchQueue.main).assign(to: &$error)
        airportDataLoader.$downloadProgress.receive(on: DispatchQueue.main).assign(to: &$downloadProgress)
        airportDataLoader.$decompressProgress.receive(on: DispatchQueue.main).assign(to: &$decompressProgress)
        airportDataLoader.$processingProgress.receive(on: DispatchQueue.main).assign(to: &$processingProgress)
        
        Publishers.CombineLatest3(airportDataLoader.$downloadProgress,
                                  airportDataLoader.$decompressProgress,
                                  airportDataLoader.$processingProgress).map { (download, decompress, processing) in
            download.isLoading || decompress.isLoading || processing.isLoading
        }.receive(on: DispatchQueue.main).assign(to: &$loading)
        
        needsLoad = outOfDate(schemaVersion: Defaults[.schemaVersion])
            || outOfDate(cycle: Defaults[.lastCycleLoaded])
        canSkip = !noData && !outOfDate(schemaVersion: Defaults[.schemaVersion])
        
        Publishers.CombineLatest3(
            $skipLoadThisSession,
            Defaults.publisher(.lastCycleLoaded).map { $0.newValue },
            Defaults.publisher(.schemaVersion).map { $0.newValue }
        ).map { [weak self] skipLoadThisSession, cycle, schemaVersion in
            guard let this = self else { return false }
            if skipLoadThisSession { return false }
            
            return this.outOfDate(schemaVersion: schemaVersion)
                || this.outOfDate(cycle: cycle)
        }.receive(on: DispatchQueue.main)
        .assign(to: &$needsLoad)
        
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.networkIsExpensive = (path.isConstrained || path.isExpensive)
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }
    
    func loadNASR() {
        Task.detached(priority: .userInitiated) {
            do {
                guard let cycle = try await self.airportDataLoader.loadNASR() else { return }
                DispatchQueue.main.async {
                    Defaults[.lastCycleLoaded] = cycle
                    Defaults[.schemaVersion] = latestSchemaVersion
                }
            } catch (let error as Error) {
                DispatchQueue.main.async { self.error = error }
            } catch {
                DispatchQueue.main.async { self.error = .unknown(error: error) }
            }
        }
    }
    
    func loadNASRLater() {
        //AirportLoaderTask.submit()
        DispatchQueue.main.async { self.skipLoadThisSession = true }
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
    
    private func outOfDate(schemaVersion: Int) -> Bool {
        schemaVersion != latestSchemaVersion
    }
}
