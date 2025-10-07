import Foundation
import Logging

public struct TAF: Sendable {
  public let validFrom: Date
  public let validTo: Date
  public let windDirection: Int?  // nil for VRB
  public let windSpeed: Int?
  public let windGust: Int?
  public let altimeter: Double?

  public init(
    validFrom: Date,
    validTo: Date,
    windDirection: Int?,
    windSpeed: Int?,
    windGust: Int?,
    altimeter: Double?
  ) {
    self.validFrom = validFrom
    self.validTo = validTo
    self.windDirection = windDirection
    self.windSpeed = windSpeed
    self.windGust = windGust
    self.altimeter = altimeter
  }
}

public struct TAFData: Sendable {
  public let stationID: String
  public let forecasts: [TAF]
  public let rawText: String

  public init(stationID: String, forecasts: [TAF], rawText: String) {
    self.stationID = stationID
    self.forecasts = forecasts
    self.rawText = rawText
  }
}

final class TAFXMLParser: NSObject, XMLParserDelegate {
  private static let logger = Logger(label: "codes.tim.SF50-TOLD.TAFXMLParser")

  private let continuation: AsyncStream<(String, TAFData)>.Continuation
  private var currentElement: String?
  private var currentTAF: TAFInfo?
  private var currentForecast: ForecastData?
  private var isInCDATA = false
  private var cdataContent = ""

  private init(continuation: AsyncStream<(String, TAFData)>.Continuation) {
    self.continuation = continuation
    super.init()
  }

  static func parse(data: Data) -> AsyncStream<(String, TAFData)> {
    AsyncStream { continuation in
      Task {
        let parser = TAFXMLParser(continuation: continuation)
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

  func parser(_: XMLParser, foundCDATA CDATABlock: Data) {
    handleCDATA(CDATABlock)
  }

  private func handleStartElement(_ elementName: String) {
    currentElement = elementName

    if elementName == "TAF" {
      currentTAF = TAFInfo()
    } else if elementName == "forecast" {
      currentForecast = ForecastData()
    }
  }

  private func handleEndElement(_ elementName: String) {
    if elementName == "TAF", let tafInfo = currentTAF {
      // Try to build TAF from collected data
      guard let stationID = tafInfo.stationID,
        let rawText = tafInfo.rawText
      else {
        Self.logger.error(
          "Incomplete TAF data",
          metadata: ["stationID": "\(tafInfo.stationID ?? "nil")"]
        )
        currentTAF = nil
        return
      }

      let tafData = TAFData(
        stationID: stationID,
        forecasts: tafInfo.forecasts,
        rawText: rawText
      )

      continuation.yield((stationID, tafData))
      currentTAF = nil
    } else if elementName == "forecast", let forecastData = currentForecast {
      // Add forecast to current TAF
      guard let validFrom = forecastData.validFrom,
        let validTo = forecastData.validTo
      else {
        Self.logger.error("Incomplete forecast data in TAF")
        currentForecast = nil
        return
      }

      // Parse wind direction - handle VRB
      var windDir: Int?
      if let windDirStr = forecastData.windDirection {
        if windDirStr != "VRB" {
          windDir = Int(windDirStr)
        }
      }

      let forecast = TAF(
        validFrom: validFrom,
        validTo: validTo,
        windDirection: windDir,
        windSpeed: forecastData.windSpeed,
        windGust: forecastData.windGust,
        altimeter: forecastData.altimeter
      )

      currentTAF?.forecasts.append(forecast)
      currentForecast = nil
    }

    currentElement = nil
  }

  private func handleCharacters(_ string: String) {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }

    if currentTAF != nil {
      switch currentElement {
        case "station_id":
          currentTAF?.stationID = trimmed
        default:
          break
      }
    }

    if currentForecast != nil {
      switch currentElement {
        case "fcst_time_from":
          let formatter = ISO8601DateFormatter()
          formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          currentForecast?.validFrom = formatter.date(from: trimmed)
        case "fcst_time_to":
          let formatter = ISO8601DateFormatter()
          formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
          currentForecast?.validTo = formatter.date(from: trimmed)
        case "wind_dir_degrees":
          currentForecast?.windDirection = trimmed
        case "wind_speed_kt":
          currentForecast?.windSpeed = Int(trimmed)
        case "wind_gust_kt":
          currentForecast?.windGust = Int(trimmed)
        case "altim_in_hg":
          currentForecast?.altimeter = Double(trimmed)
        default:
          break
      }
    }
  }

  private func handleCDATA(_ cdataBlock: Data) {
    if currentElement == "raw_text", let string = String(data: cdataBlock, encoding: .utf8) {
      currentTAF?.rawText = string.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  }

  private struct TAFInfo {
    var stationID: String?
    var rawText: String?
    var forecasts: [TAF] = []
  }

  private struct ForecastData {
    var validFrom: Date?
    var validTo: Date?
    var windDirection: String?
    var windSpeed: Int?
    var windGust: Int?
    var altimeter: Double?
  }
}
