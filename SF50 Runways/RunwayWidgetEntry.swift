import Foundation
import SF50_Shared
import WidgetKit

/// A timeline entry containing runway performance data for widget display.
///
/// ``RunwayWidgetEntry`` captures a snapshot of airport conditions at a specific
/// time, including runway information and calculated takeoff distances.
///
/// ## Properties
///
/// - ``date``: When this entry is valid
/// - ``airportName``: Name of the selected airport
/// - ``runways``: Snapshot of runway data
/// - ``conditions``: Weather conditions used for calculations
/// - ``takeoffDistances``: Calculated takeoff distance for each runway
///
/// ## Empty State
///
/// Use ``empty()`` factory method when no airport is selected.
struct RunwayWidgetEntry: TimelineEntry, Sendable {
  /// When this timeline entry should be displayed.
  let date: Date

  /// Name of the selected airport, or nil if none selected.
  let airportName: String?

  /// Snapshot of runway data for display.
  let runways: [RunwaySnapshot]?

  /// Weather conditions used for performance calculations.
  let conditions: Conditions?

  /// Calculated takeoff distance for each runway, keyed by runway name.
  let takeoffDistances: [String: Value<Measurement<UnitLength>>]?

  /// Creates an empty entry for when no airport is selected.
  static func empty() -> Self {
    return .init(
      date: Date(),
      airportName: nil,
      runways: nil,
      conditions: nil,
      takeoffDistances: nil
    )
  }
}
