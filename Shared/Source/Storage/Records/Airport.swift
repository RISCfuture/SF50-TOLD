import CoreData
import CoreLocation
import MapKit
import Dispatch

// roll your own lazy vars
fileprivate var coreLocations = Dictionary<String, CLLocationCoordinate2D>()
fileprivate var mapPoints = Dictionary<String, MKMapPoint>()

extension Airport {
    var coreLocation: CLLocationCoordinate2D {
        if let loc = coreLocations[id!] { return loc }
        let loc =  CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        coreLocations[id!] = loc
        return loc
    }
    
    var mapPoint: MKMapPoint {
        if let point = mapPoints[id!] { return point }
        let point =  MKMapPoint(coreLocation)
        mapPoints[id!] = point
        return point
    }
    
    static func byIDRequest(id: String) -> NSFetchRequest<Airport> {
        let request = NSFetchRequest<Airport>(entityName: "Airport")
        request.fetchLimit = 1
        request.includesPropertyValues = true
        request.includesSubentities = true
        request.returnsObjectsAsFaults = false
        let predicate = NSPredicate(format: "id == %@", id)
        request.predicate = predicate
        return request
    }
}
