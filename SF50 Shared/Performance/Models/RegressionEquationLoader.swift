import Foundation

/// Loads regression equations from bundled JSON files.
///
/// ``RegressionEquationLoader`` provides methods to load regression equation
/// definitions for performance calculations. Each equation is stored as a
/// JSON file in the app bundle, organized by model type and category.
///
/// ## Data Organization
///
/// Equation files are organized in the bundle as:
///
/// ```
/// Data/
/// ├── g1/
/// │   └── regressions/
/// │       ├── takeoff-ground-run.json
/// │       ├── takeoff-total-distance.json
/// │       ├── vref-flaps50.json
/// │       └── ...
/// ├── g2/
/// │   └── regressions/
/// │       └── ...
/// └── g2+/
///     └── regressions/
///         └── ...
/// ```
///
/// ## Shared Data
///
/// Some equations are shared between G1 and G2+ models:
/// - Vref speeds (all generations use G1 data)
/// - Ice-contaminated landing data
/// - Enroute climb data
struct RegressionEquationLoader {

  private let bundle: Bundle
  let aircraftType: AircraftType

  private var dataURL: URL {
    let directory = "Data/\(aircraftType.dataDirectoryName)/regressions"
    return bundle.resourceURL!.appending(component: directory, directoryHint: .isDirectory)
  }

  private var g1DataURL: URL {
    bundle.resourceURL!.appending(component: "Data/g1/regressions", directoryHint: .isDirectory)
  }

  init(bundle: Bundle = Bundle(for: BasePerformanceModel.self), aircraftType: AircraftType) {
    self.bundle = bundle
    self.aircraftType = aircraftType
  }

  // MARK: - Takeoff Equations

  func loadTakeoffRunEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-ground-run.json")
  }

  func loadTakeoffDistanceEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-total-distance.json")
  }

  func loadTakeoffClimbGradientEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-climb-gradient.json")
  }

  func loadTakeoffClimbRateEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-climb-rate.json")
  }

  // MARK: - Takeoff Adjustment Factor Equations

  func loadTakeoffRunHeadwindFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-run-headwind-factor.json")
  }

  func loadTakeoffRunTailwindFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-run-tailwind-factor.json")
  }

  func loadTakeoffRunUphillFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-run-uphill-factor.json")
  }

  func loadTakeoffRunDownhillFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-run-downhill-factor.json")
  }

  func loadTakeoffDistanceHeadwindFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-distance-headwind-factor.json")
  }

  func loadTakeoffDistanceTailwindFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-distance-tailwind-factor.json")
  }

  func loadTakeoffDistanceUnpavedFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "takeoff-distance-unpaved-factor.json")
  }

  // MARK: - Landing Equations

  func loadLandingRunEquation(flapSetting: FlapSetting) throws -> RegressionEquation {
    let filename = "landing-run-\(flapSetting.regressionFileSuffix).json"
    let fromG1 = flapSetting.isIceContaminated
    return try loadEquation(filename: filename, fromG1: fromG1)
  }

  func loadLandingDistanceEquation(flapSetting: FlapSetting) throws -> RegressionEquation {
    let filename = "landing-distance-\(flapSetting.regressionFileSuffix).json"
    let fromG1 = flapSetting.isIceContaminated
    return try loadEquation(filename: filename, fromG1: fromG1)
  }

  func loadGoAroundClimbGradientEquation() throws -> RegressionEquation {
    try loadEquation(filename: "go-around-climb-gradient.json")
  }

  // MARK: - Landing Adjustment Factor Equations

  func loadLandingRunHeadwindFactorEquation(flapSetting: FlapSetting) throws -> RegressionEquation {
    let filename = "landing-run-headwind-factor-\(flapSetting.regressionFileSuffix).json"
    return try loadEquation(filename: filename)
  }

  func loadLandingRunTailwindFactorEquation(flapSetting: FlapSetting) throws -> RegressionEquation {
    let filename = "landing-run-tailwind-factor-\(flapSetting.regressionFileSuffix).json"
    return try loadEquation(filename: filename)
  }

  func loadLandingRunUphillFactorEquation(flapSetting: FlapSetting) throws -> RegressionEquation {
    let filename = "landing-run-uphill-factor-\(flapSetting.regressionFileSuffix).json"
    return try loadEquation(filename: filename)
  }

  func loadLandingRunDownhillFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "landing-run-downhill-factor.json")
  }

  func loadLandingDistanceHeadwindFactorEquation(
    flapSetting: FlapSetting
  ) throws -> RegressionEquation {
    let filename = "landing-distance-headwind-factor-\(flapSetting.regressionFileSuffix).json"
    return try loadEquation(filename: filename)
  }

  func loadLandingDistanceTailwindFactorEquation(
    flapSetting: FlapSetting
  ) throws -> RegressionEquation {
    let filename = "landing-distance-tailwind-factor-\(flapSetting.regressionFileSuffix).json"
    return try loadEquation(filename: filename)
  }

  func loadLandingDistanceUnpavedFactorEquation() throws -> RegressionEquation {
    try loadEquation(filename: "landing-distance-unpaved-factor.json")
  }

  // MARK: - Vref Equations

  func loadVrefEquation(flapSetting: FlapSetting) throws -> RegressionEquation {
    let filename = "vref-\(flapSetting.regressionFileSuffix).json"
    // Vref always uses G1 data
    return try loadEquation(filename: filename, fromG1: true)
  }

  // MARK: - En Route Climb Equations

  func loadEnrouteClimbGradientEquation(iceContaminated: Bool) throws -> RegressionEquation {
    let suffix = iceContaminated ? "ice" : "normal"
    return try loadEquation(filename: "enroute-climb-gradient-\(suffix).json", fromG1: true)
  }

  func loadEnrouteClimbRateEquation(iceContaminated: Bool) throws -> RegressionEquation {
    let suffix = iceContaminated ? "ice" : "normal"
    return try loadEquation(filename: "enroute-climb-rate-\(suffix).json", fromG1: true)
  }

  func loadEnrouteClimbSpeedEquation(iceContaminated: Bool) throws -> RegressionEquation {
    let suffix = iceContaminated ? "ice" : "normal"
    return try loadEquation(filename: "enroute-climb-speed-\(suffix).json", fromG1: true)
  }

  // MARK: - Private Helpers

  private func loadEquation(filename: String, fromG1: Bool = false) throws -> RegressionEquation {
    let url = fromG1 ? g1DataURL.appending(path: filename) : dataURL.appending(path: filename)
    return try RegressionEquation(fileURL: url)
  }
}

// MARK: - FlapSetting Extension

extension FlapSetting {
  /// The file suffix used for regression equation JSON files.
  var regressionFileSuffix: String {
    switch self {
      case .flapsUp: "flapsup"
      case .flapsUpIce: "flapsupice"
      case .flaps50: "flaps50"
      case .flaps50Ice: "flaps50ice"
      case .flaps100: "flaps100"
    }
  }

  /// Whether this flap setting is ice-contaminated.
  var isIceContaminated: Bool {
    switch self {
      case .flapsUpIce, .flaps50Ice: true
      default: false
    }
  }
}
