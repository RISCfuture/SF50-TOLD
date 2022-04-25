import Foundation
import Combine
import CoreData
import Dispatch

class AppState: ObservableObject {
    @Published private(set) var payload = 0.0

    @Published var error: Error? = nil

    @Published private(set) var takeoff: SectionState
    @Published private(set) var landing: SectionState
    @Published private(set) var settings = SettingsState()

    var airportLoadingService: AirportLoadingService

    private let weightFormatter = ValueFormatter(precision: 0)

    init() {
        takeoff = SectionState(operation: .takeoff)
        landing = SectionState(operation: .landing)
        
        airportLoadingService = AirportLoadingService()
        airportLoadingService.$error.assign(to: &$error)
    }
}
