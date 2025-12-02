import Foundation
import FoundationModels
import SF50_Shared

/// Extracted contamination data from a NOTAM.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct ContaminationExtraction: Sendable {
  @Guide(description: "Type: water, slush, wetSnow, drySnow, ice, compactedSnow")
  let type: String?

  @Guide(description: "Coverage percentage (0-100)")
  let coverage: Int?

  @Guide(description: "Depth value")
  let depth: Double?

  @Guide(description: "Depth units: in, mm, or cm")
  let depthUnits: String?

  /// Converts to the app's Contamination type.
  var contamination: SF50_Shared.Contamination? {
    guard let type else { return nil }

    switch type.lowercased() {
      case "water", "slush":
        guard let depthMeasurement else { return nil }
        return .waterOrSlush(depth: depthMeasurement)
      case "wetsnow", "wet_snow":
        guard let depthMeasurement else { return nil }
        return .slushOrWetSnow(depth: depthMeasurement)
      case "drysnow", "dry_snow":
        return .drySnow
      case "ice", "compactedsnow", "compacted_snow":
        return .compactSnow
      default:
        return nil
    }
  }

  /// Depth as a measurement.
  private var depthMeasurement: Measurement<UnitLength>? {
    guard let depth, let depthUnits else { return nil }
    let unit: UnitLength? =
      switch depthUnits.lowercased() {
        case "in": .inches
        case "mm": .millimeters
        case "cm": .centimeters
        default: nil
      }
    guard let unit else { return nil }
    return Measurement(value: depth, unit: unit)
  }
}

/// Extracted runway performance data from a single NOTAM.
///
/// This struct matches the training data schema used to fine-tune the adapter.
/// Property order matters - place fields in generation order with notes last.
@available(iOS 26.0, macOS 26.0, *)
@Generable
struct NOTAMExtraction: Sendable {
  @Guide(description: "Airport ICAO identifier (e.g., KSFO)")
  let airportID: String?

  @Guide(description: "Runway designator (e.g., 09L, 27R) or null if not runway-specific")
  let runway: String?

  @Guide(description: "Effective start time in ISO8601 format")
  let effectiveStart: String?

  @Guide(description: "Effective end time in ISO8601 format")
  let effectiveEnd: String?

  @Guide(description: "True if this NOTAM cancels a previous NOTAM")
  let isCanceled: Bool?

  @Guide(description: "True if runway is fully closed")
  let runwayClosed: Bool?

  @Guide(description: "Takeoff distance reduction from displaced threshold or closure")
  let takeoffShortening: Double?

  @Guide(description: "Units for takeoff shortening: ft or m")
  let takeoffShorteningUnits: String?

  @Guide(description: "Landing distance reduction from displaced threshold or closure")
  let landingShortening: Double?

  @Guide(description: "Units for landing shortening: ft or m")
  let landingShorteningUnits: String?

  @Guide(description: "Takeoff Run Available")
  let TORA: Double?

  @Guide(description: "Units for TORA: ft or m")
  let TORAUnits: String?

  @Guide(description: "Takeoff Distance Available")
  let TODA: Double?

  @Guide(description: "Units for TODA: ft or m")
  let TODAUnits: String?

  @Guide(description: "Landing Distance Available")
  let LDA: Double?

  @Guide(description: "Units for LDA: ft or m")
  let LDAUnits: String?

  @Guide(description: "Obstacle height above ground level (AGL)")
  let obstacleHeight: Double?

  @Guide(description: "Units for obstacle height AGL: ft or m")
  let obstacleHeightUnits: String?

  @Guide(description: "Obstacle elevation above mean sea level (MSL)")
  let obstacleHeightMSL: Double?

  @Guide(description: "Units for obstacle MSL: ft or m")
  let obstacleHeightMSLUnits: String?

  @Guide(description: "Distance from reference point to obstacle")
  let obstacleDistance: Double?

  @Guide(description: "Units for obstacle distance: ft, m, or nm")
  let obstacleDistanceUnits: String?

  @Guide(description: "Bearing from reference point in degrees (0-360)")
  let obstacleBearing: Double?

  @Guide(description: "GPS coordinates in decimal format (e.g., 37.123456, -122.456789)")
  let obstacleCoordinates: String?

  @Guide(description: "Reference point for distance measurement (e.g., THR 27, ARP)")
  let obstacleReferencePoint: String?

  @Guide(description: "Array of contamination conditions on the runway")
  let contaminations: [ContaminationExtraction]?

  @Guide(description: "Required climb gradient value")
  let requiredClimbGradient: Double?

  @Guide(description: "Units for climb gradient: percent or ft/nm")
  let requiredClimbGradientUnits: String?

  @Guide(description: "Source NOTAM IDs this data was extracted from")
  let sourceNOTAMIDs: [String]?

  @Guide(description: "Additional notes or warnings about the extraction")
  let notes: String?
}

@available(iOS 26.0, macOS 26.0, *)
extension NOTAMExtraction {
  private var takeoffShorteningMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: takeoffShortening, units: takeoffShorteningUnits)
  }

  private var landingShorteningMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: landingShortening, units: landingShorteningUnits)
  }

  private var toraMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: TORA, units: TORAUnits)
  }

  private var todaMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: TODA, units: TODAUnits)
  }

  private var ldaMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: LDA, units: LDAUnits)
  }

  private var obstacleHeightMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: obstacleHeight, units: obstacleHeightUnits)
  }

  private var obstacleHeightMSLMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: obstacleHeightMSL, units: obstacleHeightMSLUnits)
  }

  private var obstacleDistanceMeasurement: Measurement<UnitLength>? {
    lengthMeasurement(value: obstacleDistance, units: obstacleDistanceUnits)
  }

  /// Contamination with highest coverage percentage, or first if no coverage data.
  private var primaryContamination: SF50_Shared.Contamination? {
    guard let contaminations, !contaminations.isEmpty else { return nil }
    let sorted = contaminations.sorted { ($0.coverage ?? 0) > ($1.coverage ?? 0) }
    return sorted.first?.contamination
  }

  /// Converts this extraction to an `InterpretedNOTAM` for use with the existing data model.
  func toInterpretedNOTAM() -> InterpretedNOTAM {
    InterpretedNOTAM(
      sourceNOTAMIDs: sourceNOTAMIDs ?? [],
      contamination: primaryContamination,
      takeoffDistanceShortening: takeoffShorteningMeasurement,
      landingDistanceShortening: landingShorteningMeasurement,
      obstacleHeight: obstacleHeightMeasurement,
      obstacleDistance: obstacleDistanceMeasurement,
      confidence: 0.9,
      parsingNotes: notes
    )
  }

  private func lengthMeasurement(value: Double?, units: String?) -> Measurement<UnitLength>? {
    guard let value, value > 0, let units else { return nil }
    let unit: UnitLength? =
      switch units.lowercased() {
        case "ft", "feet": .feet
        case "m", "meters": .meters
        case "nm", "nautical miles": .nauticalMiles
        default: nil
      }
    guard let unit else { return nil }
    return Measurement(value: value, unit: unit)
  }
}
