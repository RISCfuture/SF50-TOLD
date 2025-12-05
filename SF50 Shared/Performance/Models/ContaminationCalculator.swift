import Foundation

/// Calculates landing distance increases due to runway contamination.
///
/// ``ContaminationCalculator`` adjusts landing ground run distances when runways are
/// contaminated with water, slush, or snow. The AFM provides specific adjustment factors
/// for different contamination types and depths.
///
/// ## Supported Contamination Types
///
/// - **Water or slush**: Standing water up to specified depth
/// - **Slush or wet snow**: Depth-dependent adjustment
/// - **Dry snow**: Fixed percentage increase
/// - **Compact snow**: Fixed percentage increase (largest impact)
/// - **Wet runway**: Fixed percentage increase
///
/// ## Calculation Methods
///
/// Two calculation approaches are supported based on initialization:
///
/// 1. **Tabular**: Uses ``DataTable`` interpolation for exact AFM values (initialized with data tables)
/// 2. **Regression**: Uses polynomial formulas with uncertainty estimates (initialized without data tables)
///
/// The regression approach includes RMSE uncertainty from curve fitting, propagated
/// through to the final result.
///
/// ## Usage
///
/// ```swift
/// // For tabular model
/// let calculator = ContaminationCalculator(
///   modelType: .g2Plus,
///   compactSnowData: compactSnowTable,
///   drySnowData: drySnowTable,
///   slushData: slushTable,
///   waterData: waterTable
/// )
///
/// // For regression model
/// let calculator = ContaminationCalculator(modelType: .g2Plus)
///
/// let adjustedDistance = calculator.landingRunContaminationAddition(
///   distance: baseDistance,
///   contamination: .wetRunway
/// )
/// ```
final class ContaminationCalculator {

  // MARK: - Properties

  private let modelType: DataTableLoader.ModelType

  // Data tables for tabular mode (nil for regression mode)
  private let compactSnowData: DataTable?
  private let drySnowData: DataTable?
  private let slushData: DataTable?
  private let waterData: DataTable?

  /// Whether this calculator uses tabular data (vs regression formulas)
  private var usesTabularData: Bool { waterData != nil }

  // MARK: - Initializers

  /// Creates a contamination calculator for tabular model (with data tables).
  ///
  /// Use this initializer when the performance model uses tabular interpolation
  /// from digitized AFM data.
  ///
  /// - Parameter loader: The data table loader to load contamination tables from
  init(loader: DataTableLoader) throws {
    self.modelType = loader.modelType
    self.compactSnowData = try loader.loadContaminationCompactSnowData()
    self.drySnowData = try loader.loadContaminationDrySnowData()
    self.slushData = try loader.loadContaminationSlushData()
    self.waterData = try loader.loadContaminationWaterData()
  }

  /// Creates a contamination calculator for regression model (no data tables).
  ///
  /// Use this initializer when the performance model uses polynomial regression
  /// formulas derived from AFM data.
  ///
  /// - Parameter modelType: The aircraft model type (G1 or G2+)
  init(modelType: DataTableLoader.ModelType) {
    self.modelType = modelType
    self.compactSnowData = nil
    self.drySnowData = nil
    self.slushData = nil
    self.waterData = nil
  }

  // MARK: - Public Methods

  /// Calculates the contamination adjustment to landing run distance.
  ///
  /// This method applies the appropriate contamination factor based on the type
  /// and the calculator's configuration (tabular vs regression).
  ///
  /// - Parameters:
  ///   - distance: The base landing run distance
  ///   - contamination: The contamination type, or nil for clean runway
  /// - Returns: The adjusted landing run distance with contamination effects
  func landingRunContaminationAddition(
    distance: Value<Double>,
    contamination: Contamination?
  ) -> Value<Double> {
    guard let contamination else { return distance }

    if usesTabularData {
      return tabularContamination(distance: distance, contamination: contamination)
    }
    return regressionContamination(distance: distance, contamination: contamination)
  }

  // MARK: - Tabular Contamination

  private func tabularContamination(
    distance: Value<Double>,
    contamination: Contamination
  ) -> Value<Double> {
    switch contamination {
      case .wetRunway:
        // G2/G2+ AFM Reissue A: Add 15% to landing ground distance for wet runway
        // G1: No effect (tabular data doesn't include wet runway adjustment)
        guard modelType == .g2Plus else { return distance }
        return distance.map { value, uncertainty in
          (value * 1.15, uncertainty.map { $0 * 1.15 })
        }

      case .waterOrSlush(let depth):
        return tabularWaterContamination(distance: distance, depth: depth)

      case .slushOrWetSnow(let depth):
        return tabularSlushContamination(distance: distance, depth: depth)

      case .drySnow:
        return tabularDrySnowContamination(distance: distance)

      case .compactSnow:
        return tabularCompactSnowContamination(distance: distance)
    }
  }

