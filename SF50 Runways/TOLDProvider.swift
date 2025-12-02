import Combine
import Defaults
import SwiftData
import SwiftUI
import WidgetKit

/// Timeline provider for the SF50 TOLD widget.
///
/// ``TOLDProvider`` supplies timeline entries containing runway performance data.
/// The timeline refreshes every 15 minutes to capture weather changes, with
/// immediate refresh available via `WidgetCenter.reloadTimelines` when settings change.
///
/// ## Timeline Behavior
///
/// - **Snapshot**: Returns current performance for quick preview
/// - **Timeline**: Returns entries with 15-minute refresh policy
/// - **Placeholder**: Shows empty state while loading
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
