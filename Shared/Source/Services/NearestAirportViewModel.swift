import Foundation
import CoreLocation
import SwiftData

@Observable class NearestAirportViewModel: NearestAirportDelegate {
    @MainActor var nearestAirportID: String? = nil
    @MainActor var location: CLLocationCoordinate2D? = nil
    @MainActor var loading = false
    @MainActor var errorText: String? = nil
    @MainActor var authorizationStatus: CLAuthorizationStatus? = nil
    
    private let nearestAirport: NearestAirport
    
    init(modelContext: ModelContext) {
        nearestAirport = .init(modelContainer: modelContext.container)
        Task { await nearestAirport.setDelegate(self) }
    }
    
    func didReceiveNearestAirport(ID: String?) {
        Task { @MainActor in nearestAirportID = ID }
    }
}
