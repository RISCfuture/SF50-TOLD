import Foundation

class BaseRegressionPerformanceModel: BasePerformanceModel {

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
