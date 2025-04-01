import BackgroundTasks
import Combine
import CoreData
import Defaults
import Foundation
import Network
import SwiftNASR

class AirportLoadingService: ObservableObject {
    @Published private(set) var downloadProgress = StepProgress.pending
    @Published private(set) var decompressProgress = StepProgress.pending
    @Published private(set) var processingProgress = StepProgress.pending
    @Published private(set) var error: DataDownloadError?
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

    func loadNASR() {
        Task.detached(priority: .userInitiated) {
            do {
                DispatchQueue.main.async { self.loading = true }
                guard let cycle = try await self.airportDataLoader.loadNASR() else { return }
                DispatchQueue.main.async {
                    Defaults[.lastCycleLoaded] = cycle
                    Defaults[.schemaVersion] = latestSchemaVersion
                    self.needsLoad = self.outOfDate(cycle: cycle)
                    self.loading = false
                }
            } catch let error as DataDownloadError {
                DispatchQueue.main.async { self.error = error }
            } catch {
                DispatchQueue.main.async { self.error = .unknown(error: error) }
            }
        }
    }

    func loadNASRLater() {
        // AirportLoaderTask.submit()
        DispatchQueue.main.async { self.skipLoadThisSession = true }
    }

    private func airportCount() throws -> Int {
        let fetchRequest: NSFetchRequest<Airport> = Airport.fetchRequest()
        return try PersistentContainer.shared.viewContext.count(for: fetchRequest)
    }

    private func outOfDate(cycle: Cycle?) -> Bool {
        if let cycle, cycle.isEffective,
           let count = try? airportCount(), count > 0 { return false } // swiftlint:disable:this empty_count
        return true
    }

    private func outOfDate(schemaVersion: Int) -> Bool {
        schemaVersion != latestSchemaVersion
    }
}
