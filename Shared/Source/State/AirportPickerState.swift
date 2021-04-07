import Foundation
import Combine

class AirportPickerState: ObservableObject {
    @Published var airportFilterText = ""
    @Published var matchingAirports = Array<Airport>()
    @Published var favoriteAndRecentAirports = Array<Airport>()
    @Published var error: Swift.Error? = nil

    init() {
        $airportFilterText.tryMap { text in
            try AirportStorage.instance.airportsForQuery(text)
        }.replaceError(with: [])
        .receive(on: RunLoop.main)
        .assign(to: &$matchingAirports)
        
        $airportFilterText.filter { $0.isEmpty }.tryMap { _ in
            try AirportStorage.instance.favoritesAndRecents()
        }.replaceError(with: [])
        .receive(on: RunLoop.main)
        .assign(to: &$favoriteAndRecentAirports)
        do {
            favoriteAndRecentAirports = try AirportStorage.instance.favoritesAndRecents()
        } catch (let error) {
            self.error = error
        }
    }
}
