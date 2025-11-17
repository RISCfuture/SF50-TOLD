import Foundation
import SwiftNASR

public struct AirportDataCodable: Codable, Sendable {
  public let nasrCycle: Cycle?
  public let ourAirportsLastUpdated: Date?
  public let airports: [AirportCodable]

  public struct AirportCodable: Codable, Sendable {
    public let recordID: String
    public let locationID: String
    public let ICAO_ID: String?
    public let name: String
    public let city: String?
    public let dataSource: String  // "nasr" or "ourAirports"
    public let latitude: Double  // decimal degrees
    public let longitude: Double  // decimal degrees
    public let elevation: Double  // meters
    public let variation: Double  // degrees
    public let timeZone: String?  // IANA timezone identifier (e.g., "America/Los_Angeles")
    public let runways: [RunwayCodable]
  }

  public struct RunwayCodable: Codable, Sendable {
    public let name: String
    public let elevation: Double?  // meters
    public let trueHeading: Double  // degrees
    public let gradient: Float?  // fraction
    public let length: Double  // meters
    public let takeoffRun: Double?  // meters
    public let takeoffDistance: Double?  // meters
    public let landingDistance: Double?  // meters
    public let isTurf: Bool
    public let reciprocalName: String?  // name of reciprocal runway
  }
}
