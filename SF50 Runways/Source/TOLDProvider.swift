import Combine
import CoreData
import Defaults
import SwiftMETAR
import SwiftUI
import WidgetKit

struct TOLDProvider: TimelineProvider {
    private let performanceCalculator: PerformanceCalculator
    private var managedObjectContext: NSManagedObjectContext

    init(managedObjectContext: NSManagedObjectContext) {
        self.performanceCalculator = PerformanceCalculator()
        self.managedObjectContext = managedObjectContext
    }

    func placeholder(in _: Context) -> RunwayWidgetEntry { .empty() }

    func getSnapshot(in context: Context, completion: @escaping (RunwayWidgetEntry) -> Void) {
//        if context.isPreview {
//            completion(placeholder(in: context))
//            return
//        }

        performanceCalculator.generateEntries { entries in
            guard let entry = entries.first else {
                completion(placeholder(in: context))
                return
            }
            completion(entry)
        }
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<RunwayWidgetEntry>) -> Void) {
        performanceCalculator.generateEntries { entries in
            completion(.init(entries: entries,
                             policy: .after(Date().addingTimeInterval(1800))))
        }
    }
}
