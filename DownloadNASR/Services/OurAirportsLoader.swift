import Foundation
import Logging
import TabularData

/// Downloads and parses airport data from the OurAirports database.
///
/// ``OurAirportsLoader`` fetches CSV data from OurAirports (a community-maintained
/// database) to supplement FAA NASR data with international airports.
///
/// ## Data Source
///
/// CSV files are hosted at `davidmegginson.github.io/ourairports-data/`:
/// - `airports.csv`: Airport records
/// - `runways.csv`: Runway records
///
/// ## Processing
///
/// The loader:
/// 1. Downloads both CSV files
/// 2. Parses using TabularData framework
/// 3. Filters to small/medium/large airports (excludes heliports, seaplane bases)
/// 4. Filters runways ≥500 feet (excludes water runways)
/// 5. Returns ``OurAirportData`` structs
///
/// ## See Also
///
/// - ``OurAirportData``
/// - ``OurRunwayData``
struct OurAirportsLoader {
  private let logger: Logger
  private let progress: Progress

  private let airportsURL = URL(
    string: "https://davidmegginson.github.io/ourairports-data/airports.csv"
  )!
  private let runwaysURL = URL(
    string: "https://davidmegginson.github.io/ourairports-data/runways.csv"
  )!

  init(logger: Logger, progress: Progress) {
    self.logger = logger
    self.progress = progress
  }

  func loadAirports() async throws -> ([OurAirportData], Date) {
    progress.totalUnitCount = 2

    logger.notice("Downloading OurAirports data…")
    progress.localizedDescription = "Downloading OurAirports data…"

    // Download CSV files
    let (airportsData, _) = try await URLSession.shared.data(from: airportsURL)
    let (runwaysData, _) = try await URLSession.shared.data(from: runwaysURL)
    progress.completedUnitCount = 1

    logger.notice("Parsing OurAirports CSVs…")
    progress.localizedDescription = "Parsing OurAirports CSVs…"

    // Parse and process data on background thread to avoid blocking UI
    let airports = try await Task.detached {
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
      let runwaysByAirport = await groupRunwaysByAirport(runwaysDataFrame)

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
        let ICAO_ID = row["icao_code", String.self]
        let elevation = Double(row["elevation_ft", Int.self] ?? 0)
        let municipality = row["municipality", String.self]

        let runways = runwaysByAirport[ident] ?? []
        let airport = OurAirportData(
          id: String(id),
          localId: locationId,
          ICAO_ID: ICAO_ID,
          name: name,
          municipality: municipality,
          latitude: latitude,
          longitude: longitude,
          elevationFt: elevation,
          runways: runways
        )
        airports.append(airport)
      }

      return airports
    }.value

    // Use current date as last updated
    let lastUpdated = Date()
    progress.completedUnitCount = 2

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
    if surface == "CON" { return true }

    return false
  }

  private func calculateHeadingFromIdent(_ ident: String) -> Double {
    // Extract numeric part from runway identifier (e.g., "09L" -> 09)
    let digits = ident.prefix(2).filter(\.isNumber)
    guard let runwayNumber = Double(digits) else { return 0 }
    return runwayNumber * 10  // Convert to degrees (09 -> 090)
  }
}

/// Airport data parsed from OurAirports CSV.
///
/// Contains airport metadata needed for the app's airport database.
/// Values are in OurAirports native units (feet, degrees).
struct OurAirportData {
  /// Unique ID from OurAirports database (used as recordID).
  let id: String

  /// FAA location ID (local_code field).
  let localId: String

  /// ICAO identifier if available.
  let ICAO_ID: String?

  /// Airport name.
  let name: String

  /// City/municipality name.
  let municipality: String?

  /// Latitude in decimal degrees.
  let latitude: Double

  /// Longitude in decimal degrees.
  let longitude: Double

  /// Field elevation in feet.
  let elevationFt: Double

  /// Runways at this airport.
  let runways: [OurRunwayData]
}

/// Runway data parsed from OurAirports CSV.
///
/// Contains runway properties needed for performance calculations.
/// Values are in OurAirports native units (feet, degrees).
struct OurRunwayData {
  /// Runway designator (e.g., "09L").
  let name: String

  /// Threshold elevation in feet.
  let elevationFt: Double?

  /// True heading in degrees.
  let trueHeading: Double

  /// Runway length in feet.
  let lengthFt: Double

  /// Displaced threshold distance in feet.
  let displacedThresholdFt: Double

  /// Whether the runway has a turf (non-paved) surface.
  let isTurf: Bool

  /// Name of the reciprocal runway end.
  let reciprocalName: String?
}
