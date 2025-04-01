import Combine
import CoreData
import CoreLocation
import Foundation
import Logging
import MapKit

private let earthRadius = 21638.0 // NM

private func degreeLonLen(lat: Double) -> Double {
    cos(deg2rad(lat)) * (earthRadius / 360)
}
class NearestAirportPublisher: NSObject, ObservableObject, CLLocationManagerDelegate {
    private static let logger = Logger(label: "codes.tim.SF50-TOLD.NearestAirportPublisher")

    @Published var nearestAirportID: String?
    @Published var location: CLLocationCoordinate2D?
    @Published var loading = false
    @Published var errorText: String?
    @Published var authorizationStatus: CLAuthorizationStatus?

    private let manager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()

    var predicate: NSPredicate { predicate(coordinate: location) }

    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startMonitoringSignificantLocationChanges()
    }

    func request() {
        loading = true
        errorText = nil
        location = nil
        manager.requestLocation()
    }

    func locationManager(_: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task.detached(priority: .background) {
            guard let coordinate = locations.first?.coordinate else { return }
            let nearestAirportID = await self.findNearestAirportID(to: coordinate)
            RunLoop.main.perform {
                self.location = coordinate
                self.errorText = nil
                self.loading = false
                self.nearestAirportID = nearestAirportID
            }
        }
    }

    func locationManager(_: CLLocationManager, didFailWithError error: Swift.Error) {
        Self.logger.error("CLLocationManager: error", metadata: ["error": "\(error.localizedDescription)"])
        RunLoop.main.perform {
            self.location = nil
            self.errorText = error.localizedDescription
            self.loading = false
            self.nearestAirportID = nil
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        self.authorizationStatus = manager.authorizationStatus
    }

    func airportDistance(_ airport1: Airport, _ airport2: Airport) -> Bool {
        guard let location else { return false }

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

    private func location() async -> CLLocationCoordinate2D {
        return await withCheckedContinuation { continuation in
            $location.sink { location in
                guard let location else { return }
                continuation.resume(with: .success(location))
            }
            .store(in: &cancellables)
        }
    }

    func findNearestAirportID() async -> String? {
        return await findNearestAirportID(to: location())
    }

    func findNearestAirportID(to coordinate: CLLocationCoordinate2D) async -> String? {
        let reference = MKMapPoint(coordinate)
        return await withCheckedContinuation { continuation in
            PersistentContainer.shared.newBackgroundContext().perform {
                let request = NSFetchRequest<Airport>(entityName: "Airport")
                request.predicate = self.predicate(coordinate: coordinate)
                do {
                    let airports = try request.execute().sorted { self.compareDistances($0, $1, reference: reference) }
                    continuation.resume(returning: airports.first?.id)
                } catch {
                    Self.logger.error("findNearestAirportID(): error", metadata: ["error": "\(error.localizedDescription)"])
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    private func predicate(coordinate: CLLocationCoordinate2D?) -> NSPredicate {
        guard let coordinate else { return .init(value: false) }

        let lowerLat = (coordinate.latitude - 0.8332) // - 50 NM
        let upperLat = (coordinate.latitude + 0.8332) // + 50 NM
        let lonBracket = 50 / degreeLonLen(lat: coordinate.latitude)
        let lowerLon = (coordinate.longitude - lonBracket) // - 50 NM
        let upperLon = (coordinate.longitude + lonBracket) // + 50 NM
        // TODO boundary conditions

        return .init(format: "latitude > %f AND latitude < %f AND longitude > %f AND longitude < %f AND longestRunway >= %d",
                     lowerLat, upperLat, lowerLon, upperLon, minRunwayLength)
    }

    deinit {
        manager.stopMonitoringSignificantLocationChanges()
        for cancellable in cancellables { cancellable.cancel() }
    }
}
