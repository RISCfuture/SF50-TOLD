import Foundation
import SF50_Shared
import WidgetKit

struct RunwayWidgetEntry: TimelineEntry {
  let date: Date
  let airport: Airport?
  let conditions: Conditions?
  let takeoffDistances: [String: Value<Measurement<UnitLength>>]?

  static func empty() -> Self {
    return .init(date: Date(), airport: nil, conditions: nil, takeoffDistances: nil)
  }
}
