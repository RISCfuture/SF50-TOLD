import Combine
import CoreData
import Dispatch
import Foundation

class AppState: ObservableObject {
    @Published private(set) var payload = 0.0

    @Published var error: DataDownloadError?

    @Published private(set) var takeoff: SectionState
    @Published private(set) var landing: SectionState

    var airportLoadingService: AirportLoadingService

    private let weightFormatter = ValueFormatter(precision: 0)

    init() {
        takeoff = SectionState(operation: .takeoff)
        landing = SectionState(operation: .landing)

        airportLoadingService = AirportLoadingService()
        airportLoadingService.$error.assign(to: &$error)
    }
}
