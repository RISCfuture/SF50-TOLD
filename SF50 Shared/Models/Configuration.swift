import Foundation

/// Aircraft flap configuration settings.
///
/// The SF50 Vision Jet has three flap positions (Up, 50%, 100%) which affect
/// takeoff and landing performance. Ice protection variants account for the
/// performance penalty when the ice protection system is active.
public enum FlapSetting: Sendable {
  /// Flaps up (clean configuration)
  case flapsUp
  /// Flaps up with ice protection
  case flapsUpIce
  /// Flaps 50% deflection
  case flaps50
  /// Flaps 50% with ice protection
  case flaps50Ice
  /// Flaps 100% deflection
  case flaps100
}

/// Aircraft configuration including weight and flap setting.
///
/// ``Configuration`` represents the physical configuration of the aircraft
/// for performance calculations, including gross weight and flap deflection.
///
/// ## Topics
///
/// ### Properties
/// - ``weight``
/// - ``flapSetting``
/// - ``iceProtection``
public struct Configuration {
  /// Aircraft gross weight
  public let weight: Measurement<UnitMass>

  /// Flap deflection setting
  public let flapSetting: FlapSetting

  /// Ice protection system (IPS) enabled for takeoff/enroute climb
  public let iceProtection: Bool

  /// Creates a new aircraft configuration.
  /// - Parameters:
  ///   - weight: Aircraft gross weight
  ///   - flapSetting: Flap deflection setting
  ///   - iceProtection: Ice protection system enabled (default: false)
  public init(weight: Measurement<UnitMass>, flapSetting: FlapSetting, iceProtection: Bool = false)
  {
    self.weight = weight
    self.flapSetting = flapSetting
    self.iceProtection = iceProtection
  }

  /// Returns a configuration with weight clamped to the specified range.
  func clampWeight(min: Measurement<UnitMass>? = nil, max: Measurement<UnitMass>? = nil) -> Self {
    var weight = weight
    if let min, min > weight { weight = min }
    if let max, max < weight { weight = max }

    return .init(weight: weight, flapSetting: flapSetting, iceProtection: iceProtection)
  }
}

/// The generation of SF50 Vision Jet aircraft.
///
/// Different aircraft generations have different performance characteristics
/// and require different performance models for accurate calculations.
public enum AircraftType: String {
  /// First generation SF50 Vision Jet
  case G1
  /// Second generation and later SF50 Vision Jet (G2, G2+)
  case G2Plus
}
