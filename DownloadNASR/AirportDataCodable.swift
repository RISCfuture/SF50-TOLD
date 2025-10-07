import Foundation
import SwiftNASR

struct AirportDataCodable: Codable {
  let nasrCycle: Cycle?
  let ourAirportsLastUpdated: Date?
  let airports: [AirportCodable]

  struct AirportCodable: Codable {
    let recordID: String
    let locationID: String
    let ICAO_ID: String?
    let name: String
    let city: String?
    let dataSource: String  // "nasr" or "ourAirports"
    let latitude: Double  // decimal degrees
    let longitude: Double  // decimal degrees
    let elevation: Double  // meters
    let variation: Double  // degrees
    let timeZone: String?  // IANA timezone identifier (e.g., "America/Los_Angeles")
    let runways: [RunwayCodable]
  }

  struct RunwayCodable: Codable {
    let name: String
    let elevation: Double?  // meters
    let trueHeading: Double  // degrees
    let gradient: Float?  // fraction
    let length: Double  // meters
    let takeoffRun: Double?  // meters
    let takeoffDistance: Double?  // meters
    let landingDistance: Double?  // meters
    let isTurf: Bool
    let reciprocalName: String?  // name of reciprocal runway
  }
}
