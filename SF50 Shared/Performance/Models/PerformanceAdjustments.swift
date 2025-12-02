import Foundation

/// Performance adjustment factor calculations.
///
/// ``PerformanceAdjustments`` provides static methods to calculate multiplicative
/// adjustment factors for wind, gradient, and surface conditions. These factors
/// are applied to base performance values to account for environmental effects.
///
/// ## Adjustment Types
///
/// - **Wind**: Headwind reduces distances, tailwind increases them
/// - **Gradient**: Uphill increases takeoff run, decreases landing run (opposite effects)
/// - **Surface**: Unpaved (turf) runways add margin to distances
///
/// ## Two Calculation Modes
///
/// 1. **Scalar factors**: Simple multipliers for regression models
/// 2. **Table-based factors**: Weight-dependent factors from ``DataTable`` for tabular models
///
/// ## Factor Application
///
/// Factors are multiplicative: a factor of 1.0 means no change, 0.9 reduces by 10%,
/// and 1.1 increases by 10%. Negative wind components (tailwind when headwind expected)
/// are handled by separate methods.
enum PerformanceAdjustments {

  // MARK: - Takeoff Run Adjustments

  static func takeoffRunHeadwindAdjustment(factor: Double, headwind: Double) -> Double {
    1 - factor * headwind / 10
  }

  static func takeoffRunTailwindAdjustment(factor: Double, tailwind: Double) -> Double {
    1 + factor * tailwind / 10
  }

  static func takeoffRunUphillAdjustment(factor: Double, uphill: Double) -> Double {
    1 + factor * uphill * 100
  }

  static func takeoffRunDownhillAdjustment(factor: Double, downhill: Double) -> Double {
    1 - factor * downhill * 100
  }

  // MARK: - Takeoff Distance Adjustments

  static func takeoffDistanceHeadwindAdjustment(factor: Double, headwind: Double) -> Double {
    1 - factor * headwind / 10
  }

  static func takeoffDistanceTailwindAdjustment(factor: Double, tailwind: Double) -> Double {
    1 + factor * tailwind / 10
  }

  static func takeoffDistanceUnpavedAdjustment(factor: Double) -> Double {
    1 + factor
  }

  // MARK: - Landing Run Adjustments

  static func landingRunHeadwindAdjustment(factor: Double, headwind: Double) -> Double {
    1 - factor * headwind / 10
  }

  static func landingRunTailwindAdjustment(factor: Double, tailwind: Double) -> Double {
    1 + factor * tailwind / 10
  }

  static func landingRunUphillAdjustment(factor: Double, uphill: Double) -> Double {
    1 - factor * uphill * 100
  }

  static func landingRunDownhillAdjustment(factor: Double, downhill: Double) -> Double {
    1 + factor * downhill * 100
  }

  // MARK: - Landing Distance Adjustments

  static func landingDistanceHeadwindAdjustment(factor: Double, headwind: Double) -> Double {
    1 - factor * headwind / 10
  }

  static func landingDistanceTailwindAdjustment(factor: Double, tailwind: Double) -> Double {
    1 + factor * tailwind / 10
  }

  static func landingDistanceUnpavedAdjustment(factor: Double) -> Double {
    1 + factor
  }

  // MARK: - Tabular Model Adjustments with DataTable

  static func takeoffRunHeadwindAdjustment(data: DataTable, weight: Double, headwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 - $0 * headwind / 10 }
  }

  static func takeoffRunTailwindAdjustment(data: DataTable, weight: Double, tailwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 * tailwind / 10 }
  }

  static func takeoffRunUphillAdjustment(data: DataTable, weight: Double, uphill: Double) -> Value<
    Double
  > {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 * uphill * 100 }
  }

  static func takeoffRunDownhillAdjustment(data: DataTable, weight: Double, downhill: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 - $0 * downhill * 100 }
  }

  static func takeoffDistanceHeadwindAdjustment(data: DataTable, weight: Double, headwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 - $0 * headwind / 10 }
  }

  static func takeoffDistanceTailwindAdjustment(data: DataTable, weight: Double, tailwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 * tailwind / 10 }
  }

  static func takeoffDistanceUnpavedAdjustment(data: DataTable, weight: Double) -> Value<Double> {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 }
  }

  static func landingRunHeadwindAdjustment(data: DataTable, weight: Double, headwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 - $0 * headwind / 10 }
  }

  static func landingRunTailwindAdjustment(data: DataTable, weight: Double, tailwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 * tailwind / 10 }
  }

  static func landingRunUphillAdjustment(data: DataTable, weight: Double, uphill: Double) -> Value<
    Double
  > {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 - $0 * uphill * 100 }
  }

  static func landingRunDownhillAdjustment(data: DataTable, weight: Double, downhill: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 * downhill * 100 }
  }

  static func landingDistanceHeadwindAdjustment(data: DataTable, weight: Double, headwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 - $0 * headwind / 10 }
  }

  static func landingDistanceTailwindAdjustment(data: DataTable, weight: Double, tailwind: Double)
    -> Value<Double>
  {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 * tailwind / 10 }
  }

  static func landingDistanceUnpavedAdjustment(data: DataTable, weight: Double) -> Value<Double> {
    let factor = data.value(for: [weight], clamping: [.clampBoth])
    return factor.map { 1 + $0 }
  }
}
