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

  /// Creates a new aircraft configuration.
  /// - Parameters:
  ///   - weight: Aircraft gross weight
  ///   - flapSetting: Flap deflection setting
  public init(weight: Measurement<UnitMass>, flapSetting: FlapSetting) {
    self.weight = weight
    self.flapSetting = flapSetting
  }

  func clampWeight(min: Measurement<UnitMass>? = nil, max: Measurement<UnitMass>? = nil) -> Self {
    var weight = weight
    if let min, min > weight { weight = min }
    if let max, max < weight { weight = max }

    return .init(weight: weight, flapSetting: flapSetting)
  }
}

public enum AircraftType: String {
  case G1
  case G2Plus
}
