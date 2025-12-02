import Foundation

/// Base class for regression-based performance models.
///
/// ``BaseRegressionPerformanceModel`` extends ``BasePerformanceModel`` with support
/// for polynomial regression calculations and bounds checking against AFM table ranges.
/// This class provides shared infrastructure for both G1 and G2+ regression models.
///
/// ## Bounds Checking
///
/// Regression models can extrapolate beyond the original AFM data range, but results
/// outside the bounds may be less reliable. The bounds checker validates inputs against
/// the tabular model limits:
///
/// - ``takeoffInputsOffscaleLow`` / ``takeoffInputsOffscaleHigh``
/// - ``landingInputsOffscaleLow`` / ``landingInputsOffscaleHigh``
///
/// ## Uncertainty Calculation
///
/// Regression models include statistical uncertainty based on residual errors from
/// the curve fitting process. The ``uncertainty(for:)`` method retrieves RMSE values
/// for specific calculation tables.
class BaseRegressionPerformanceModel: BasePerformanceModel {

  // MARK: - Properties

  /// Bounds checker to validate inputs against AFM table ranges.
  let boundsChecker: BoundsChecker

  /// Indicates if the takeoff inputs are below the minimum AFM table bounds.
  var takeoffInputsOffscaleLow: Bool {
    boundsChecker.takeoffBoundsStatus(
      weight: weight,
      altitude: altitude,
      temperature: temperature
    ) == .belowMinimum
  }

  /// Indicates if the takeoff inputs are above the maximum AFM table bounds.
  var takeoffInputsOffscaleHigh: Bool {
    boundsChecker.takeoffBoundsStatus(
      weight: weight,
      altitude: altitude,
      temperature: temperature
    ) == .aboveMaximum
  }

  /// Indicates if the landing inputs are below the minimum AFM table bounds.
  var landingInputsOffscaleLow: Bool {
    boundsChecker.landingBoundsStatus(
      weight: weight,
      altitude: altitude,
      temperature: temperature,
      flapSetting: configuration.flapSetting
    ) == .belowMinimum
  }

  /// Indicates if the landing inputs are above the maximum AFM table bounds.
  var landingInputsOffscaleHigh: Bool {
    boundsChecker.landingBoundsStatus(
      weight: weight,
      altitude: altitude,
      temperature: temperature,
      flapSetting: configuration.flapSetting
    ) == .aboveMaximum
  }

  // MARK: - Initializer

  init(
    conditions: Conditions,
    configuration: Configuration,
    runway: RunwayInput,
    notam: NOTAMSnapshot?,
    modelType: DataTableLoader.ModelType
  ) {
    self.boundsChecker = BoundsChecker(modelType: modelType)
    super.init(conditions: conditions, configuration: configuration, runway: runway, notam: notam)
  }

  // MARK: - Shared uncertainty calculation

  func uncertainty(for table: String) -> Double {
    ResidualErrorCalculator.RMSE(
      for: table,
      binParameters: [
        "weight": weight,
        "altitude": altitude,
        "temperature": temperature
      ]
    )
  }

  // MARK: - Shared contamination calculation

  func landingRun_contaminationAddition(distance: Value<Double>) -> Value<Double> {
    ContaminationCalculator.landingRunContaminationAddition(
      distance: distance,
      contamination: notam?.contamination
    )
  }
}
