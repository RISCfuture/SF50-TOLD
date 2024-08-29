import Foundation
import SwiftData
import CoreLocation
import MapKit
import Logging
import SwiftUI

fileprivate let earthRadius = 21638.0 // NM
fileprivate func degreeLonLen(lat: Double) -> Double {
    cos(deg2rad(lat))*(earthRadius/360)
}

protocol NearestAirportDelegate: AnyObject {
    func didReceiveNearestAirport(ID: String?)
}

final actor NearestAirport {
    private let modelContext: ModelContext
    private let locationDelegate: LocationDelegate
    
    var loading = false
    var errorText: String? = nil
    var authorizationStatus: CLAuthorizationStatus? = nil
    weak var delegate: NearestAirportDelegate? = nil
    private let manager = CLLocationManager()
    
    var nearestAirportID: String? = nil {
        didSet { delegate?.didReceiveNearestAirport(ID: nearestAirportID) }
    }
    var location: CLLocationCoordinate2D? = nil  {
        didSet { Task { try? findNearestAirportID() } }
    }
    
    private static let logger = Logger(label: "codes.tim.SF50-TOLD.NearestAirport")
    
    init(modelContainer: ModelContainer) {
        modelContext = .init(modelContainer)
        locationDelegate = LocationDelegate(target: self)
        Task {
            manager.delegate = locationDelegate
            manager.requestWhenInUseAuthorization()
            manager.startMonitoringSignificantLocationChanges()
        }
    }
    
    deinit {
        manager.stopMonitoringSignificantLocationChanges()
    }
    
    func setDelegate(_ delegate: NearestAirportDelegate) {
        self.delegate = delegate
    }
    
    func request() {
        loading = true
        errorText = nil
        location = nil
        manager.requestLocation()
    }
    
    private func setCoordinate(_ coordinate: CLLocationCoordinate2D) {
        location = coordinate
        errorText = nil
        loading = false
    }
    
    private func setError(_ error: Error) {
        Self.logger.error("CLLocationManager: error", metadata: ["error": "\(error.localizedDescription)"])
        location = nil
        errorText = error.localizedDescription
        loading = false
    }
    
    private func setAuthStatus(_ status: CLAuthorizationStatus) {
        authorizationStatus = status
    }
    
    private func airportDistance(_ airport1: Airport, _ airport2: Airport) -> Bool {
        guard let location = location else { return false }
        
        let point = MKMapPoint(location)
        let dist1 = airport1.mapPoint.distance(to: point)
        let dist2 = airport2.mapPoint.distance(to: point)
        
        return dist1 < dist2
    }
    
    private func compareDistances(_ airport1: Airport, _ airport2: Airport, reference: MKMapPoint) -> Bool {
        let dist1 = airport1.mapPoint.distance(to: reference)
        let dist2 = airport2.mapPoint.distance(to: reference)
        
        return dist1 < dist2
    }
    
    private func findNearestAirportID() throws {
        guard let location = location else { return }
        nearestAirportID = try findNearestAirportID(to: location)
    }
    
    private func findNearestAirportID(to coordinate: CLLocationCoordinate2D) throws -> String? {
        let reference = MKMapPoint(coordinate)
        let airports = try modelContext.fetch(.init(predicate: predicate(coordinate: coordinate)))
            .sorted { self.compareDistances($0, $1, reference: reference) }
        return airports.first?.id
    }
    
    private func predicate(coordinate: CLLocationCoordinate2D?) -> Predicate<Airport> {
        guard let coordinate = coordinate else { return #Predicate { _ in false } }
        
        let lowerLat = (coordinate.latitude - 0.8332) // - 50 NM
        let upperLat = (coordinate.latitude + 0.8332) // + 50 NM
        let lonBracket = 50/degreeLonLen(lat: coordinate.latitude)
        let lowerLon = (coordinate.longitude - lonBracket) // - 50 NM
        let upperLon = (coordinate.longitude + lonBracket) // + 50 NM
        //TODO boundary conditions
        
        return #Predicate<Airport> { airport in
            airport.latitude >= lowerLat &&
            airport.latitude <= upperLat &&
            airport.longitude >= lowerLon &&
            airport.longitude <= upperLon
        }
    }
    
    class LocationDelegate: NSObject, CLLocationManagerDelegate {
        private var target: NearestAirport
        
        init(target: NearestAirport) {
            self.target = target
        }
        
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let coordinate = locations.first?.coordinate else { return }
            Task { await target.setCoordinate(coordinate) }
        }
        
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
            Task { await target.setError(error) }
        }
        
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            Task { await target.setAuthStatus(manager.authorizationStatus) }
        }
    }
}
