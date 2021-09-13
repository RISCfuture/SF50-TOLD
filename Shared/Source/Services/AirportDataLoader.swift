import Foundation
import CoreData
import OSLog
import UIKit
import SwiftNASR

class AirportDataLoader: ObservableObject {
    private let persistentContainer: NSPersistentContainer
    @Published private(set) var progress: Progress? = nil
    @Published private(set) var error: Swift.Error? = nil
    
    private let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "AirportDataLoader")
    private let queue = DispatchQueue(label: "SF50-Told.AirportService", qos: .background)
    
    private var loader = BackgroundDownloader()
    
    required init(container: NSPersistentContainer) {
        persistentContainer = container
        ConcurrentDistribution.progressQueue = DispatchQueue.main
    }
    
    func loadNASR(callback: @escaping (Result<Cycle?, Swift.Error>) -> Void) {
        let progress = Progress(totalUnitCount: 10)
        DispatchQueue.main.async { self.progress = progress }
        
        queue.async {
            let nasr = NASR(loader: self.loader)
            
            let loadProgress = nasr.load { result in
                switch result {
                    case .success:
                        self.queue.async {
                            do {
                                self.logger.info("NASR data loaded from remote")
                                try nasr.parse(.airports, progressHandler: { progress.addChild($0, identifier: "parseAirports", pendingUnitCount: 7) }) { error in
                                    self.logger.error("Couldn't parse airport: \(error.localizedDescription)")
                                    return true
                                }
                                self.logger.info("NASR airports parsed")
                                try self.loadAirports(nasr.data, progress: progress)
                                self.logger.info("NASR airports loaded")
                                DispatchQueue.main.async { self.progress = nil }
                                callback(.success(nasr.data.cycle))
                            } catch (let error) {
                                self.logger.error("Couldn't parse airports: \(error.localizedDescription)")
                                DispatchQueue.main.async { self.error = error }
                                callback(.failure(error))
                            }
                        }
                    case .failure(let error):
                        self.logger.error("Couldn't load remote NASR data: \(error.localizedDescription)")
                        DispatchQueue.main.async { self.error = error }
                        callback(.failure(error))
                }
            }
            progress.addChild(loadProgress, identifier: "loadProgress", pendingUnitCount: 2)
        }
    }
    
    private func loadAirports(_ data: NASRData, progress: Progress) throws {
        let context = persistentContainer.newBackgroundContext()
        try deleteExistingAirports(context: context)
        try addNewAirportsFrom(data, context: context, progress: progress)
        try context.save()
    }
    
    private func deleteExistingAirports(context: NSManagedObjectContext) throws {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Airport")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        try persistentContainer.persistentStoreCoordinator.execute(deleteRequest, with: context)
    }
    
    private func addNewAirportsFrom(_ data: NASRData, context: NSManagedObjectContext, progress: Progress) throws {
        progress.addChild(identifier: "addRecords", totalUnitCount: Int64(data.airports!.count), pendingUnitCount: 1)
        
        for airport in data.airports! {
            var airportRecord = Airport(entity: Airport.entity(), insertInto: context)
            configureRecord(&airportRecord, from: airport)
            
            for runway in airport.runways {
                var baseEndRecord = Runway(entity: Runway.entity(), insertInto: context)
                guard configureRecord(&baseEndRecord, from: runway, end: runway.baseEnd, airport: airport) else {
                    context.delete(baseEndRecord)
                    continue
                }
                baseEndRecord.airport = airportRecord
                airportRecord.addToRunways(baseEndRecord)
                
                if let reciprocalEnd = runway.reciprocalEnd {
                    var reciprocalEndRecord = Runway(entity: Runway.entity(), insertInto: context)
                    guard configureRecord(&reciprocalEndRecord, from: runway, end: reciprocalEnd, airport: airport) else {
                        context.delete(reciprocalEndRecord)
                        continue
                    }
                    reciprocalEndRecord.airport = airportRecord
                    airportRecord.addToRunways(reciprocalEndRecord)
                }
            }
            
            if airportRecord.runways?.count == 0 { context.delete(airportRecord) }
            progress.increment("addRecords")
        }
    }
    
    private func configureRecord(_ record: inout Airport, from airport: SwiftNASR.Airport) {
        record.id = airport.id
        record.city = airport.city
        record.icao = airport.ICAOIdentifier
        record.lid = airport.LID
        record.name = airport.name
        record.elevation = airport.referencePoint.elevation ?? 0
        record.longestRunway = Int16(airport.runways.max { $0.length ?? 0 < $1.length ?? 0 }?.length ?? 0)
    }
    
    private func configureRecord(_ record: inout Runway, from runway: SwiftNASR.Runway, end: SwiftNASR.RunwayEnd, airport: SwiftNASR.Airport) -> Bool {
        guard let elevation = end.touchdownZoneElevation ?? airport.referencePoint.elevation else { return false }
        guard let heading = end.trueHeading else { return false }
        guard let LDA = end.LDA ?? runway.length else { return false }
        guard let TODA = end.TODA ?? runway.length else { return false }
        guard let TORA = end.TORA ?? runway.length else { return false }
        
        record.name = end.ID
        record.elevation = elevation
        record.heading = Int16(heading)
        record.landingDistance = Int16(LDA)
        record.slope = NSDecimalNumber(floatLiteral: Double(end.gradient ?? 0))
        record.takeoffDistance = Int16(TODA)
        record.takeoffRun = Int16(TORA)
        record.turf = !runway.isPaved
        
        return true
    }
}
