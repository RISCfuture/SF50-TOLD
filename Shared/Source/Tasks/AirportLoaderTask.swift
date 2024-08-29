import Foundation
import BackgroundTasks
import Defaults
import SwiftData

class AirportLoaderTask {
    private static let identifier = "codes.tim.TOLD.AirportDataLoader.task"
    private let modelContainer: ModelContainer
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    static func register(modelContainer: ModelContainer) {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            AirportLoaderTask(modelContainer: modelContainer).run(task: task)
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
