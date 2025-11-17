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

  func getSnapshot(in context: Context, completion: @escaping @Sendable (RunwayWidgetEntry) -> Void)
  {
    let placeholderEntry = placeholder(in: context)
    Task { @MainActor in
      let entries = await performanceCalculator.generateEntries()
      guard let entry = entries.first else {
        completion(placeholderEntry)
        return
      }
      completion(entry)
    }
  }

  func getTimeline(
    in _: Context,
    completion: @escaping @Sendable (Timeline<RunwayWidgetEntry>) -> Void
  ) {
    Task { @MainActor in
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