  // MARK: - Regression Contamination

  private func regressionContamination(
    distance: Value<Double>,
    contamination: Contamination
  ) -> Value<Double> {
    switch contamination {
      case .wetRunway:
        // Regression model: Apply 15% increase for all aircraft types
        return distance.map { value, uncertainty in
          (value * 1.15, uncertainty.map { $0 * 1.15 })
        }

      case .waterOrSlush(let depth):
        return regressionWaterContamination(distance: distance, depth: depth)

      case .slushOrWetSnow(let depth):
        return regressionSlushContamination(distance: distance, depth: depth)

      case .drySnow:
        return regressionDrySnowContamination(distance: distance)

      case .compactSnow:
        return regressionCompactSnowContamination(distance: distance)
    }
  }

  // MARK: - Tabular Contamination Methods

  private func tabularWaterContamination(
    distance: Value<Double>,
    depth: Measurement<UnitLength>
  ) -> Value<Double> {
    guard let waterData else { return distance }

    return distance.flatMap { distanceValue in
      waterData.value(
        for: [distanceValue, depth.converted(to: .inches).value],
        clamping: [.clampBoth, .clampBoth]
      )
    }
  }

  private func tabularSlushContamination(
    distance: Value<Double>,
    depth: Measurement<UnitLength>
  ) -> Value<Double> {
    guard let slushData else { return distance }

    return distance.flatMap { distanceValue in
      slushData.value(
        for: [distanceValue, depth.converted(to: .inches).value],
        clamping: [.clampBoth, .clampBoth]
      )
    }
  }

  private func tabularDrySnowContamination(distance: Value<Double>) -> Value<Double> {
    guard let drySnowData else { return distance }

    return distance.flatMap { distanceValue in
      drySnowData.value(for: [distanceValue], clamping: [.clampBoth])
    }
  }

  private func tabularCompactSnowContamination(distance: Value<Double>) -> Value<Double> {
    guard let compactSnowData else { return distance }

    return distance.flatMap { distanceValue in
      compactSnowData.value(for: [distanceValue], clamping: [.clampBoth])
    }
  }

  // MARK: - Regression Contamination Methods

  private func regressionWaterContamination(
    distance: Value<Double>,
    depth: Measurement<UnitLength>
  ) -> Value<Double> {
    let depthInches = depth.converted(to: .inches).value

    return distance.map { distanceValue, existingUncertainty in
      let newDistance =
        1.406974e+00 * distanceValue
        + 1.076892e-03 * depthInches
        + 1.371359e+01

      let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
        for: "water",
        distance: distanceValue,
        depth: depthInches
      )

      let newUncertainty =
        if let existingUncertainty {
          sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
        } else {
          contaminationUncertainty
        }

      return (newDistance, newUncertainty)
    }
  }

  private func regressionSlushContamination(
    distance: Value<Double>,
    depth: Measurement<UnitLength>
  ) -> Value<Double> {
    let depthInches = depth.converted(to: .inches).value

    return distance.map { distanceValue, existingUncertainty in
      let newDistance =
        1.692337e+00 * distanceValue
        - 2.335086e-03 * depthInches
        + 3.409392e-07 * pow(distanceValue, 2)
        - 6.240405e-01 * distanceValue * depthInches
        + 1.113034e-01 * pow(depthInches, 2)
        + 7.443967e+00

      let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
        for: "slush, wet snow",
        distance: distanceValue,
        depth: depthInches
      )

      let newUncertainty =
        if let existingUncertainty {
          sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
        } else {
          contaminationUncertainty
        }

      return (newDistance, newUncertainty)
    }
  }

  private func regressionDrySnowContamination(distance: Value<Double>) -> Value<Double> {
    return distance.map { distanceValue, existingUncertainty in
      let newDistance =
        1.328947e+00 * distanceValue
        + 5.263158e+00

      let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
        for: "dry snow",
        distance: distanceValue
      )

      let newUncertainty =
        if let existingUncertainty {
          sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
        } else {
          contaminationUncertainty
        }

      return (newDistance, newUncertainty)
    }
  }

  private func regressionCompactSnowContamination(distance: Value<Double>) -> Value<Double> {
    return distance.map { distanceValue, existingUncertainty in
      let newDistance =
        1.578947e+00 * distanceValue
        + 5.263158e+00

      let contaminationUncertainty = ResidualErrorCalculator.contaminationRMSE(
        for: "compact snow",
        distance: distanceValue
      )

      let newUncertainty =
        if let existingUncertainty {
          sqrt(pow(existingUncertainty, 2) + pow(contaminationUncertainty, 2))
        } else {
          contaminationUncertainty
        }

      return (newDistance, newUncertainty)
    }
  }
}
