import Foundation

/// Loads performance data tables from bundled CSV files.
///
/// ``DataTableLoader`` provides methods to load digitized AFM chart data for
/// performance calculations. Each data table is stored as a CSV file in the
/// app bundle, organized by model type (G1 or G2+) and performance category.
///
/// ## Data Organization
///
/// Performance data is organized in the bundle as:
///
/// ```
/// Data/
/// ├── g1/
/// │   ├── takeoff/
/// │   │   ├── ground run.csv
/// │   │   ├── total distance.csv
/// │   │   └── ... adjustment factors
/// │   ├── landing/
/// │   │   ├── 100/ (flaps 100)
/// │   │   ├── 50/ (flaps 50)
/// │   │   └── contamination/
/// │   └── enroute climb/
/// └── g2+/
///     └── ... (similar structure)
/// ```
///
struct DataTableLoader {

  private let bundle: Bundle
  let aircraftType: AircraftType

  private var dataURL: URL {
    let directory = "Data/\(aircraftType.dataDirectoryName)"
    return bundle.resourceURL!.appending(component: directory, directoryHint: .isDirectory)
  }

  /// Fallback URL for G2+ aircraft to use G2 data when G2+ data is not available.
  private var fallbackDataURL: URL? {
    switch aircraftType {
      case .g2Plus, .g2(true):
        return bundle.resourceURL!.appending(component: "Data/g2", directoryHint: .isDirectory)
      default:
        return nil
    }
  }

  init(bundle: Bundle = Bundle(for: BasePerformanceModel.self), aircraftType: AircraftType) {
    self.bundle = bundle
    self.aircraftType = aircraftType
  }

  // MARK: - Main Performance Data Tables

  func loadTakeoffRunData() throws -> DataTable {
    try loadDataTable(path: "takeoff/ground run.csv")
  }

  func loadTakeoffDistanceData() throws -> DataTable {
    try loadDataTable(path: "takeoff/total distance.csv")
  }

  func loadLandingRunData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/ground run.csv")
  }

  func loadLandingDistanceData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/total distance.csv")
  }

  func loadVrefData() throws -> DataTable {
    try loadDataTable(path: "vref/50.csv")
  }

  func loadVrefData(vrefPrefix: String) throws -> DataTable {
    try loadDataTable(path: "vref/\(vrefPrefix).csv")
  }

  func loadTakeoffClimbGradientData() throws -> DataTable {
    try loadDataTable(path: "takeoff climb/gradient.csv")
  }

  func loadTakeoffClimbRateData() throws -> DataTable {
    try loadDataTable(path: "takeoff climb/rate.csv")
  }

  func loadGoAroundClimbGradientData() throws -> DataTable {
    try loadDataTable(path: "landing/go around gradient.csv")
  }

  // MARK: - Enroute Climb Data Tables

  func loadEnrouteClimbGradientData(iceContaminated: Bool) throws -> DataTable {
    let subdir = iceContaminated ? "ice contaminated" : "normal"
    return try loadDataTable(path: "enroute climb/\(subdir)/gradient.csv")
  }

  func loadEnrouteClimbRateData(iceContaminated: Bool) throws -> DataTable {
    let subdir = iceContaminated ? "ice contaminated" : "normal"
    return try loadDataTable(path: "enroute climb/\(subdir)/rate.csv")
  }

  func loadEnrouteClimbSpeedData(iceContaminated: Bool) throws -> DataTable {
    let subdir = iceContaminated ? "ice contaminated" : "normal"
    return try loadDataTable(path: "enroute climb/\(subdir)/speed.csv")
  }

  // MARK: - Adjustment Factor Data Tables

  func loadTakeoffRunHeadwindData() throws -> DataTable {
    try loadDataTable(path: "takeoff/ground run - headwind factor.csv")
  }

  func loadTakeoffRunTailwindData() throws -> DataTable {
    try loadDataTable(path: "takeoff/ground run - tailwind factor.csv")
  }

  func loadTakeoffRunDownhillData() throws -> DataTable {
    try loadDataTable(path: "takeoff/ground run - downhill factor.csv")
  }

  func loadTakeoffRunUphillData() throws -> DataTable {
    try loadDataTable(path: "takeoff/ground run - uphill factor.csv")
  }

  func loadTakeoffDistanceHeadwindData() throws -> DataTable {
    try loadDataTable(path: "takeoff/total distance - headwind factor.csv")
  }

  func loadTakeoffDistanceTailwindData() throws -> DataTable {
    try loadDataTable(path: "takeoff/total distance - tailwind factor.csv")
  }

  func loadTakeoffDistanceUnpavedData() throws -> DataTable {
    try loadDataTable(path: "takeoff/total distance - unpaved factor.csv")
  }

  func loadLandingRunHeadwindData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/ground run - headwind factor.csv")
  }

  func loadLandingRunTailwindData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/ground run - tailwind factor.csv")
  }

  func loadLandingRunDownhillData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/ground run - downhill factor.csv")
  }

  func loadLandingRunUphillData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/ground run - uphill factor.csv")
  }

  func loadLandingDistanceHeadwindData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/total distance - headwind factor.csv")
  }

  func loadLandingDistanceTailwindData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/total distance - tailwind factor.csv")
  }

  func loadLandingDistanceUnpavedData(landingPrefix: String) throws -> DataTable {
    try loadDataTable(path: "landing/\(landingPrefix)/total distance - unpaved factor.csv")
  }

  // MARK: - Contamination Data Tables

  func loadCompactSnowLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/compact snow.csv")
  }

  func loadDrySnowLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/dry snow.csv")
  }

  func loadSlushLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/slush, wet snow.csv")
  }

  func loadWaterLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/water.csv")
  }

  // Alias methods for contamination data (used by TabularPerformanceModelG2+)
  func loadContaminationCompactSnowData() throws -> DataTable {
    try loadCompactSnowLandingData()
  }

  func loadContaminationDrySnowData() throws -> DataTable {
    try loadDrySnowLandingData()
  }

  func loadContaminationSlushData() throws -> DataTable {
    try loadSlushLandingData()
  }

  func loadContaminationWaterData() throws -> DataTable {
    try loadWaterLandingData()
  }

  // MARK: - Helper Functions

  private func loadDataTable(path: String) throws -> DataTable {
    let url = dataURL.appending(path: path)

    // Try primary location first
    if FileManager.default.fileExists(atPath: url.path) {
      return try DataTable(fileURL: url)
    }

    // Fall back to G2 data for G2+ aircraft if primary doesn't exist
    if let fallbackURL = fallbackDataURL {
      let fallback = fallbackURL.appending(path: path)
      return try DataTable(fileURL: fallback)
    }

    // No fallback available, throw original error
    return try DataTable(fileURL: url)
  }
}

extension AircraftType {
  /// The directory name used for loading performance data tables.
  ///
  /// - G1: uses g1 data
  /// - G2 without updated thrust: uses g2 data
  /// - G2 with updated thrust: uses g2+ data
  /// - G2+: uses g2+ data
  var dataDirectoryName: String {
    switch self {
      case .g1: "g1"
      case .g2(let updated): updated ? "g2+" : "g2"
      case .g2Plus: "g2+"
    }
  }
}
