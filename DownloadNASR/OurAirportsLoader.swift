import Foundation
import Logging
import TabularData

struct OurAirportsLoader {
  private let logger: Logger

  private let airportsURL = URL(
    string: "https://davidmegginson.github.io/ourairports-data/airports.csv"
  )!
  private let runwaysURL = URL(
    string: "https://davidmegginson.github.io/ourairports-data/runways.csv"
  )!

  init(logger: Logger) {
    self.logger = logger
  }

  func loadAirports() async throws -> ([OurAirportData], Date) {
    logger.notice("Downloading OurAirports data…")

    // Download CSV files
    let (airportsData, _) = try await URLSession.shared.data(from: airportsURL)
    let (runwaysData, _) = try await URLSession.shared.data(from: runwaysURL)

    logger.notice("Parsing OurAirports CSVs…")

    // Parse airports CSV
    let airportsDataFrame = try DataFrame(
      csvData: airportsData,
      options: CSVReadingOptions(hasHeaderRow: true)
    )

    // Parse runways CSV
    let runwaysDataFrame = try DataFrame(
      csvData: runwaysData,
      options: CSVReadingOptions(hasHeaderRow: true)
    )

    // Convert to our data structures
    var airports = [OurAirportData]()
    let runwaysByAirport = groupRunwaysByAirport(runwaysDataFrame)

    for row in airportsDataFrame.rows {
      guard let id = row["id", Int.self],
        let ident = row["ident", String.self],
        let type = row["type", String.self],
        // Only include airports (not heliports, seaplane bases, etc.)
        ["small_airport", "medium_airport", "large_airport"].contains(type),
        let name = row["name", String.self],
        let latitude = row["latitude_deg", Double.self],
        let longitude = row["longitude_deg", Double.self]
      else {
        continue
      }

      let localId = row["local_code", String.self] ?? ""
      let locationId = localId.isEmpty ? ident : localId
      let icaoId = row["icao_code", String.self]
      let elevation = Double(row["elevation_ft", Int.self] ?? 0)
      let municipality = row["municipality", String.self]

      let runways = runwaysByAirport[ident] ?? []
      let airport = OurAirportData(
        id: String(id),
        localId: locationId,
        icaoId: icaoId,
        name: name,
        municipality: municipality,
        latitude: latitude,
        longitude: longitude,
        elevationFt: elevation,
        runways: runways
      )
      airports.append(airport)
    }

    // Use current date as last updated
    let lastUpdated = Date()

    logger.notice("Loaded \(airports.count) airports from OurAirports")
    return (airports, lastUpdated)
  }

  private func groupRunwaysByAirport(_ runwaysDataFrame: DataFrame) -> [String: [OurRunwayData]] {
    var runwaysByAirport = [String: [OurRunwayData]]()

    for row in runwaysDataFrame.rows {
      guard let airportIdent = row["airport_ident", String.self],
        let length = row["length_ft", Int.self],
        length >= 500
      else {
        continue
      }

      let surface = row["surface", String.self] ?? ""
      let isTurf = !isHardSurface(surface)

      // Skip water runways
      if surface.lowercased().contains("water") {
        continue
      }

      // Process low end (base end)
      if let lowIdent = row["le_ident", String.self] {
        let lowElevation = row["le_elevation_ft", Int.self].map { Double($0) }
        let lowHeading = row["le_heading_degT", Double.self] ?? calculateHeadingFromIdent(lowIdent)
        let lowDisplaced = Double(row["le_displaced_threshold_ft", Int.self] ?? 0)

        let runway = OurRunwayData(
          name: lowIdent,
          elevationFt: lowElevation,
          trueHeading: lowHeading,
          lengthFt: Double(length),
          displacedThresholdFt: lowDisplaced,
          isTurf: isTurf,
          reciprocalName: row["he_ident", String.self]
        )

        if runwaysByAirport[airportIdent] == nil {
          runwaysByAirport[airportIdent] = []
        }
        runwaysByAirport[airportIdent]?.append(runway)
      }

      // Process high end (reciprocal end)
      if let highIdent = row["he_ident", String.self] {
        let highElevation = row["he_elevation_ft", Int.self].map { Double($0) }
        let highHeading =
          row["he_heading_degT", Double.self] ?? calculateHeadingFromIdent(highIdent)
        let highDisplaced = Double(row["he_displaced_threshold_ft", Int.self] ?? 0)

        let runway = OurRunwayData(
          name: highIdent,
          elevationFt: highElevation,
          trueHeading: highHeading,
          lengthFt: Double(length),
          displacedThresholdFt: highDisplaced,
          isTurf: isTurf,
          reciprocalName: row["le_ident", String.self]
        )

        if runwaysByAirport[airportIdent] == nil {
          runwaysByAirport[airportIdent] = []
        }
        runwaysByAirport[airportIdent]?.append(runway)
      }
    }

    return runwaysByAirport
  }

  private func isHardSurface(_ surface: String) -> Bool {
    // Check for hard surface indicators - be inclusive to catch variations
    let hardSurfaceIndicators = ["asp", "conc", "pem", "bit", "tarmac", "paved", "macadam"]
    let lowercased = surface.lowercased()

    // Return true if any hard surface indicator is found
    for indicator in hardSurfaceIndicators where lowercased.contains(indicator) {
      return true
    }

    // CON by itself (not part of "concrete") is also hard surface
    if surface == "CON" {
      return true
    }

    return false
  }

  private func calculateHeadingFromIdent(_ ident: String) -> Double {
    // Extract numeric part from runway identifier (e.g., "09L" -> 09)
    let digits = ident.prefix(2).filter(\.isNumber)
    guard let runwayNumber = Double(digits) else { return 0 }
    return runwayNumber * 10  // Convert to degrees (09 -> 090)
  }
}

struct OurAirportData {
  let id: String  // The unique id from OurAirports database (used as recordID)
  let localId: String  // This maps to FAA location ID (local_code)
  let icaoId: String?  // The ICAO code (icao_code)
  let name: String
  let municipality: String?
  let latitude: Double  // decimal degrees
  let longitude: Double  // decimal degrees
  let elevationFt: Double
  let runways: [OurRunwayData]
}

struct OurRunwayData {
  let name: String
  let elevationFt: Double?
  let trueHeading: Double  // degrees
  let lengthFt: Double
  let displacedThresholdFt: Double
  let isTurf: Bool
  let reciprocalName: String?
}
