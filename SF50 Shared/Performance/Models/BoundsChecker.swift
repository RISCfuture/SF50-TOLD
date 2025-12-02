import Foundation

/// Status of inputs relative to AFM table bounds.
///
/// Used by ``BoundsChecker`` to indicate whether performance calculation inputs
/// fall within, below, or above the valid data range.
enum BoundsStatus {
  /// All inputs are within the valid AFM table range.
  case withinBounds
  /// One or more inputs are below the minimum table value.
  case belowMinimum
  /// One or more inputs are above the maximum table value.
  case aboveMaximum
}

/// Validates performance calculation inputs against AFM data table bounds.
///
/// ``BoundsChecker`` is used by regression models to validate that inputs (weight,
/// altitude, temperature) fall within the ranges covered by the original AFM tables.
/// While regression models can extrapolate beyond these bounds, results outside the
/// valid range may be less reliable.
///
/// ## Usage
///
/// ```swift
/// let checker = BoundsChecker(modelType: .g1)
///
/// let status = checker.takeoffBoundsStatus(
///     weight: 5800,
///     altitude: 5000,
///     temperature: 30
/// )
///
/// if status == .aboveMaximum {
///     // Warn user that inputs exceed AFM data range
/// }
/// ```
final class BoundsChecker {

  private let takeoffRunData: DataTable
  private let landingRunData_flaps100: DataTable
  private let landingRunData_flaps50: DataTable
  private let landingRunData_flaps50Ice: DataTable

  // swiftlint:disable force_try
  init(modelType: DataTableLoader.ModelType) {
    let loader = DataTableLoader(modelType: modelType)

    // Load takeoff data for bounds
    self.takeoffRunData = try! loader.loadTakeoffRunData()

    // Load landing data for each flap configuration
    self.landingRunData_flaps100 = try! loader.loadLandingRunData(landingPrefix: "100")
    self.landingRunData_flaps50 = try! loader.loadLandingRunData(landingPrefix: "50")
    self.landingRunData_flaps50Ice = try! loader.loadLandingRunData(landingPrefix: "50 ice")
  }
  // swiftlint:enable force_try

  /// Returns the bounds status for takeoff parameters.
  /// - Parameters:
  ///   - weight: Aircraft weight in lbs
  ///   - altitude: Pressure altitude in feet
  ///   - temperature: Temperature in Celsius
  /// - Returns: The bounds status (within, below, or above limits)
  func takeoffBoundsStatus(
    weight: Double,
    altitude: Double,
    temperature: Double
  ) -> BoundsStatus {
    checkBoundsStatus(
      weight: weight,
      altitude: altitude,
      temperature: temperature,
      dataTable: takeoffRunData
    )
  }

  /// Checks if takeoff parameters are within bounds and returns the value or offscale state.
  /// - Parameters:
  ///   - weight: Aircraft weight in lbs
  ///   - altitude: Pressure altitude in feet
  ///   - temperature: Temperature in Celsius
  ///   - value: The computed value to return if within bounds
  /// - Returns: The value if within bounds, or .offscaleLow/.offscaleHigh if out of bounds
  func checkTakeoffBounds<T>(
    weight: Double,
    altitude: Double,
    temperature: Double,
    value: Value<T>
  ) -> Value<T> {
    checkBounds(
      weight: weight,
      altitude: altitude,
      temperature: temperature,
      value: value,
      dataTable: takeoffRunData
    )
  }

  /// Returns the bounds status for landing parameters.
  /// - Parameters:
  ///   - weight: Aircraft weight in lbs
  ///   - altitude: Pressure altitude in feet
  ///   - temperature: Temperature in Celsius
  ///   - flapSetting: The flap configuration to check bounds for
  /// - Returns: The bounds status (within, below, or above limits)
  func landingBoundsStatus(
    weight: Double,
    altitude: Double,
    temperature: Double,
    flapSetting: FlapSetting
  ) -> BoundsStatus {
    let dataTable: DataTable =
      switch flapSetting {
        case .flaps100: landingRunData_flaps100
        case .flaps50, .flapsUp: landingRunData_flaps50
        case .flaps50Ice, .flapsUpIce: landingRunData_flaps50Ice
      }

    return checkBoundsStatus(
      weight: weight,
      altitude: altitude,
      temperature: temperature,
      dataTable: dataTable
    )
  }

  /// Checks if landing parameters are within bounds for the given flap setting.
  /// - Parameters:
  ///   - weight: Aircraft weight in lbs
  ///   - altitude: Pressure altitude in feet
  ///   - temperature: Temperature in Celsius
  ///   - value: The computed value to return if within bounds
  ///   - flapSetting: The flap configuration to check bounds for
  /// - Returns: The value if within bounds, or .offscaleLow/.offscaleHigh if out of bounds
  func checkLandingBounds<T>(
    weight: Double,
    altitude: Double,
    temperature: Double,
    value: Value<T>,
    flapSetting: FlapSetting
  ) -> Value<T> {
    let dataTable: DataTable =
      switch flapSetting {
        case .flaps100: landingRunData_flaps100
        case .flaps50, .flapsUp: landingRunData_flaps50
        case .flaps50Ice, .flapsUpIce: landingRunData_flaps50Ice
      }

    return checkBounds(
      weight: weight,
      altitude: altitude,
      temperature: temperature,
      value: value,
      dataTable: dataTable
    )
  }

  // MARK: - Private Helpers

  private func checkBoundsStatus(
    weight: Double,
    altitude: Double,
    temperature: Double,
    dataTable: DataTable
  ) -> BoundsStatus {
    let inputs = [weight, altitude, temperature]

    // Check each dimension (weight=0, altitude=1, temperature=2)
    for dimension in 0..<3 {
      let input = inputs[dimension]
      let minValue = dataTable.min(dimension: dimension)
      let maxValue = dataTable.max(dimension: dimension)

      if input < minValue {
        return .belowMinimum
      }
      if input > maxValue {
        return .aboveMaximum
      }
    }

    // All parameters within bounds
    return .withinBounds
  }

  private func checkBounds<T>(
    weight: Double,
    altitude: Double,
    temperature: Double,
    value: Value<T>,
    dataTable: DataTable
  ) -> Value<T> {
    let inputs = [weight, altitude, temperature]

    // Check each dimension (weight=0, altitude=1, temperature=2)
    for dimension in 0..<3 {
      let input = inputs[dimension]
      let minValue = dataTable.min(dimension: dimension)
      let maxValue = dataTable.max(dimension: dimension)

      if input < minValue {
        return .offscaleLow
      }
      if input > maxValue {
        return .offscaleHigh
      }
    }

    // All parameters within bounds
    return value
  }
}
