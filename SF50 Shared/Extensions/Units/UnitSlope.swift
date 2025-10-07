import Foundation

/// In mathematics, the slope or gradient of a line is a number that describes the
/// direction of the line on a plane. Often denoted by the letter _m_, slope is
/// calculated as the ratio of the vertical change to the horizontal change
/// ("rise over run") between two distinct points on the line, giving the same
/// number for any choice of points.
public final class UnitSlope: Dimension, @unchecked Sendable {
  /// Base unit: gradient = rise/run as decimal
  public static let gradient = UnitSlope(
    symbol: "m",
    converter: UnitConverterLinear(coefficient: 1.0)
  )

  /// Percent grade, or gradient × 100
  public static let percentGrade = UnitSlope(
    symbol: "%",
    converter: UnitConverterLinear(coefficient: 100.0)
  )

  /// Feet per nautical mile (ft/NM)
  public static let feetPerNauticalMile = UnitSlope(
    symbol: "ft/NM",
    converter: UnitConverterLinear(
      coefficient: Measurement(value: 1, unit: UnitLength.feet).converted(to: .nauticalMiles).value
    )
  )

  override public static func baseUnit() -> UnitSlope { .gradient }
}
