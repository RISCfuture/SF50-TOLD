import Defaults
import Foundation

/// Aircraft type setting for UserDefaults storage.
///
/// This is a simple enum used only for persisting the user's aircraft type selection.
/// For app-wide use, convert to ``AircraftType`` which includes the G2's thrust schedule state.
public enum AircraftTypeSetting: String, Sendable, CaseIterable {
  /// First generation SF50 Vision Jet
  case g1 = "G1"
  /// Second generation SF50 Vision Jet
  case g2 = "G2"
  /// Second generation plus SF50 Vision Jet
  case g2Plus = "G2+"
}

// MARK: - Defaults.Serializable

public struct AircraftTypeSettingBridge: Defaults.Bridge, Sendable {
  public typealias Value = AircraftTypeSetting
  public typealias Serializable = String

  public func serialize(_ value: AircraftTypeSetting?) -> String? {
    value?.rawValue
  }

  public func deserialize(_ object: String?) -> AircraftTypeSetting? {
    guard let object else { return nil }
    return AircraftTypeSetting(rawValue: object)
  }
}

extension AircraftTypeSetting: Defaults.Serializable {
  public static let bridge = AircraftTypeSettingBridge()
}
