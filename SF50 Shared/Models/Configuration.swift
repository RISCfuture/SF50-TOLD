import Foundation

/// Aircraft flap configuration settings.
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
/// `Configuration` represents the physical configuration of the aircraft
/// for performance calculations, including gross weight and flap deflection.
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

  func clampWeight(min: Measurement<UnitMass>? = nil, max: Measurement<UnitMass>? = nil) -> Self {
    var weight = weight
    if let min, min > weight { weight = min }
    if let max, max < weight { weight = max }

    return .init(weight: weight, flapSetting: flapSetting, iceProtection: iceProtection)
  }
}

public enum AircraftType: String {
  case G1
  case G2Plus
}
