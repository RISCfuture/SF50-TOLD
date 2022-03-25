import Foundation
import Combine
import CoreData
import Dispatch
import OSLog
import Network

class AppState: ObservableObject {
    @Published private(set) var payload = 0.0

    @Published var error: Error? = nil

    @Published private(set) var loadingAirports = false
    @Published private(set) var needsLoad = true
    @Published private(set) var canSkipLoad = false
    @Published private(set) var networkIsExpensive = false

    @Published private(set) var takeoff: SectionState
    @Published private(set) var landing: SectionState
    @Published private(set) var settings = SettingsState()

    var airportLoadingService: AirportLoadingService!

    let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "MainViewController")

    private let weightFormatter = ValueFormatter(precision: 0)
    private let networkMonitor = NWPathMonitor()
    private let networkMonitorQueue = DispatchQueue(label: "codes.tim.SF50-Told.networkMonitorQueue")

    init() {
        takeoff = SectionState(operation: .takeoff)
        landing = SectionState(operation: .landing)
        airportLoadingService = AirportLoadingService()

        configureLoadingService()

        networkMonitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.networkIsExpensive = (path.isConstrained || path.isExpensive)
            }
        }
        networkMonitor.start(queue: networkMonitorQueue)
    }

    private func configureLoadingService() {
        airportLoadingService.$error.receive(on: DispatchQueue.main).assign(to: &$error)
        airportLoadingService.$progress.receive(on: DispatchQueue.main).map { !$0.isFinished }.assign(to: &$loadingAirports)
        airportLoadingService.$needsLoad.receive(on: DispatchQueue.main).assign(to: &$needsLoad)
        airportLoadingService.$canSkip.receive(on: DispatchQueue.main).assign(to: &$canSkipLoad)
    }
}
