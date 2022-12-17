import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    
    @Published var location: CLLocationCoordinate2D?
    @Published var authorizationStatus: CLAuthorizationStatus?
    @Published var errorText: String? = nil
    @Published var loading = false
    
    var isAuthorized: Bool {
        guard let authorizationStatus = authorizationStatus else { return false }
        switch authorizationStatus {
            case .notDetermined, .restricted, .denied: return false
            case .authorizedAlways, .authorizedWhenInUse, .authorized: return true
            @unknown default: return false
        }
    }
    
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
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
    }
}
