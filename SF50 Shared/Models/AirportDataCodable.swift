import Foundation
import SwiftNASR

/// Codable container for the airport database distributed with the app.
///
/// ``AirportDataCodable`` represents the entire airport database in a format
/// suitable for encoding to property list and LZMA compression. It combines
/// data from FAA NASR and OurAirports sources.
///
/// ## Data Sources
///
/// The database merges two sources with NASR taking priority:
/// - **NASR**: FAA National Airspace System Resources (US airports)
/// - **OurAirports**: Community database (international airports)
///
/// ## File Format
///
/// The data is serialized to binary property list format, then LZMA-compressed
/// for distribution. Files are named by AIRAC cycle (e.g., `2501.plist.lzma`).
///
/// ## See Also
///
/// - ``AirportCodable``
/// - ``RunwayCodable``
public struct AirportDataCodable: Codable, Sendable {
  /// NASR AIRAC cycle identifier (e.g., 2501 for January 2025)
  public let nasrCycle: Cycle?

  /// Date when OurAirports data was last updated
  public let ourAirportsLastUpdated: Date?

  /// All airports in the database
  public let airports: [AirportCodable]

  /**
   * Codable representation of an airport.
   *
   * ``AirportCodable`` stores airport data in a format optimized for
   * serialization and storage. All measurements use metric units (meters, degrees).
   */
  public struct AirportCodable: Codable, Sendable {
    /// Unique database record identifier
    public let recordID: String

    /// FAA location identifier (e.g., "SFO")
    public let locationID: String

    /// ICAO identifier if available (e.g., "KSFO")
    public let ICAO_ID: String?

    /// Airport name
    public let name: String

    /// City or municipality
    public let city: String?

    /// Data source: "nasr" or "ourAirports"
    public let dataSource: String

    /// Latitude in decimal degrees
    public let latitude: Double

    /// Longitude in decimal degrees
    public let longitude: Double

    /// Field elevation in meters
    public let elevation: Double

    /// Magnetic variation in degrees (positive = east)
    public let variation: Double

    /// IANA timezone identifier (e.g., "America/Los_Angeles")
    public let timeZone: String?

    /// Runways at this airport
    public let runways: [RunwayCodable]
  }

  /**
   * Codable representation of a runway.
   *
   * ``RunwayCodable`` stores runway data in metric units for serialization.
   * Each physical runway is represented as two separate entries (one per direction).
   */
  public struct RunwayCodable: Codable, Sendable {
    /// Runway designator (e.g., "28L")
    public let name: String

    /// Threshold elevation in meters (nil if not available)
    public let elevation: Double?

    /// True heading in degrees
    public let trueHeading: Double

    /// Gradient as a fraction (positive = uphill)
    public let gradient: Float?

    /// Total runway length in meters
    public let length: Double

    /// Takeoff run available (TORA) in meters
    public let takeoffRun: Double?

    /// Takeoff distance available (TODA) in meters
    public let takeoffDistance: Double?

    /// Landing distance available (LDA) in meters
    public let landingDistance: Double?

    /// Whether the runway has a turf (grass) surface
    public let isTurf: Bool

    /// Name of the reciprocal runway (e.g., "10R" for runway "28L")
    public let reciprocalName: String?
  }
}
