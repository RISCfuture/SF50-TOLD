import Foundation
import Combine
import SwiftData
import BackgroundTasks
import Defaults
import SwiftNASR
import Network

@Observable class AirportDataLoaderViewModel {
    private let modelContext: ModelContext
    private let loader: AirportDataLoader
    private var cancellable: AnyCancellable? = nil
    
    @MainActor private(set) var error: DataDownloadError? = nil
    @MainActor private(set) var downloadProgress = StepProgress.pending
    @MainActor private(set) var decompressProgress = StepProgress.pending
    @MainActor private(set) var processingProgress = StepProgress.pending
    
    @MainActor private(set) var loading = false
    
    @MainActor private(set) var needsLoad = true
    @MainActor private(set) var canSkip = false
    @MainActor var skipLoadThisSession = false
    @MainActor private(set) var networkIsExpensive = false
    
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "codes.tim.SF50-TOLD.networkMonitorQueue")
    
    @ObservationIgnored @MainActor private var noData: Bool { ((try? airportCount()) ?? 0) == 0 }
    
    @MainActor
    required init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loader = .init(modelContainer: modelContext.container)
        
        needsLoad = outOfDate(schemaVersion: Defaults[.schemaVersion])
        || outOfDate(cycle: Defaults[.lastCycleLoaded])
        canSkip = !noData && !outOfDate(schemaVersion: Defaults[.schemaVersion])
        
        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.networkIsExpensive = (path.isConstrained || path.isExpensive)
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }
    
    deinit {
        stopObserving()
    }
    
    func loadNASR() {
        Task {
            do {
                await MainActor.run { self.loading = true }
                startObserving()
                guard let cycle = try await self.loader.loadNASR() else { return }
                await MainActor.run {
                    Defaults[.lastCycleLoaded] = cycle
                    Defaults[.schemaVersion] = latestSchemaVersion
                    self.needsLoad = self.outOfDate(cycle: cycle)
                    self.loading = false
                }
            } catch (let error as DataDownloadError) {
                await MainActor.run { self.error = error }
            } catch {
                await MainActor.run { self.error = .unknown(error: error) }
            }
        }
    }
    
    @MainActor func loadNASRLater() {
        //AirportLoaderTask.submit()
        self.skipLoadThisSession = true
    }
    
    private func startObserving() {
        cancellable = Timer.publish(every: 0.1, on: .main, in: .common)
            .autoconnect()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                
                Task { @MainActor in
                    self.error = await self.loader.error
                    self.downloadProgress = await self.loader.downloadProgress
                    self.decompressProgress = await self.loader.decompressProgress
                    self.processingProgress = await self.loader.processingProgress
                    
                    if self.error != nil { self.stopObserving() }
                    if self.downloadProgress == StepProgress.complete &&
                        self.decompressProgress == StepProgress.complete &&
                        self.processingProgress == StepProgress.complete {
                        self.stopObserving()
                    }
                }
            }
    }
    
    private func stopObserving() {
        cancellable?.cancel()
        cancellable = nil
    }
    
    @MainActor
    private func airportCount() throws -> Int {
        return try modelContext.fetchCount(FetchDescriptor<Airport>())
    }
    
    @MainActor
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
