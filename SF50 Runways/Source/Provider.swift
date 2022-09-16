import SwiftUI
import WidgetKit
import Combine
import CoreData
import Defaults
import SwiftMETAR

struct Provider: TimelineProvider {
    private let performanceCalculator: PerformanceCalculator
    private var managedObjectContext: NSManagedObjectContext
    
    init(airport: AirportSelection, managedObjectContext: NSManagedObjectContext) {
        self.performanceCalculator = PerformanceCalculator(airport: airport)
        self.managedObjectContext = managedObjectContext
    }
    
    func placeholder(in context: Context) -> RunwayWidgetEntry {
        RunwayWidgetEntry(date: Date(),
                          airport: nil,
                          weather: nil,
                          takeoffDistances: [:])
    }
    
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
                             policy: .atEnd))
        }
    }
}
