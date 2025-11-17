import Foundation
import SF50_Shared

/// A lightweight, Sendable snapshot of runway data for use in widget timeline entries.
///
/// This struct captures only the essential runway properties needed for widget display,
/// avoiding the need to pass non-Sendable SwiftData models across actor boundaries.
struct RunwaySnapshot: Sendable {
  let name: String
  let takeoffDistanceOrLength: Measurement<UnitLength>
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
