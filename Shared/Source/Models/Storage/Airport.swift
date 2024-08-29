import Foundation
import SwiftData
import CoreLocation
import MapKit

// roll your own lazy vars
fileprivate var coreLocations = Dictionary<String, CLLocationCoordinate2D>()
fileprivate var mapPoints = Dictionary<String, MKMapPoint>()

@Model final class Airport {
    @Attribute(.unique) var id: String
    @Attribute(.unique) var icao: String? = nil
    @Attribute(.unique) var lid: String
    
    var name: String
    var elevation: Double
    
    var city: String? = nil
    var latitude: Double
    var longitude: Double
    
    var longestRunway: UInt
    
    @Relationship(deleteRule: .cascade, inverse: \Runway.airport) var runways: [Runway] {
        didSet { setLongestRunway() }
    }
    
    var coreLocation: CLLocationCoordinate2D {
        if let loc = coreLocations[id] { return loc }
        let loc =  CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        coreLocations[id] = loc
        return loc
    }
    
    var mapPoint: MKMapPoint {
        if let point = mapPoints[id] { return point }
        let point =  MKMapPoint(coreLocation)
        mapPoints[id] = point
        return point
    }
    
    init(id: String, icao: String? = nil, lid: String, name: String, elevation: Double, city: String? = nil, latitude: Double, longitude: Double, longestRunway: UInt = 0) {
        self.id = id
        self.icao = icao
        self.lid = lid
        self.name = name
        self.elevation = elevation
        self.city = city
        self.latitude = latitude
        self.longitude = longitude
        self.longestRunway = longestRunway
        self.runways = []
    }
    
    func setLongestRunway() {
        longestRunway = runways.filter { !$0.turf }.max { $0.landingDistance < $1.landingDistance }?.landingDistance ?? 0
    }
}
