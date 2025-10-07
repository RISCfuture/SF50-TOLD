import Foundation

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
