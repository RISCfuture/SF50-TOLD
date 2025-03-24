import CoreData

final class PersistentContainer: ObservableObject {
    static let shared = PersistentContainer.init()
    let container: NSPersistentContainer
    
    @Published private(set) var error: Swift.Error?
    
    var viewContext: NSManagedObjectContext { container.viewContext }
    var persistentStoreCoordinator: NSPersistentStoreCoordinator { container.persistentStoreCoordinator }
    
    private init() {
        container = NSPersistentContainer(name: "Airports")
        
        guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.codes.tim.TOLD") else {
            fatalError("Shared file container couild not be created.")
        }
        let storeURL = containerURL.appendingPathComponent("Airports.sqlite")
        
        container.persistentStoreDescriptions = [NSPersistentStoreDescription(url: storeURL)]
        container.loadPersistentStores { description, error in
            if let error {
                fatalError("Unable to load persistent stores: \(error)")
            }
        }
    }
    
    func saveContext() {
        error = nil
        if viewContext.hasChanges {
            do {
                try viewContext.save()
            } catch {
                self.error = DataDownloadError.unknown(error: error)
            }
        }
    }
    
    func newBackgroundContext() -> NSManagedObjectContext {
        container.newBackgroundContext()
    }
}
