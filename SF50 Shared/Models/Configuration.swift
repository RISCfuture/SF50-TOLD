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
/// Different aircraft generations have different operational limitations and
/// performance characteristics. The key differences are:
///
/// - **G1**: Maximum enroute altitude of 28,000 ft, no updated thrust schedule
/// - **G2**: Maximum enroute altitude of 31,000 ft, may have updated thrust schedule (SB5X-72-01)
/// - **G2+**: Maximum enroute altitude of 31,000 ft, always has updated thrust schedule
///
/// The G2 case includes an associated value indicating whether the aircraft has the
/// updated thrust schedule (SB5X-72-01 completed). This affects performance calculations
/// but not operational limitations.
public enum AircraftType: Sendable, Equatable {
  /// First generation SF50 Vision Jet (max 28,000 ft)
  case g1
  /// Second generation SF50 Vision Jet (max 31,000 ft)
  /// - Parameter updatedThrustSchedule: Whether SB5X-72-01 is completed
  case g2(updatedThrustSchedule: Bool)
  /// Second generation plus SF50 Vision Jet (max 31,000 ft)
  case g2Plus

  /// The operational limitations for this aircraft type.
  public var limitations: Limitations.Type {
    switch self {
      case .g1: LimitationsG1.self
      case .g2, .g2Plus: LimitationsG2.self
    }
  }

  /// Whether this aircraft uses the updated (G2+) thrust schedule for performance calculations.
  ///
  /// - G1: Always false (uses G1 performance data)
  /// - G2 without SB: false (uses G1 performance data)
  /// - G2 with SB: true (uses G2+ performance data)
  /// - G2+: Always true (uses G2+ performance data)
  public var usesUpdatedThrustSchedule: Bool {
    switch self {
      case .g1: false
      case .g2(let updated): updated
      case .g2Plus: true
    }
  }
}
