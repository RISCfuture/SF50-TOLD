import Defaults
import SF50_Shared
import SwiftUI

/// A view that provides the aircraft type to its children via the environment.
///
/// This view observes `aircraftTypeSetting` and `updatedThrustSchedule` from Defaults,
/// constructing the full `AircraftType` and injecting it into the environment. This
/// allows child views to simply use `@Environment(\.aircraftType)` without needing
/// to access Defaults directly.
///
/// ## Usage
/// ```swift
/// AircraftTypeProvider {
///   // Child views can use @Environment(\.aircraftType)
///   MyView()
/// }
/// ```
struct AircraftTypeProvider<Content: View>: View {
  @Default(.aircraftTypeSetting)
  private var aircraftTypeSetting

  @Default(.updatedThrustSchedule)
  private var updatedThrustSchedule

  @ViewBuilder var content: () -> Content

  private var aircraftType: AircraftType {
    guard let setting = aircraftTypeSetting else {
      // Legacy migration: infer from updatedThrustSchedule
      return updatedThrustSchedule ? .g2Plus : .g2(updatedThrustSchedule: false)
    }
    switch setting {
      case .g1: return .g1
      case .g2: return .g2(updatedThrustSchedule: updatedThrustSchedule)
      case .g2Plus: return .g2Plus
    }
  }

  var body: some View {
    content()
      .environment(\.aircraftType, aircraftType)
  }
}
