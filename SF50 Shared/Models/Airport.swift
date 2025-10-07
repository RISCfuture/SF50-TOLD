import CoreLocation
import Foundation
import SwiftData

/// The source of airport data.
public enum DataSource: String, Codable {
  /// National Airspace System Resources (FAA)
  case NASR = "NASR"
  /// OurAirports open data
  case ourAirports = "OurAirports"
}

/// An airport with associated runways and location data.
///
/// `Airport` represents an aerodrome with its associated metadata including
/// location, elevation, magnetic variation, and runways. Airport data is
/// persisted using SwiftData and can be sourced from NASR or OurAirports.
@Model
public final class Airport {
  /// Unique identifier for SwiftData persistence
  @Attribute(.unique)
  public var recordID: String

  /// Airport identifier (e.g., KJFK, KSFO)
  public var locationID: String

  /// ICAO identifier if available
  public var ICAO_ID: String?

  /// Airport name
  public var name: String

  /// City where airport is located
  public var city: String?

  /// Source of airport data (NASR or OurAirports)
  public var dataSource: DataSource

  var _latitude: Double  // decimal degrees
  var _longitude: Double  // decimal degrees
  var _elevation: Double  // meters
  var _variation: Double  // degrees
  var _timeZone: String?  // IANA timezone identifier (e.g., "America/Los_Angeles")

  /// Runways associated with this airport
  @Relationship(deleteRule: .cascade)
  public var runways: [Runway]

  /// Airport latitude in degrees
  public var latitude: Measurement<UnitAngle> {
    get { .init(value: _latitude, unit: .degrees) }
    set { _latitude = newValue.converted(to: .degrees).value }
  }

  /// Airport longitude in degrees
  public var longitude: Measurement<UnitAngle> {
    get { .init(value: _longitude, unit: .degrees) }
    set { _longitude = newValue.converted(to: .degrees).value }
  }

  /// Airport elevation above sea level
  public var elevation: Measurement<UnitLength> {
    get { .init(value: _elevation, unit: .meters) }
    set { _elevation = newValue.converted(to: .meters).value }
  }

  /// Magnetic variation at the airport location
  public var variation: Measurement<UnitAngle> {
    get { .init(value: _variation, unit: .degrees) }
    set { _variation = newValue.converted(to: .degrees).value }
  }

  /// Airport timezone
  public var timeZone: TimeZone? {
    get {
      guard let identifier = _timeZone else { return nil }
      return TimeZone(identifier: identifier)
    }
    set { _timeZone = newValue?.identifier }
  }

  /// CoreLocation coordinate for the airport
  public var coordinate: CLLocationCoordinate2D {
    .init(
      latitude: latitude.converted(to: .degrees).value,
      longitude: longitude.converted(to: .degrees).value
    )
  }

  /// CoreLocation location object for the airport
  public var location: CLLocation {
    .init(
      latitude: latitude.converted(to: .degrees).value,
      longitude: longitude.converted(to: .degrees).value
    )
  }

  /// Display identifier (prefers ICAO for OurAirports, locationID for NASR)
  public var displayID: String {
    if dataSource == .NASR {
      return locationID
    }
    return ICAO_ID ?? locationID
  }

  /// Creates a new airport.
  public init(
    recordID: String,
    locationID: String,
    ICAO_ID: String?,
    name: String,
    city: String?,
    dataSource: DataSource,
    latitude: Measurement<UnitAngle>,
    longitude: Measurement<UnitAngle>,
    elevation: Measurement<UnitLength>,
    variation: Measurement<UnitAngle>,
    timeZone: TimeZone? = nil
  ) {
    self.recordID = recordID
    self.locationID = locationID
    self.ICAO_ID = ICAO_ID
    self.name = name
    self.city = city
    self.dataSource = dataSource
    _latitude = latitude.converted(to: .degrees).value
    _longitude = longitude.converted(to: .degrees).value
    _elevation = elevation.converted(to: .meters).value
    _variation = variation.converted(to: .degrees).value
    _timeZone = timeZone?.identifier
    self.runways = []
  }
}
