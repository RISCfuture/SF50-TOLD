import Foundation
import SF50_Shared

/// Intermediate representation of a NOTAM after parsing with LLM.
///
/// `ParsedNOTAM` bridges the gap between raw NOTAM text and the SwiftData `NOTAM` model.
/// It contains extracted structured data with confidence scores for LLM-parsed fields.
public struct ParsedNOTAM: Sendable {
  /// Source NOTAM IDs this data was extracted from
  public let sourceNOTAMIds: [String]

  /// Runway surface contamination extracted from NOTAM text
  public let contamination: Contamination?

  /// Reduction in takeoff distance available (e.g., displaced threshold)
  public let takeoffDistanceShortening: Measurement<UnitLength>?

  /// Reduction in landing distance available (e.g., displaced threshold)
  public let landingDistanceShortening: Measurement<UnitLength>?

  /// Height of obstacle above runway surface
  public let obstacleHeight: Measurement<UnitLength>?

  /// Distance from runway threshold to obstacle
  public let obstacleDistance: Measurement<UnitLength>?

  /// Confidence score for the parsing (0.0 to 1.0)
  /// - 1.0: High confidence - all fields clearly stated in NOTAM
  /// - 0.5-0.99: Medium confidence - some interpretation required
  /// - 0.0-0.49: Low confidence - ambiguous or incomplete information
  public let confidence: Double

  /// Notes about the parsing (warnings, ambiguities, etc.)
  public let parsingNotes: String?

  /// Creates a new parsed NOTAM result.
  public init(
    sourceNOTAMIds: [String],
    contamination: Contamination? = nil,
    takeoffDistanceShortening: Measurement<UnitLength>? = nil,
    landingDistanceShortening: Measurement<UnitLength>? = nil,
    obstacleHeight: Measurement<UnitLength>? = nil,
    obstacleDistance: Measurement<UnitLength>? = nil,
    confidence: Double = 1.0,
    parsingNotes: String? = nil
  ) {
    self.sourceNOTAMIds = sourceNOTAMIds
    self.contamination = contamination
    self.takeoffDistanceShortening = takeoffDistanceShortening
    self.landingDistanceShortening = landingDistanceShortening
    self.obstacleHeight = obstacleHeight
    self.obstacleDistance = obstacleDistance
    self.confidence = max(0.0, min(1.0, confidence))  // Clamp to 0-1
    self.parsingNotes = parsingNotes
  }

  /// Returns true if no data was successfully extracted from the NOTAM.
  public var isEmpty: Bool {
    contamination == nil
      && takeoffDistanceShortening == nil
      && landingDistanceShortening == nil
      && obstacleHeight == nil
      && obstacleDistance == nil
  }

  /// Returns a confidence level description.
  public var confidenceLevel: ConfidenceLevel {
    if confidence >= 0.8 {
      return .high
    }
    if confidence >= 0.5 {
      return .medium
    }
    return .low
  }

  public enum ConfidenceLevel: String, Sendable {
    case high = "High"
    case medium = "Medium"
    case low = "Low"
  }
}

extension ParsedNOTAM {
  /// Applies this parsed data to a SwiftData NOTAM model.
  ///
  /// - Parameters:
  ///   - notam: The NOTAM model to update
  ///   - operation: The operation type to filter which fields are applied
  ///   - appendSource: If true, appends source NOTAM IDs to existing list; if false, replaces
  public func apply(to notam: NOTAM, for operation: SF50_Shared.Operation, appendSource: Bool = true) {
    switch operation {
    case .takeoff:
      // Takeoff uses: takeoff shortening, obstacle height/distance
      // Does NOT use: contamination, landing shortening
      if let shortening = takeoffDistanceShortening {
        notam.takeoffDistanceShortening = shortening
      }
      if let height = obstacleHeight {
        notam.obstacleHeight = height
      }
      if let distance = obstacleDistance {
        notam.obstacleDistance = distance
      }

    case .landing:
      // Landing uses: contamination, landing shortening
      // Does NOT use: takeoff shortening, obstacle height/distance
      if let contamination {
        notam.contamination = contamination
      }
      if let shortening = landingDistanceShortening {
        notam.landingDistanceShortening = shortening
      }
    }

    // Update source NOTAMs list (only include IDs for fields that were actually applied)
    let relevantSourceIds = relevantSourceNOTAMIds(for: operation)
    if appendSource {
      for sourceId in relevantSourceIds where !notam.sourceNOTAMs.contains(sourceId) {
        notam.sourceNOTAMs.append(sourceId)
      }
    } else {
      notam.sourceNOTAMs = relevantSourceIds
    }

    notam.lastFetched = Date()
  }

