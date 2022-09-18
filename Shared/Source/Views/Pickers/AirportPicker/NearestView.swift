import SwiftUI
import CoreData
import CoreLocation
import CoreLocationUI
import MapKit

fileprivate class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var errorText: String? = nil
    @Published var loading = false
    
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startMonitoringSignificantLocationChanges()
    }
    
    deinit {
        manager.stopMonitoringSignificantLocationChanges()
    }
    
    func requestLocation() {
        loading = true
        errorText = nil
        location = nil
        manager.requestLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first?.coordinate
        errorText = nil
        loading = false
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Swift.Error) {
        location = nil
        errorText = error.localizedDescription
        loading = false
    }
}

fileprivate let earthRadius = 21638.0 // NM

fileprivate func degreeLonLen(lat: Double) -> Double {
    cos(deg2rad(lat))*(earthRadius/360)
}

struct NearestView: View {
    @StateObject fileprivate var locationManager = LocationManager()
    
    var onSelect: (Airport) -> Void
    
    private var predicate: NSPredicate {
        guard let location = locationManager.location else { return .init() }
        
        let lowerLat = (location.latitude - 0.8332) // - 50 NM
        let upperLat = (location.latitude + 0.8332) // + 50 NM
        let lonBracket = 50/degreeLonLen(lat: location.latitude)
        let lowerLon = (location.longitude - lonBracket) // - 50 NM
        let upperLon = (location.longitude + lonBracket) // + 50 NM
        //TODO boundary conditions
        
        return .init(format: "latitude > %f AND latitude < %f AND longitude > %f AND longitude < %f AND longestRunway >= %d",
                     lowerLat, upperLat, lowerLon, upperLon, minRunwayLength)
    }
    
    private var fetchAirports: FetchRequest<Airport> {
        return .init(entity: Airport.entity(),
                     sortDescriptors: [.init(keyPath: \Airport.id, ascending: true)],
                     predicate: predicate)
    }

    var body: some View {
        if locationManager.loading {
            List {
                HStack(spacing: 5) {
                    ProgressView()
                    Text("Finding airports…")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        } else if let error = locationManager.errorText {
            List {
                Text(error)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
            }
        } else if locationManager.location != nil {
            ListResults(airports: fetchAirports, sort: airportDistance, onSelect: onSelect)
        } else {
            LocationButton { locationManager.requestLocation() }
                .clipShape(Capsule())
                .symbolVariant(.fill)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                .foregroundColor(.white)
        }
    }
    
    private func airportDistance(_ airport1: Airport, _ airport2: Airport) -> Bool {
        guard let location = locationManager.location else { return false }
        
        let myPoint = MKMapPoint(location)
        let dist1 = airport1.mapPoint.distance(to: myPoint)
        let dist2 = airport2.mapPoint.distance(to: myPoint)
        
        return dist1 < dist2
    }
}

struct NearestView_Previews: PreviewProvider {
    private static let OAK = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "OAK"
        a.name = "Metro Oakland Intl"
        return a
    }()
    private static let SQL = { () -> Airport in
        let a = Airport(entity: Airport.entity(), insertInto: nil)
        a.lid = "SQL"
        a.name = "San Carlos"
        return a
    }()
    
    static var previews: some View {
        NearestView() { _ in }
    }
}
