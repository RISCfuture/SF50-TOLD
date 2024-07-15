import SwiftUI
import WidgetKit
import Combine
import CoreData
import Defaults
import SwiftMETAR

struct TOLDProvider: TimelineProvider {
    private let performanceCalculator: PerformanceCalculator
    private var managedObjectContext: NSManagedObjectContext
    
    init(managedObjectContext: NSManagedObjectContext) {
        self.performanceCalculator = PerformanceCalculator()
        self.managedObjectContext = managedObjectContext
    }
    
    func placeholder(in context: Context) -> RunwayWidgetEntry { .empty() }
    
    func getSnapshot(in context: Context, completion: @escaping (RunwayWidgetEntry) -> ()) {
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
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RunwayWidgetEntry>) -> ()) {
        performanceCalculator.generateEntries { entries in
            completion(.init(entries: entries,
                             policy: .after(Date().addingTimeInterval(1800))))
        }
    }
}
