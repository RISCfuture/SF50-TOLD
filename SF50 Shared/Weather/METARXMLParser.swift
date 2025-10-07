import Foundation
import Logging

public struct METAR: Sendable {
  public let stationID: String
  public let observationTime: Date
  public let temperature: Double?
  public let dewpoint: Double?
  public let windDirection: Int?  // nil for VRB
  public let windSpeed: Int
  public let windGust: Int?
  public let altimeter: Double?
  public let seaLevelPressure: Double?
  public let rawText: String

  public init(
    stationID: String,
    observationTime: Date,
    temperature: Double?,
    dewpoint: Double?,
    windDirection: Int?,
    windSpeed: Int,
    windGust: Int?,
    altimeter: Double?,
    seaLevelPressure: Double?,
    rawText: String
  ) {
    self.stationID = stationID
    self.observationTime = observationTime
    self.temperature = temperature
    self.dewpoint = dewpoint
    self.windDirection = windDirection
    self.windSpeed = windSpeed
    self.windGust = windGust
    self.altimeter = altimeter
    self.seaLevelPressure = seaLevelPressure
    self.rawText = rawText
  }
}

final class METARXMLParser: NSObject, XMLParserDelegate {
  private static let logger = Logger(label: "codes.tim.SF50-TOLD.METARXMLParser")

  private let continuation: AsyncStream<(String, METAR)>.Continuation
  private var currentElement: String?
  private var currentMETAR: METARData?

  private init(continuation: AsyncStream<(String, METAR)>.Continuation) {
    self.continuation = continuation
    super.init()
  }

  static func parse(data: Data) -> AsyncStream<(String, METAR)> {
    AsyncStream { continuation in
      Task {
        let parser = METARXMLParser(continuation: continuation)
        let xmlParser = XMLParser(data: data)
        xmlParser.delegate = parser

        let success = xmlParser.parse()

        if !success {
          Self.logger.error(
            "XML parsing failed",
            metadata: ["error": "\(xmlParser.parserError?.localizedDescription ?? "unknown")"]
          )
        }

        continuation.finish()
      }
    }
  }

  func parser(
    _: XMLParser,
    didStartElement elementName: String,
    namespaceURI _: String?,
    qualifiedName _: String?,
    attributes _: [String: String] = [:]
  ) {
    handleStartElement(elementName)
  }

  func parser(
    _: XMLParser,
    didEndElement elementName: String,
    namespaceURI _: String?,
    qualifiedName _: String?
  ) {
    handleEndElement(elementName)
  }

  func parser(_: XMLParser, foundCharacters string: String) {
    handleCharacters(string)
  }

  private func handleStartElement(_ elementName: String) {
    currentElement = elementName

    if elementName == "METAR" {
      currentMETAR = METARData()
    }
  }

  private func handleEndElement(_ elementName: String) {
    if elementName == "METAR", let metarData = currentMETAR {
      // Try to build observation from collected data
      guard let stationID = metarData.stationID,
        let rawText = metarData.rawText
      else {
        Self.logger.error(
          "Incomplete METAR data",
          metadata: ["stationID": "\(metarData.stationID ?? "nil")"]
        )
        currentMETAR = nil
        return
      }

      // Parse wind direction - handle VRB
      var windDir: Int?
      if let windDirStr = metarData.windDirection {
        if windDirStr != "VRB" {
          windDir = Int(windDirStr)
        }
      }

      let observation = METAR(
        stationID: stationID,
        observationTime: metarData.observationTime ?? Date(),
        temperature: metarData.temperature,
        dewpoint: metarData.dewpoint,
        windDirection: windDir,
        windSpeed: metarData.windSpeed ?? 0,
        windGust: metarData.windGust,
        altimeter: metarData.altimeter,
        seaLevelPressure: metarData.seaLevelPressure,
        rawText: rawText
      )

      continuation.yield((stationID, observation))
      currentMETAR = nil
    }

    currentElement = nil
  }

  private func handleCharacters(_ string: String) {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty, currentMETAR != nil else { return }

    switch currentElement {
      case "station_id":
        currentMETAR?.stationID = trimmed
      case "observation_time":
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        currentMETAR?.observationTime = formatter.date(from: trimmed)
      case "temp_c":
        currentMETAR?.temperature = Double(trimmed)
      case "dewpoint_c":
        currentMETAR?.dewpoint = Double(trimmed)
      case "wind_dir_degrees":
        currentMETAR?.windDirection = trimmed
      case "wind_speed_kt":
        currentMETAR?.windSpeed = Int(trimmed)
      case "wind_gust_kt":
        currentMETAR?.windGust = Int(trimmed)
      case "altim_in_hg":
        currentMETAR?.altimeter = Double(trimmed)
      case "sea_level_pressure_mb":
        currentMETAR?.seaLevelPressure = Double(trimmed)
      case "raw_text":
        currentMETAR?.rawText = trimmed
      default:
        break
    }
  }

  private struct METARData {
    var stationID: String?
    var observationTime: Date?
    var temperature: Double?
    var dewpoint: Double?
    var windDirection: String?
    var windSpeed: Int?
    var windGust: Int?
    var altimeter: Double?
    var seaLevelPressure: Double?
    var rawText: String?
  }
}
