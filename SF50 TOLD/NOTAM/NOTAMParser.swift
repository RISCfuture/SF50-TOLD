import Foundation
import FoundationModels
import Logging
import SF50_Shared

/// Actor responsible for parsing NOTAM text using Apple Intelligence.
///
/// `NOTAMParser` extracts structured runway performance data from NOTAM text,
/// including contamination, distance shortenings, and obstacles.
public actor NOTAMParser {
  /// Shared singleton instance
  public static let shared = NOTAMParser()

  /// Logger for parsing operations
  private static let logger = Logger(label: "codes.tim.SF50-TOLD.NOTAMParser")

  /// Private initializer to enforce singleton pattern
  private init() {}

  // MARK: - AI Extraction Model

  /// Structured output model for AI-powered NOTAM extraction
  @Generable
  struct NOTAMExtraction {
    @Guide(
      description: """
        Runway shortening for TAKEOFF in feet. ONLY extract when the NOTAM explicitly states \
        a displaced threshold or closed runway portion with a SPECIFIC DISTANCE.

        EXTRACT from NOTAMs like:
        - "RWY 04R THR DSPLCD 500 FT" → 500
        - "RWY 28L FIRST 300FT CLSD" → 300

        DO NOT EXTRACT from:
        - FICON NOTAMs (runway condition reports with snow/ice) - these are contamination only
        - Q-line coordinates like "6449N14751W005" - these are GPS positions, NOT distances
        - "RWY CLSD" without a distance - this is a full closure, not shortening
        """
    )
    let takeoffShorteningFeet: Double?

    @Guide(
      description: """
        Runway shortening for LANDING in feet. ONLY extract when the NOTAM explicitly states \
        a displaced threshold or closed runway portion with a SPECIFIC DISTANCE.

        EXTRACT from NOTAMs like:
        - "RWY 16 THR DSPLCD 200M" → 656 (convert meters to feet)
        - "LDG DIST REDUCED BY 400FT" → 400

        DO NOT EXTRACT from:
        - FICON NOTAMs (runway condition reports) - these are contamination only
        - Q-line coordinates - these are GPS positions, NOT distances
        """
    )
    let landingShorteningFeet: Double?

    @Guide(
      description: """
        Obstacle height in feet AGL. ONLY extract from OBST NOTAMs about physical obstacles.

        EXTRACT from NOTAMs like:
        - "OBST CRANE ERECTED PSN 183431N0695855W ELEV 161FT HTG 80FT" → 80 (use HTG/height, not ELEV)
        - "OBST TOWER 150FT AGL" → 150

        DO NOT EXTRACT obstacle heights from non-OBST NOTAMs.
        """
    )
    let obstacleHeightFeet: Double?

    @Guide(
      description: """
        Obstacle distance from runway threshold in nautical miles. Convert feet to NM by \
        dividing by 6076.

        EXTRACT from NOTAMs like:
        - "OBST 2000FT FM THR" → 0.33
        - "CRANE 0.5NM FROM RWY END" → 0.5
        """
    )
    let obstacleDistanceNM: Double?

    @Guide(
      description: """
        Runway surface contamination type. ONLY extract from FICON (Field Condition) NOTAMs.

        FICON NOTAMs report runway surface conditions using codes like "5/5/5" or text \
        descriptions. The Q-line contains "QMRXX" for runway condition reports.

        EXTRACT from NOTAMs like:
        - "FAI RWY 02L FICON 5/5/5 10 PCT COMPACTED SN AND 25 PCT 1/8IN DRY" → compactedSnow
        - "RWY 09/27 CONTAMINATED WITH WET SNOW 3MM" → wetSnow
        - "RWY COVERED WITH ICE" → ice
        - "STANDING WATER ON RWY" → water

        DO NOT extract contamination from non-FICON NOTAMs (runway closures, displaced \
        thresholds, obstacles, etc.)
        """,
      .anyOf(["water", "slush", "wetSnow", "drySnow", "ice", "compactedSnow"])
    )
    let contaminationType: String?

    @Guide(
      description: """
        Contamination depth in inches. Convert from metric: mm ÷ 25.4, cm ÷ 2.54.

        EXTRACT from NOTAMs like:
        - "3MM WET SNOW" → 0.12
        - "1/8IN DRY SNOW" → 0.125
        - "2CM SLUSH" → 0.79

        Only applicable for water, slush, or wet snow. Dry snow and ice typically don't \
        have measurable depth.
        """
    )
    let contaminationDepthInches: Double?

    @Guide(description: "The NOTAM ID this data was extracted from")
    let sourceNOTAMIds: [String]

    @Guide(description: "Any warnings or notes about ambiguous data in the NOTAM")
    let notes: String?
  }

  /// Parses multiple NOTAMs to extract runway performance data.
  ///
  /// This method uses Apple's on-device Intelligence to parse NOTAM text and extract:
  /// - Runway contamination (type and depth)
  /// - Takeoff/landing distance shortenings (displaced thresholds)
  /// - Obstacle information (height and distance)
  ///
  /// Uses confidence-based fallback: if AI extraction has confidence < 0.5, falls back to keyword parsing.
  ///
  /// - Parameters:
  ///   - notams: Array of NOTAM responses to parse
  ///   - runwayName: Name of the runway (e.g., "30", "16L")
  /// - Returns: Parsed NOTAM data with confidence score, or nil if no relevant data
  /// - Throws: `NOTAMParser.Errors` on parsing failure
  public func parse(notams: [NOTAMResponse], for runwayName: String) async throws -> ParsedNOTAM? {
    guard !notams.isEmpty else { return nil }

    Self.logger.info(
      "Parsing NOTAMs for runway",
      metadata: ["runway": "\(runwayName)", "count": "\(notams.count)"]
    )

    // Try using Apple Intelligence first
    if let intelligenceResult = try? await parseWithIntelligence(
      notams: notams, runway: runwayName)
    {
      // Check confidence threshold
      if intelligenceResult.confidence >= 0.5 {
        Self.logger.info(
          "Successfully parsed with Apple Intelligence",
          metadata: ["confidence": "\(String(format: "%.2f", intelligenceResult.confidence))"]
        )
        return intelligenceResult
      } else {
        Self.logger.warning(
          "AI extraction confidence too low, falling back to keyword parsing",
          metadata: ["confidence": "\(String(format: "%.2f", intelligenceResult.confidence))"]
        )
      }
    }

    Self.logger.warning("Using keyword parsing fallback")

    // Fall back to keyword-based parsing if AI is unavailable or low confidence
    return try await parseWithKeywords(notams: notams, runway: runwayName)
  }

  /// Parses NOTAMs using Apple FoundationModels for AI-powered extraction.
  private func parseWithIntelligence(notams: [NOTAMResponse], runway: String) async throws
    -> ParsedNOTAM?
  {
    // Parse NOTAMs concurrently for better performance
    let startTime = Date()
    Self.logger.info("Starting concurrent parsing", metadata: ["count": "\(notams.count)"])

    let allExtractions = await withTaskGroup(
      of: NOTAMExtraction?.self,
      returning: [NOTAMExtraction].self
    ) { group in
      for notam in notams {
        group.addTask {
          let taskStart = Date()
          do {
            let result = try await self.parseIndividualNOTAM(notam, runway: runway)
            let duration = Date().timeIntervalSince(taskStart)
            Self.logger.debug(
              "Parsed NOTAM",
              metadata: [
                "notamId": "\(notam.notamId)",
                "duration": "\(String(format: "%.2f", duration))s"
              ]
            )
            return result
          } catch {
            // Skip this NOTAM and continue with others on any error
            Self.logger.warning(
              "Skipping NOTAM due to model error",
              metadata: ["notamId": "\(notam.notamId)", "error": "\(error)"]
            )
            return nil
          }
        }
      }

      var extractions: [NOTAMExtraction] = []
      for await extraction in group {
        if let extraction {
          extractions.append(extraction)
        }
      }
      return extractions
    }

    let totalDuration = Date().timeIntervalSince(startTime)
    Self.logger.info(
      "Completed concurrent parsing",
      metadata: [
        "count": "\(notams.count)",
        "extracted": "\(allExtractions.count)",
        "duration": "\(String(format: "%.2f", totalDuration))s"
      ]
    )

    guard !allExtractions.isEmpty else {
      throw Errors.intelligenceUnavailable
    }

    // Merge extractions from all NOTAMs
    let merged = mergeExtractions(allExtractions)

    // Convert to ParsedNOTAM format
    let confidence = calculateConfidence(from: merged)
    let parsedNOTAM = ParsedNOTAM(
      sourceNOTAMIds: merged.sourceNOTAMIds,
      contamination: mapContamination(
        type: merged.contaminationType,
        depthInches: merged.contaminationDepthInches
      ),
      takeoffDistanceShortening: merged.takeoffShorteningFeet.map {
        Measurement(value: $0, unit: .feet)
      },
      landingDistanceShortening: merged.landingShorteningFeet.map {
        Measurement(value: $0, unit: .feet)
      },
      obstacleHeight: merged.obstacleHeightFeet.map {
        Measurement(value: $0, unit: .feet)
      },
      obstacleDistance: merged.obstacleDistanceNM.map {
        Measurement(value: $0, unit: .nauticalMiles)
      },
      confidence: confidence,
      parsingNotes: merged.notes
    )

    return parsedNOTAM
  }

  /// Parses a single NOTAM using FoundationModels
  private func parseIndividualNOTAM(_ notam: NOTAMResponse, runway: String) async throws
    -> NOTAMExtraction
  {
    let session = LanguageModelSession()

    // Build prompt with NOTAM context
    let prompt = """
      Extract runway performance data from this NOTAM for runway \(runway).

      NOTAM \(notam.notamId):
      \(notam.notamText)

      NOTAM TYPES:
      - FICON (Field Condition, Q-line contains QMRXX): Reports runway surface contamination \
      (ice, snow, slush, water). Extract contaminationType and contaminationDepthInches. \
      Do NOT set takeoffShorteningFeet or landingShorteningFeet for FICON NOTAMs.
      - THR DSPLCD (Displaced Threshold): Runway is shortened. Extract the distance in feet \
      as takeoffShorteningFeet and/or landingShorteningFeet.
      - OBST (Obstacle): Physical obstacle near runway. Extract obstacleHeightFeet and \
      obstacleDistanceNM.

      CRITICAL: The Q-line (starts with Q)) contains coordinates like "6449N14751W005" which \
      are GPS positions (64°49'N, 147°51'W), NOT distances. Never interpret these as feet.

      If this NOTAM does not affect runway \(runway), return null for all fields.
      Always set sourceNOTAMIds to ["\(notam.notamId)"].
      """

    let response = try await session.respond(to: prompt, generating: NOTAMExtraction.self)

    // Ensure source NOTAM ID is always set
    let content = response.content
    let sourceIds = content.sourceNOTAMIds.isEmpty ? [notam.notamId] : content.sourceNOTAMIds

    return NOTAMExtraction(
      takeoffShorteningFeet: content.takeoffShorteningFeet,
      landingShorteningFeet: content.landingShorteningFeet,
      obstacleHeightFeet: content.obstacleHeightFeet,
      obstacleDistanceNM: content.obstacleDistanceNM,
      contaminationType: content.contaminationType,
      contaminationDepthInches: content.contaminationDepthInches,
      sourceNOTAMIds: sourceIds,
      notes: content.notes
    )
  }

  /// Merges multiple NOTAM extractions into a single result
  private func mergeExtractions(_ extractions: [NOTAMExtraction]) -> NOTAMExtraction {
    // Take the most restrictive/conservative values from all extractions
    let takeoffShortening = extractions.compactMap(\.takeoffShorteningFeet).max()
    let landingShortening = extractions.compactMap(\.landingShorteningFeet).max()
    let obstacleHeight = extractions.compactMap(\.obstacleHeightFeet).max()
    let obstacleDistance = extractions.compactMap(\.obstacleDistanceNM).min()  // Closest obstacle

    // Take first contamination found (could be improved to merge)
    let contamination = extractions.first(where: { $0.contaminationType != nil })
    let contaminationType = contamination?.contaminationType
    let contaminationDepth = contamination?.contaminationDepthInches

    // Only include source IDs from extractions that actually contributed data
    let sourceIds = extractions
      .filter { extraction in
        extraction.takeoffShorteningFeet != nil
          || extraction.landingShorteningFeet != nil
          || extraction.obstacleHeightFeet != nil
          || extraction.obstacleDistanceNM != nil
          || extraction.contaminationType != nil
      }
      .flatMap(\.sourceNOTAMIds)

    // Combine all notes
    let allNotes = extractions.compactMap(\.notes).filter { !$0.isEmpty }
    let combinedNotes = allNotes.isEmpty ? nil : allNotes.joined(separator: "; ")

    return NOTAMExtraction(
      takeoffShorteningFeet: takeoffShortening,
      landingShorteningFeet: landingShortening,
      obstacleHeightFeet: obstacleHeight,
      obstacleDistanceNM: obstacleDistance,
      contaminationType: contaminationType,
      contaminationDepthInches: contaminationDepth,
      sourceNOTAMIds: sourceIds,
      notes: combinedNotes
    )
  }

  /// Parses NOTAMs using keyword matching (fallback method).
  private func parseWithKeywords(notams: [NOTAMResponse], runway: String) async throws
    -> ParsedNOTAM?
  {
    // Combine all relevant NOTAMs for this runway
    let relevantNOTAMs = notams.filter { notam in
      let text = notam.notamText.uppercased()
      return text.contains(runway) || text.contains("RWY \(runway)") || text.contains("ALL RWY")
    }

    guard !relevantNOTAMs.isEmpty else { return nil }

    // Use first NOTAM's ID as primary source
    let notamId = relevantNOTAMs.first!.notamId
    let combinedText = relevantNOTAMs.map(\.notamText).joined(separator: " ").uppercased()

    Self.logger.info("Using keyword parsing for NOTAM", metadata: ["notamId": "\(notamId)"])

    var contamination: Contamination?
    var takeoffShortening: Measurement<UnitLength>?
    var landingShortening: Measurement<UnitLength>?
    var obstacleHeight: Measurement<UnitLength>?
    var obstacleDistance: Measurement<UnitLength>?
    var confidence = 0.0
    var notes: [String] = []

    // Detect contamination
    if combinedText.contains("ICE") || combinedText.contains("COMPACT SNOW")
      || combinedText.contains("COMPACTED SNOW")
    {
      contamination = .compactSnow
      confidence += 0.25
    } else if combinedText.contains("DRY SNOW") {
      contamination = .drySnow
      confidence += 0.25
    } else if combinedText.contains("SLUSH") || combinedText.contains("WET SNOW") {
      // Try to extract depth
      if let depth = extractDepth(from: combinedText) {
        contamination = .slushOrWetSnow(depth: depth)
        confidence += 0.3
      } else {
        contamination = .slushOrWetSnow(depth: .init(value: 0.01, unit: .meters))
        confidence += 0.15
        notes.append("Slush/wet snow detected but depth not specified")
      }
    } else if combinedText.contains("WATER") || combinedText.contains("STANDING WATER") {
      if let depth = extractDepth(from: combinedText) {
        contamination = .waterOrSlush(depth: depth)
        confidence += 0.3
      } else {
        contamination = .waterOrSlush(depth: .init(value: 0.01, unit: .meters))
        confidence += 0.15
        notes.append("Water detected but depth not specified")
      }
    }

    // Detect displaced threshold / distance shortening
    if combinedText.contains("THR") || combinedText.contains("THRESHOLD")
      || combinedText.contains("DSPLCD")
    {
      if let distance = extractDistance(from: combinedText) {
        if combinedText.contains("TKOF") || combinedText.contains("TAKEOFF") {
          takeoffShortening = distance
          confidence += 0.25
        } else if combinedText.contains("LDG") || combinedText.contains("LANDING") {
          landingShortening = distance
          confidence += 0.25
        } else {
          // Apply to both if not specified
          takeoffShortening = distance
          landingShortening = distance
          confidence += 0.2
          notes.append("Threshold displacement applied to both takeoff and landing")
        }
      } else {
        notes.append("Displaced threshold mentioned but distance not extracted")
      }
    }

    // Detect obstacles
    if combinedText.contains("OBST") || combinedText.contains("OBSTACLE")
      || combinedText.contains("TOWER") || combinedText.contains("CRANE")
    {
      if let height = extractHeight(from: combinedText) {
        obstacleHeight = height
        confidence += 0.15
      }
      if let distance = extractObstacleDistance(from: combinedText) {
        obstacleDistance = distance
        confidence += 0.15
      }
      if obstacleHeight == nil && obstacleDistance == nil {
        notes.append("Obstacle mentioned but dimensions not extracted")
      }
    }

    // Detect runway closures (these don't map to NOTAM model but should be noted)
    if combinedText.contains("CLSD") || combinedText.contains("CLOSED") {
      notes.append("Runway closure detected - manual review recommended")
      confidence = max(confidence, 0.3)  // At least some info was extracted
    }

    let parsed = ParsedNOTAM(
      sourceNOTAMIds: [notamId],
      contamination: contamination,
      takeoffDistanceShortening: takeoffShortening,
      landingDistanceShortening: landingShortening,
      obstacleHeight: obstacleHeight,
      obstacleDistance: obstacleDistance,
      confidence: confidence,
      parsingNotes: notes.isEmpty ? nil : notes.joined(separator: "; ")
    )

    if parsed.isEmpty {
      Self.logger.warning(
        "No relevant data extracted from NOTAM",
        metadata: ["notamId": "\(notamId)"]
      )
    } else {
      Self.logger.info(
        "Successfully parsed NOTAM",
        metadata: [
          "notamId": "\(notamId)",
          "confidence": "\(String(format: "%.2f", confidence))",
          "fields": "\(describeExtractedFields(parsed))"
        ]
      )
    }

    return parsed
  }

  // MARK: - AI Parsing Helper Methods

  /// Maps AI-extracted contamination data to the Contamination enum
  private func mapContamination(type: String?, depthInches: Double?) -> Contamination? {
    guard let type else { return nil }

    switch type {
    case "water":
      let depth = Measurement(
        value: depthInches.map { $0 * 0.0254 } ?? 0.01,  // inches to meters
        unit: UnitLength.meters
      )
      return .waterOrSlush(depth: depth)

    case "slush", "wetSnow":
      let depth = Measurement(
        value: depthInches.map { $0 * 0.0254 } ?? 0.01,
        unit: UnitLength.meters
      )
      return .slushOrWetSnow(depth: depth)

    case "drySnow":
      return .drySnow

    case "ice", "compactedSnow":
      return .compactSnow

    default:
      return nil
    }
  }

  /// Calculates confidence score based on extracted field completeness
  private func calculateConfidence(from extraction: NOTAMExtraction) -> Double {
    var confidence = 0.0
    var fieldCount = 0

    // Base confidence on number of fields extracted
    if extraction.takeoffShorteningFeet != nil {
      confidence += 0.2
      fieldCount += 1
    }
    if extraction.landingShorteningFeet != nil {
      confidence += 0.2
      fieldCount += 1
    }
    if extraction.obstacleHeightFeet != nil {
      confidence += 0.15
      fieldCount += 1
    }
    if extraction.obstacleDistanceNM != nil {
      confidence += 0.15
      fieldCount += 1
    }
    if extraction.contaminationType != nil {
      if extraction.contaminationDepthInches != nil {
        confidence += 0.3  // Complete contamination data
        fieldCount += 1
      } else {
        confidence += 0.15  // Contamination type without depth
        fieldCount += 1
      }
    }

    // Boost confidence if multiple fields extracted (more comprehensive)
    if fieldCount >= 2 {
      confidence += 0.1
    }

    // Cap at 1.0
    return min(confidence, 1.0)
  }

  // MARK: - Keyword Parsing Helper Methods

  private func extractDepth(from text: String) -> Measurement<UnitLength>? {
    // Look for patterns like "10MM", "1 INCH", "0.5IN"
    let patterns = [
      #"(\d+\.?\d*)\s*MM"#,  // millimeters
      #"(\d+\.?\d*)\s*CM"#,  // centimeters
      #"(\d+\.?\d*)\s*IN"#,  // inches
      #"(\d+\.?\d*)\s*INCH"#
    ]

    for (index, pattern) in patterns.enumerated() {
      if let regex = try? NSRegularExpression(pattern: pattern),
        let match = regex.firstMatch(
          in: text,
          range: NSRange(text.startIndex..., in: text)
        ),
        let range = Range(match.range(at: 1), in: text),
        let value = Double(text[range])
      {
        switch index {
          case 0: return .init(value: value / 1000, unit: .meters)  // mm to m
          case 1: return .init(value: value / 100, unit: .meters)  // cm to m
          case 2, 3: return .init(value: value * 0.0254, unit: .meters)  // inches to m
          default: break
        }
      }
    }
    return nil
  }

  private func extractDistance(from text: String) -> Measurement<UnitLength>? {
    // Look for patterns like "500FT", "1000 FEET", "150M"
    let patterns = [
      #"(\d+)\s*FT"#,
      #"(\d+)\s*FEET"#,
      #"(\d+)\s*M\b"#,  // meters (word boundary to avoid matching "MM")
      #"(\d+)\s*METERS"#
    ]

    for (index, pattern) in patterns.enumerated() {
      if let regex = try? NSRegularExpression(pattern: pattern),
        let match = regex.firstMatch(
          in: text,
          range: NSRange(text.startIndex..., in: text)
        ),
        let range = Range(match.range(at: 1), in: text),
        let value = Double(text[range])
      {
        switch index {
          case 0, 1: return .init(value: value, unit: .feet)
          case 2, 3: return .init(value: value, unit: .meters)
          default: break
        }
      }
    }
    return nil
  }

  private func extractHeight(from text: String) -> Measurement<UnitLength>? {
    // Similar to distance but might have different context words
    // Look for "HGT", "HEIGHT", etc.
    return extractDistance(from: text)
  }

  private func extractObstacleDistance(from text: String) -> Measurement<UnitLength>? {
    // Look for distance from threshold
    // This is more complex - might say "500M FROM THR" or similar
    return extractDistance(from: text)
  }

  private func describeExtractedFields(_ parsed: ParsedNOTAM) -> String {
    var fields: [String] = []
    if parsed.contamination != nil { fields.append("contamination") }
    if parsed.takeoffDistanceShortening != nil { fields.append("takeoffShortening") }
    if parsed.landingDistanceShortening != nil { fields.append("landingShortening") }
    if parsed.obstacleHeight != nil { fields.append("obstacleHeight") }
    if parsed.obstacleDistance != nil { fields.append("obstacleDistance") }
    return fields.joined(separator: ", ")
  }

  /// Errors that can occur during NOTAM parsing
  public enum Errors: Error {
    /// Failed to parse NOTAM text
    case parsingFailed(reason: String)

    /// Apple Intelligence unavailable on this device/OS version
    case intelligenceUnavailable
  }
}
