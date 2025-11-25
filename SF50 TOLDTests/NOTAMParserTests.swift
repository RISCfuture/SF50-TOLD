import Foundation
import Testing
@testable import SF50_Shared
@testable import SF50_TOLD

/// Tests for NOTAMParser using real NOTAM examples
@Suite("NOTAM Parser Tests")
struct NOTAMParserTests {

  // MARK: - Real NOTAM Examples

  /// Test parsing NOTAM with runway closure
  @Test("Parse runway closure NOTAM")
  func testRunwayClosureNOTAM() async throws {
    let notam = NOTAMResponse(
      id: 1,
      notamId: "TEST001",
      icaoLocation: "KORD",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 02L/20R CLSD DUE TO WIP",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "02L")

    // Should return a result with runway closure note
    #expect(result != nil)
    if let parsed = result {
      #expect(parsed.parsingNotes?.contains("closure") == true || parsed.parsingNotes?.contains("CLSD") == true)
    }
  }

  /// Test parsing NOTAM with obstacle information
  @Test("Parse obstacle NOTAM")
  func testObstacleNOTAM() async throws {
    let notam = NOTAMResponse(
      id: 2,
      notamId: "TEST002",
      icaoLocation: "TJSJ",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "OBST CRANE ERECTED PSN 183431.6N0695855.3W ELEV 161FT HTG 80FT",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "10")

    // Should extract obstacle height
    #expect(result != nil)
    if let parsed = result {
      #expect(parsed.obstacleHeight != nil)
      if let height = parsed.obstacleHeight {
        // Should be around 80 feet
        #expect(height.converted(to: UnitLength.feet).value > 50)
        #expect(height.converted(to: UnitLength.feet).value < 150)
      }
    }
  }

  /// Test parsing NOTAM with displaced threshold
  @Test("Parse displaced threshold NOTAM")
  func testDisplacedThresholdNOTAM() async throws {
    let notam = NOTAMResponse(
      id: 3,
      notamId: "TEST003",
      icaoLocation: "KJFK",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 04R THR DSPLCD 500 FT DUE WIP",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "04R")

    // Should extract distance shortening
    #expect(result != nil)
    if let parsed = result {
      #expect(parsed.takeoffDistanceShortening != nil || parsed.landingDistanceShortening != nil)

      // Check if the value is close to 500 ft
      if let shortening = parsed.takeoffDistanceShortening ?? parsed.landingDistanceShortening {
        let feet = shortening.converted(to: UnitLength.feet).value
        #expect(feet >= 400 && feet <= 600)
      }
    }
  }

  /// Test parsing NOTAM with contamination
  @Test("Parse contamination NOTAM")
  func testContaminationNOTAM() async throws {
    let notam = NOTAMResponse(
      id: 4,
      notamId: "TEST004",
      icaoLocation: "KBOS",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 04R/22L CONTAMINATED WITH 3MM WET SNOW",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "04R")

    // Should extract contamination
    #expect(result != nil)
    if let parsed = result {
      #expect(parsed.contamination != nil)

      // Should be wet snow with depth
      switch parsed.contamination {
      case .slushOrWetSnow(let depth):
        // 3mm = 0.003 meters
        #expect(depth.converted(to: UnitLength.meters).value > 0.002)
        #expect(depth.converted(to: UnitLength.meters).value < 0.005)
      default:
        Issue.record("Expected slushOrWetSnow contamination")
      }
    }
  }

  /// Test parsing NOTAM with ice contamination
  @Test("Parse ice contamination NOTAM")
  func testIceContaminationNOTAM() async throws {
    let notam = NOTAMResponse(
      id: 5,
      notamId: "TEST005",
      icaoLocation: "KORD",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 10/28 CONTAMINATED WITH ICE",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "10")

    // Should extract contamination
    #expect(result != nil)
    if let parsed = result {
      #expect(parsed.contamination != nil)

      // Should be compact snow (ice/compacted snow)
      switch parsed.contamination {
      case .compactSnow:
        break  // Expected
      default:
        Issue.record("Expected compactSnow contamination for ice")
      }
    }
  }

  /// Test parsing NOTAM with standing water
  @Test("Parse standing water NOTAM")
  func testStandingWaterNOTAM() async throws {
    let notam = NOTAMResponse(
      id: 6,
      notamId: "TEST006",
      icaoLocation: "KMIA",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 09/27 STANDING WATER 5MM DEPTH",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "09")

    // Should extract contamination
    #expect(result != nil)
    if let parsed = result {
      #expect(parsed.contamination != nil)

      // Should be water or slush with depth
      switch parsed.contamination {
      case .waterOrSlush(let depth):
        // 5mm = 0.005 meters
        #expect(depth.converted(to: UnitLength.meters).value > 0.004)
        #expect(depth.converted(to: UnitLength.meters).value < 0.007)
      default:
        Issue.record("Expected waterOrSlush contamination")
      }
    }
  }

  /// Test parsing multiple NOTAMs for same runway
  @Test("Parse multiple NOTAMs and merge")
  func testMultipleNOTAMs() async throws {
    let notam1 = NOTAMResponse(
      id: 7,
      notamId: "TEST007A",
      icaoLocation: "KSFO",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 28L THR DSPLCD 300 FT",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let notam2 = NOTAMResponse(
      id: 8,
      notamId: "TEST007B",
      icaoLocation: "KSFO",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 28L OBST CRANE 45 FT 800 FT FROM THR",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam1, notam2], for: "28L")

    // Should merge both NOTAMs
    #expect(result != nil)
    if let parsed = result {
      // Should have both distance shortening and obstacle
      #expect(parsed.takeoffDistanceShortening != nil || parsed.landingDistanceShortening != nil)
      #expect(parsed.obstacleHeight != nil)
    }
  }

  /// Test parsing irrelevant NOTAM
  @Test("Parse irrelevant NOTAM returns nil")
  func testIrrelevantNOTAM() async throws {
    let notam = NOTAMResponse(
      id: 9,
      notamId: "TEST008",
      icaoLocation: "KJFK",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "TAXIWAY B CLSD",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "04R")

    // Should return nil or empty result for taxiway closure
    if let parsed = result {
      #expect(parsed.isEmpty)
    }
  }

  /// Test parsing empty NOTAM array
  @Test("Parse empty NOTAM array returns nil")
  func testEmptyNOTAMArray() async throws {
    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [], for: "10")

    #expect(result == nil)
  }

  /// Test confidence scoring
  @Test("Verify confidence scores")
  func testConfidenceScoring() async throws {
    let notam = NOTAMResponse(
      id: 10,
      notamId: "TEST009",
      icaoLocation: "KDEN",
      effectiveStart: Date(),
      effectiveEnd: Date().addingTimeInterval(86400),
      schedule: nil,
      notamText: "RWY 16R/34L THR DSPLCD 600 FT, CONTAMINATED WITH 8MM DRY SNOW, OBST TOWER 50 FT 1200 FT FROM THR",
      qLine: nil,
      purpose: "N",
      scope: "A",
      trafficType: "IV",
      createdAt: Date(),
      updatedAt: Date(),
      rawMessage: nil
    )

    let parser = NOTAMParser.shared
    let result = try await parser.parse(notams: [notam], for: "16R")

    // Should have high confidence with multiple fields extracted
    #expect(result != nil)
    if let parsed = result {
      // Confidence should be relatively high (> 0.3) with multiple restrictions
      #expect(parsed.confidence > 0.3)

      // Should have extracted multiple fields
      var fieldCount = 0
      if parsed.takeoffDistanceShortening != nil { fieldCount += 1 }
      if parsed.landingDistanceShortening != nil { fieldCount += 1 }
      if parsed.contamination != nil { fieldCount += 1 }
      if parsed.obstacleHeight != nil { fieldCount += 1 }

      #expect(fieldCount >= 2)
    }
  }
}
