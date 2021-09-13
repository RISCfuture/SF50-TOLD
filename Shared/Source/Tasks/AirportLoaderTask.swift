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
        let airportDataLoader = AirportDataLoader(container: persistentContainer)
        airportDataLoader.loadNASR { result in
            switch result {
                case .success(let cycle):
                    Defaults[.lastCycleLoaded] = cycle
                    task.setTaskCompleted(success: true)
                default:
                    task.setTaskCompleted(success: false)
            }
        }
    }
    
    static func submit() {
        let request = BGProcessingTaskRequest(identifier: identifier)
        try? BGTaskScheduler.shared.submit(request)
    }
}
