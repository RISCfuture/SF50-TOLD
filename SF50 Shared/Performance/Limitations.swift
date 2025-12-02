import Foundation

/// Protocol defining aircraft operational limitations.
///
/// ``Limitations`` provides access to the aircraft's certified operating limits
/// as specified in the Aircraft Flight Manual (AFM). Different aircraft generations
/// may have different limitations.
///
/// ## Topics
///
/// ### Weight Limits
/// - ``maxTakeoffWeight``
/// - ``maxLandingWeight``
/// - ``maxZeroFuelWeight``
///
/// ### Altitude Limits
/// - ``maxTakeoffAltitude``
/// - ``maxEnrouteAltitude``
///
/// ### Wind Limits
/// - ``maxTailwind``
/// - ``maxCrosswind_flaps50``
/// - ``maxCrosswind_flaps100``
///
/// ### Other Limits
/// - ``maxFuel``
/// - ``minRunwayLength``
/// - ``minTemperature``
/// - ``maxTemperature``
public protocol Limitations {
  /// Maximum certified takeoff weight.
  static var maxTakeoffWeight: Measurement<UnitMass> { get }

  /// Maximum certified landing weight.
  static var maxLandingWeight: Measurement<UnitMass> { get }

  /// Maximum zero fuel weight.
  static var maxZeroFuelWeight: Measurement<UnitMass> { get }

  /// Maximum pressure altitude for takeoff.
  static var maxTakeoffAltitude: Measurement<UnitLength> { get }

  /// Maximum pressure altitude for enroute flight.
  static var maxEnrouteAltitude: Measurement<UnitLength> { get }

  /// Maximum tailwind component for takeoff and landing.
  static var maxTailwind: Measurement<UnitSpeed> { get }

  /// Maximum crosswind component with flaps 50.
  static var maxCrosswind_flaps50: Measurement<UnitSpeed> { get }

  /// Maximum crosswind component with flaps 100.
  static var maxCrosswind_flaps100: Measurement<UnitSpeed> { get }

  /// Maximum usable fuel capacity.
  static var maxFuel: Measurement<UnitVolume> { get }

  /// Minimum runway length for operations.
  static var minRunwayLength: Measurement<UnitLength> { get }

  /// Minimum operating temperature.
  static var minTemperature: Measurement<UnitTemperature> { get }

  /// Maximum operating temperature.
  static var maxTemperature: Measurement<UnitTemperature> { get }
}

/// Operational limitations for first-generation SF50 Vision Jet (G1).
public struct LimitationsG1: Limitations {
  public static let maxTakeoffWeight = Measurement(value: 6000, unit: UnitMass.pounds)
  public static let maxLandingWeight = Measurement(value: 5550, unit: UnitMass.pounds)
  public static let maxZeroFuelWeight = Measurement(value: 4900, unit: UnitMass.pounds)
  public static let maxTakeoffAltitude = Measurement(value: 10_000, unit: UnitLength.feet)
  public static let maxEnrouteAltitude = Measurement(value: 28_000, unit: UnitLength.feet)
  public static let maxTailwind = Measurement(value: 10, unit: UnitSpeed.knots)  // takeoff and landing
  public static let maxCrosswind_flaps50 = Measurement(value: 18, unit: UnitSpeed.knots)
  public static let maxCrosswind_flaps100 = Measurement(value: 16, unit: UnitSpeed.knots)
  public static let maxFuel = Measurement(value: 296, unit: UnitVolume.gallons)
  public static let minRunwayLength = Measurement(value: 1400, unit: UnitLength.feet)
  public static let minTemperature = Measurement(value: -40, unit: UnitTemperature.celsius)
  public static let maxTemperature = Measurement(value: 50, unit: UnitTemperature.celsius)

  private init() {}
}

/// Operational limitations for second-generation and later SF50 Vision Jet (G2, G2+).
public struct LimitationsG2Plus: Limitations {
  public static let maxTakeoffWeight = Measurement(value: 6000, unit: UnitMass.pounds)
  public static let maxLandingWeight = Measurement(value: 5550, unit: UnitMass.pounds)
  public static let maxZeroFuelWeight = Measurement(value: 4900, unit: UnitMass.pounds)
  public static let maxTakeoffAltitude = Measurement(value: 10_000, unit: UnitLength.feet)
  public static let maxEnrouteAltitude = Measurement(value: 31_000, unit: UnitLength.feet)
  public static let maxTailwind = Measurement(value: 10, unit: UnitSpeed.knots)  // takeoff and landing
  public static let maxCrosswind_flaps50 = Measurement(value: 18, unit: UnitSpeed.knots)
  public static let maxCrosswind_flaps100 = Measurement(value: 16, unit: UnitSpeed.knots)
  public static let maxFuel = Measurement(value: 296, unit: UnitVolume.gallons)
  public static let minRunwayLength = Measurement(value: 1400, unit: UnitLength.feet)
  public static let minTemperature = Measurement(value: -40, unit: UnitTemperature.celsius)
  public static let maxTemperature = Measurement(value: 50, unit: UnitTemperature.celsius)

  private init() {}
}
