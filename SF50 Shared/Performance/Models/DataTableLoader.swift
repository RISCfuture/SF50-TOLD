import Foundation

struct DataTableLoader {

  private let bundle: Bundle
  private let modelType: ModelType

  private var dataURL: URL {
    let directory = modelType == .g1 ? "Data/g1" : "Data/g2+"
    return bundle.resourceURL!.appending(component: directory, directoryHint: .isDirectory)
  }

  private var g1DataURL: URL {
    bundle.resourceURL!.appending(component: "Data/g1", directoryHint: .isDirectory)
  }

  init(bundle: Bundle = Bundle(for: BasePerformanceModel.self), modelType: ModelType) {
    self.bundle = bundle
    self.modelType = modelType
  }

  // MARK: - Main Performance Data Tables

  func loadTakeoffRunData() throws -> DataTable {
    try loadDataTable(path: "takeoff/ground run.csv")
  }

  func loadTakeoffDistanceData() throws -> DataTable {
    try loadDataTable(path: "takeoff/total distance.csv")
  }

  func loadLandingRunData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(path: "landing/\(landingPrefix)/ground run.csv", fromG1: fromG1)
  }

  func loadLandingDistanceData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(path: "landing/\(landingPrefix)/total distance.csv", fromG1: fromG1)
  }

  func loadVrefData() throws -> DataTable {
    try loadDataTable(path: "vref/50.csv", fromG1: true)
  }

  func loadVrefData(vrefPrefix: String) throws -> DataTable {
    try loadDataTable(path: "vref/\(vrefPrefix).csv", fromG1: true)
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
    return try loadDataTable(path: "enroute climb/\(subdir)/gradient.csv", fromG1: true)
  }

  func loadEnrouteClimbRateData(iceContaminated: Bool) throws -> DataTable {
    let subdir = iceContaminated ? "ice contaminated" : "normal"
    return try loadDataTable(path: "enroute climb/\(subdir)/rate.csv", fromG1: true)
  }

  func loadEnrouteClimbSpeedData(iceContaminated: Bool) throws -> DataTable {
    let subdir = iceContaminated ? "ice contaminated" : "normal"
    return try loadDataTable(path: "enroute climb/\(subdir)/speed.csv", fromG1: true)
  }

  // MARK: - Time Fuel Distance to Climb Data Tables

  func loadTimeFuelDistanceTimeData() throws -> DataTable {
    try loadDataTable(path: "time fuel distance to climb/time.csv", fromG1: true)
  }

  func loadTimeFuelDistanceFuelData() throws -> DataTable {
    try loadDataTable(path: "time fuel distance to climb/fuel.csv", fromG1: true)
  }

  func loadTimeFuelDistanceDistanceData() throws -> DataTable {
    try loadDataTable(path: "time fuel distance to climb/distance.csv", fromG1: true)
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
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(
      path: "landing/\(landingPrefix)/ground run - headwind factor.csv",
      fromG1: fromG1
    )
  }

  func loadLandingRunTailwindData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(
      path: "landing/\(landingPrefix)/ground run - tailwind factor.csv",
      fromG1: fromG1
    )
  }

  func loadLandingRunDownhillData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(
      path: "landing/\(landingPrefix)/ground run - downhill factor.csv",
      fromG1: fromG1
    )
  }

  func loadLandingRunUphillData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(
      path: "landing/\(landingPrefix)/ground run - uphill factor.csv",
      fromG1: fromG1
    )
  }

  func loadLandingDistanceHeadwindData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(
      path: "landing/\(landingPrefix)/total distance - headwind factor.csv",
      fromG1: fromG1
    )
  }

  func loadLandingDistanceTailwindData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(
      path: "landing/\(landingPrefix)/total distance - tailwind factor.csv",
      fromG1: fromG1
    )
  }

  func loadLandingDistanceUnpavedData(landingPrefix: String) throws -> DataTable {
    let fromG1 = landingPrefix == "50 ice"
    return try loadDataTable(
      path: "landing/\(landingPrefix)/total distance - unpaved factor.csv",
      fromG1: fromG1
    )
  }

  // MARK: - Contamination Data Tables

  func loadCompactSnowLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/compact snow.csv", fromG1: true)
  }

  func loadDrySnowLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/dry snow.csv", fromG1: true)
  }

  func loadSlushLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/slush, wet snow.csv", fromG1: true)
  }

  func loadWaterLandingData() throws -> DataTable {
    try loadDataTable(path: "landing/contamination/water.csv", fromG1: true)
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

  private func loadDataTable(path: String, fromG1: Bool = false) throws -> DataTable {
    let url = fromG1 ? g1DataURL.appending(path: path) : dataURL.appending(path: path)
    return try DataTable(fileURL: url)
  }

  enum ModelType {
    case g1
    case g2Plus
  }
}
