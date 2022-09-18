import Foundation
import BackgroundTasks
import CoreData
import Defaults

class AirportLoaderTask {
    private static let identifier = "codes.tim.TOLD.AirportDataLoader.task"
    private let persistentContainer: NSPersistentContainer
    
    init(persistentContainer: NSPersistentContainer) {
        self.persistentContainer = persistentContainer
    }
    
    static func register(persistentContainer: NSPersistentContainer) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            AirportLoaderTask(persistentContainer: persistentContainer).run(task: task)
        }
    }
    
    func run(task: BGTask) {
        Task(priority: .background) {
            let airportDataLoader = AirportDataLoader()
            do {
                let cycle = try await airportDataLoader.loadNASR()
                Defaults[.lastCycleLoaded] = cycle
                Defaults[.schemaVersion] = latestSchemaVersion
                task.setTaskCompleted(success: true)
            } catch (_) {
                task.setTaskCompleted(success: false)
            }
        }
    }
    
    static func submit() {
        let request = BGProcessingTaskRequest(identifier: identifier)
        try? BGTaskScheduler.shared.submit(request)
    }
}
