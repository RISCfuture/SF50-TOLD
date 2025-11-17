import Foundation
import SF50_Shared
import WidgetKit

struct RunwayWidgetEntry: TimelineEntry, Sendable {
  let date: Date
  let airportName: String?
  let runways: [RunwaySnapshot]?
  let conditions: Conditions?
  let takeoffDistances: [String: Value<Measurement<UnitLength>>]?

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
