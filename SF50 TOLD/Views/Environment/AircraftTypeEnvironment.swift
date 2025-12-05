import SF50_Shared
import SwiftUI

// MARK: - Environment

private struct AircraftTypeKey: EnvironmentKey {
  static let defaultValue = AircraftType.g2(updatedThrustSchedule: false)
}

extension EnvironmentValues {
  /// The current aircraft type for the view hierarchy.
  ///
  /// This provides the effective aircraft type, accounting for legacy
  /// `updatedThrustSchedule` settings when `aircraftType` is not explicitly set.
  var aircraftType: AircraftType {
    get { self[AircraftTypeKey.self] }
    set { self[AircraftTypeKey.self] = newValue }
  }
}
