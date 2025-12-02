import Foundation
import SF50_Shared

/// A lightweight, Sendable snapshot of runway data for widget timeline entries.
///
/// ``RunwaySnapshot`` captures only the essential runway properties needed for
/// widget display, avoiding the need to pass non-Sendable SwiftData models
/// across actor boundaries.
///
/// ## Properties
///
/// - ``name``: Runway designator (e.g., "28L")
/// - ``takeoffDistanceOrLength``: Available takeoff distance or runway length
/// - ``trueHeading``: Runway true heading for wind calculations
///
/// ## Wind Calculations
///
/// The snapshot provides methods to calculate wind components:
/// - ``headwind(conditions:)`` - Headwind/tailwind component
/// - ``crosswind(conditions:)`` - Left/right crosswind component
struct RunwaySnapshot: Sendable {
  /// Runway designator (e.g., "28L", "09").
  let name: String

  /// Available takeoff distance or total runway length.
  let takeoffDistanceOrLength: Measurement<UnitLength>

  /// Runway true heading in degrees.
  let trueHeading: Measurement<UnitAngle>

  /// Calculate headwind component for the given conditions.
  func headwind(conditions: Conditions) -> Measurement<UnitSpeed> {
    guard let windDirection = conditions.windDirection,
      let windSpeed = conditions.windSpeed
    else { return .init(value: 0, unit: .knots) }
    let angle = windDirection - trueHeading
    return windSpeed * cos(angle)
  }

  /// Calculate crosswind component for the given conditions.
  func crosswind(conditions: Conditions) -> Measurement<UnitSpeed> {
    guard let windDirection = conditions.windDirection,
      let windSpeed = conditions.windSpeed
    else { return .init(value: 0, unit: .knots) }
    let angle = windDirection - trueHeading
    return windSpeed * sin(angle)
  }
}

extension RunwaySnapshot {
  /// Name comparator that matches Runway.NameComparator behavior.
  struct NameComparator: SortComparator {
    typealias Compared = RunwaySnapshot

    /// Sort order (forward = ascending, reverse = descending).
    var order: SortOrder = .forward

    func compare(_ lhs: RunwaySnapshot, _ rhs: RunwaySnapshot) -> ComparisonResult {
      let result = lhs.name.localizedStandardCompare(rhs.name)
      return order == .forward ? result : result.inverted
    }
  }
}

extension ComparisonResult {
  fileprivate var inverted: ComparisonResult {
    switch self {
      case .orderedAscending: return .orderedDescending
      case .orderedDescending: return .orderedAscending
      case .orderedSame: return .orderedSame
    }
  }
}
