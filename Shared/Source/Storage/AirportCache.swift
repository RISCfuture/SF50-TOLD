import Foundation
import CoreData
import Dispatch

fileprivate let cacheSize = UInt(100)

class ManagedObjectCache<T: NSManagedObject> where T: Identifiable {
    private let cache = LRUCache<T>(size: cacheSize)
    private let context: NSManagedObjectContext
    private let mutex = DispatchSemaphore(value: 1)
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func fetch(ids: Set<T.ID>) throws -> Array<T> {
        mutex.wait()
        
        let idsToLoad = ids.filter { !cache.contains($0) }
        let request = fetchRequestFor(ids: idsToLoad)
        let newRecords = try context.fetch(request)
        for record in newRecords {
            cache.add(record)
        }
        let fetchedRecords = ids.map { cache[$0]! }
        
        mutex.signal()
        
        return fetchedRecords
    }
    
    func fetch(_ id: T.ID) throws -> T? {
        return try fetch(ids: [id]).first
    }
    
    func fetch(_ request: NSFetchRequest<T>) throws -> Array<T> {
        request.propertiesToFetch = ["id"]
        let ids = try context.fetch(request).map { $0.id }
        let records = try fetch(ids: Set(ids))
        return ids.map { id in records.first { r in r.id == id}! }
    }
    
    private func fetchRequestFor(ids: Set<T.ID>) -> NSFetchRequest<T> {
        let request = NSFetchRequest<T>(entityName: T.entity().name!)
        request.predicate = NSPredicate(format: "id IN %@", ids)
        request.includesPropertyValues = true
        request.includesSubentities = true
        request.returnsObjectsAsFaults = false
        return request
    }
}
