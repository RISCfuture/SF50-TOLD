import Foundation

public protocol Limitations {
  static var maxTakeoffWeight: Measurement<UnitMass> { get }
  static var maxLandingWeight: Measurement<UnitMass> { get }
  static var maxZeroFuelWeight: Measurement<UnitMass> { get }
  static var maxTakeoffAltitude: Measurement<UnitLength> { get }
  static var maxTailwind: Measurement<UnitSpeed> { get }
  static var maxCrosswind_flaps50: Measurement<UnitSpeed> { get }
  static var maxCrosswind_flaps100: Measurement<UnitSpeed> { get }
  static var maxFuel: Measurement<UnitVolume> { get }
  static var minRunwayLength: Measurement<UnitLength> { get }
  static var minTemperature: Measurement<UnitTemperature> { get }
  static var maxTemperature: Measurement<UnitTemperature> { get }
}

public struct LimitationsG1: Limitations {
  public static let maxTakeoffWeight = Measurement(value: 6000, unit: UnitMass.pounds)
  public static let maxLandingWeight = Measurement(value: 5550, unit: UnitMass.pounds)
  public static let maxZeroFuelWeight = Measurement(value: 4900, unit: UnitMass.pounds)
  public static let maxTakeoffAltitude = Measurement(value: 10_000, unit: UnitLength.feet)
  public static let maxTailwind = Measurement(value: 10, unit: UnitSpeed.knots)  // takeoff and landing
  public static let maxCrosswind_flaps50 = Measurement(value: 18, unit: UnitSpeed.knots)
  public static let maxCrosswind_flaps100 = Measurement(value: 16, unit: UnitSpeed.knots)
  public static let maxFuel = Measurement(value: 296, unit: UnitVolume.gallons)
  public static let minRunwayLength = Measurement(value: 1400, unit: UnitLength.feet)
  public static let minTemperature = Measurement(value: -40, unit: UnitTemperature.celsius)
  public static let maxTemperature = Measurement(value: 50, unit: UnitTemperature.celsius)

  private init() {}
}

public struct LimitationsG2Plus: Limitations {
  public static let maxTakeoffWeight = Measurement(value: 6000, unit: UnitMass.pounds)
  public static let maxLandingWeight = Measurement(value: 5550, unit: UnitMass.pounds)
  public static let maxZeroFuelWeight = Measurement(value: 4900, unit: UnitMass.pounds)
  public static let maxTakeoffAltitude = Measurement(value: 10_000, unit: UnitLength.feet)
  public static let maxTailwind = Measurement(value: 10, unit: UnitSpeed.knots)  // takeoff and landing
  public static let maxCrosswind_flaps50 = Measurement(value: 18, unit: UnitSpeed.knots)
  public static let maxCrosswind_flaps100 = Measurement(value: 16, unit: UnitSpeed.knots)
  public static let maxFuel = Measurement(value: 296, unit: UnitVolume.gallons)
  public static let minRunwayLength = Measurement(value: 1400, unit: UnitLength.feet)
  public static let minTemperature = Measurement(value: -40, unit: UnitTemperature.celsius)
  public static let maxTemperature = Measurement(value: 50, unit: UnitTemperature.celsius)

  private init() {}
}