  /// Returns the source NOTAM IDs relevant to the given operation.
  private func relevantSourceNOTAMIds(for operation: SF50_Shared.Operation) -> [String] {
    // For now, return all source IDs since we don't track per-field sources
    // In the future, this could be refined to only return IDs for NOTAMs
    // that contributed fields relevant to this operation
    switch operation {
    case .takeoff:
      // Only return IDs if we have takeoff-relevant data
      if takeoffDistanceShortening != nil || obstacleHeight != nil || obstacleDistance != nil {
        return sourceNOTAMIds
      }
      return []
    case .landing:
      // Only return IDs if we have landing-relevant data
      if contamination != nil || landingDistanceShortening != nil {
        return sourceNOTAMIds
      }
      return []
    }
  }

  /// Creates a new SwiftData NOTAM from this parsed data.
  ///
  /// - Parameters:
  ///   - runway: The runway this NOTAM applies to
  ///   - operation: The operation type to filter which fields are included
  /// - Returns: A new NOTAM model instance
  public func createNOTAM(for runway: Runway, operation: SF50_Shared.Operation) -> NOTAM {
    let notam: NOTAM
    switch operation {
    case .takeoff:
      notam = NOTAM(
        runway: runway,
        contamination: nil,  // Not used for takeoff
        takeoffDistanceShortening: takeoffDistanceShortening,
        landingDistanceShortening: nil,  // Not used for takeoff
        obstacleHeight: obstacleHeight,
        obstacleDistance: obstacleDistance
      )
    case .landing:
      notam = NOTAM(
        runway: runway,
        contamination: contamination,
        takeoffDistanceShortening: nil,  // Not used for landing
        landingDistanceShortening: landingDistanceShortening,
        obstacleHeight: nil,  // Not used for landing
        obstacleDistance: nil  // Not used for landing
      )
    }
    notam.sourceNOTAMs = relevantSourceNOTAMIds(for: operation)
    notam.lastFetched = Date()
    notam.automaticallyCreated = true  // Mark as auto-created
    return notam
  }
}

extension ParsedNOTAM {
  /// Creates a new SwiftData NOTAM from multiple parsed NOTAMs.
  ///
  /// This method merges data from multiple parsed NOTAMs into a single NOTAM model.
  ///
  /// - Parameters:
  ///   - parsedNOTAMs: Array of parsed NOTAMs to merge
  ///   - runway: The runway this NOTAM applies to
  /// - Returns: A new NOTAM model instance with merged data
  public static func createMergedNOTAM(from parsedNOTAMs: [ParsedNOTAM], for runway: Runway)
    -> NOTAM
  {
    // Merge all parsed data (taking first non-nil value for each field)
    var contamination: Contamination?
    var takeoffShortening: Measurement<UnitLength>?
    var landingShortening: Measurement<UnitLength>?
    var obstacleHeight: Measurement<UnitLength>?
    var obstacleDistance: Measurement<UnitLength>?
    var sourceIds: [String] = []

    for parsed in parsedNOTAMs {
      if contamination == nil { contamination = parsed.contamination }
      if takeoffShortening == nil { takeoffShortening = parsed.takeoffDistanceShortening }
      if landingShortening == nil { landingShortening = parsed.landingDistanceShortening }
      if obstacleHeight == nil { obstacleHeight = parsed.obstacleHeight }
      if obstacleDistance == nil { obstacleDistance = parsed.obstacleDistance }
      sourceIds.append(contentsOf: parsed.sourceNOTAMIds)
    }

    let notam = NOTAM(
      runway: runway,
      contamination: contamination,
      takeoffDistanceShortening: takeoffShortening,
      landingDistanceShortening: landingShortening,
      obstacleHeight: obstacleHeight,
      obstacleDistance: obstacleDistance
    )
    notam.sourceNOTAMs = sourceIds
    notam.lastFetched = Date()
    notam.automaticallyCreated = true  // Mark as auto-created
    return notam
  }
}
