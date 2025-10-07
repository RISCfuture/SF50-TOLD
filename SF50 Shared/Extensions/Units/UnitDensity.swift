import Foundation

/// Density (ρ) is a substance's mass per unit of volume. Mathematically,
/// density is defined as mass divided by volume.
@preconcurrency
public class UnitDensity: Dimension, @unchecked Sendable {

  /// Kilograms per cubic meter (kg/m^3): SI unit of density
  public static let kilogramsPerCubicMeter: UnitDensity = unit(
    UnitMass.kilograms,
    per: UnitVolume.cubicMeters
  )

  /// Grams per cubic meter (g/m^3)
  public static let gramsPerCubicMeter: UnitDensity = unit(
    UnitMass.grams,
    per: UnitVolume.cubicMeters
  )

  /// Grams per cubic centimeter (g/cm^3): CGS unit of density
  public static let gramsPerCubicCentimeter: UnitDensity = unit(
    UnitMass.grams,
    per: UnitVolume.cubicCentimeters
  )

  /// Kilograms per liter (kg/L)
  public static let kilogramsPerLiter: UnitDensity = unit(
    UnitMass.kilograms,
    per: UnitVolume.liters
  )

  /// Pounds per cubic foot (lb/ft^3): American standard unit of density
  public static let poundsPerCubicFoot: UnitDensity = unit(
    UnitMass.pounds,
    per: UnitVolume.cubicFeet
  )

  /// Pounds per cubic inch (lb/in^3)
  public static let poundsPerCubicInch: UnitDensity = unit(
    UnitMass.pounds,
    per: UnitVolume.cubicInches
  )

  /// Ounces per cubic inch (oz/in^3)
  public static let ouncesPerCubicInch: UnitDensity = unit(
    UnitMass.ounces,
    per: UnitVolume.cubicInches
  )

  /// Pounds per gallon (lb/gal)
  public static let poundsPerGallon: UnitDensity = unit(UnitMass.pounds, per: UnitVolume.gallons)

  override public class func baseUnit() -> Self { kilogramsPerLiter as! Self }
}
