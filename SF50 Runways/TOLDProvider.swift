import Combine
import Defaults
import SwiftData
import SwiftUI
import WidgetKit

struct TOLDProvider: TimelineProvider {
  private let performanceCalculator: PerformanceCalculator

  @MainActor
  init() {
    self.performanceCalculator = PerformanceCalculator()
  }

  func placeholder(in _: Context) -> RunwayWidgetEntry { .empty() }

  func getSnapshot(in context: Context, completion: @escaping (RunwayWidgetEntry) -> Void) {
    Task {
      let entries = await performanceCalculator.generateEntries()
      guard let entry = entries.first else {
        completion(placeholder(in: context))
        return
      }
      completion(entry)
    }
  }

  func getTimeline(in _: Context, completion: @escaping (Timeline<RunwayWidgetEntry>) -> Void) {
    Task {
      let entries = await performanceCalculator.generateEntries()
      // Refresh every 15 minutes for weather updates
      // Settings changes will trigger immediate refresh via WidgetCenter.reloadTimelines
      completion(
        .init(
          entries: entries,
          policy: .after(Date().addingTimeInterval(900))
        )
      )
    }
  }
}
