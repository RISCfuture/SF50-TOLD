import Foundation
import Combine
import Dispatch

@Observable class AppState {
    private(set) var payload = 0.0

    var error: DataDownloadError? = nil

    private(set) var takeoff: SectionState
    private(set) var landing: SectionState

    @ObservationIgnored var airportLoadingService: AirportDataLoaderViewModel

    private let weightFormatter = ValueFormatter(precision: 0)

    init() {
        takeoff = SectionState(operation: .takeoff)
        landing = SectionState(operation: .landing)
        
        airportLoadingService = AirportDataLoaderViewModel()
        airportLoadingService.$error.assign(to: &$error)
    }
}
