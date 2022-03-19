import Foundation
import CoreData
import OSLog
import SwiftNASR

class AirportDataLoader: ObservableObject {
    @Published private(set) var error: Swift.Error? = nil
    
    private let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "AirportDataLoader")
    private let queue = DispatchQueue(label: "SF50-Told.AirportService", qos: .background)
    
    private var loader = BackgroundDownloader()
    
    func loadNASR(withProgress progressHandler: (Progress) -> Void) async throws -> Cycle? {
        let nasr = NASR(loader: loader)
        let progress = Progress(totalUnitCount: 100)
        progressHandler(progress)
        
        let _ = try await nasr.load(withProgress: { progress.addChild($0, withPendingUnitCount: 25) })
        logger.info("NASR data loaded from remote")
        
        let _ = try await nasr.parseAirports(withProgress: {
            progress.addChild($0, withPendingUnitCount: 25)
        }, errorHandler: { error in
            self.logger.error("Couldn't parse airport: \(error.localizedDescription)")
            return true
        })
        try await loadAirports(nasr.data, progress: progress)
        return nasr.data.cycle
    }
    
    private func loadAirports(_ data: NASRData, progress: Progress) async throws {
        let context = PersistentContainer.shared.newBackgroundContext()
        try await deleteExistingAirports(context: context)
        await addNewAirportsFrom(data, context: context, progress: progress)
        try await context.perform { try context.save() }
    }
    
    private func deleteExistingAirports(context: NSManagedObjectContext) async throws {
        try await PersistentContainer.shared.persistentStoreCoordinator.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Airport")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
        }
    }
    
    private func addNewAirportsFrom(_ data: NASRData, context: NSManagedObjectContext, progress: Progress) async {
        let childProgress = Progress(totalUnitCount: Int64(data.airports!.count), parent: progress, pendingUnitCount: 50)
        
        await context.perform {
            for airport in data.airports! {
                var airportRecord = Airport(context: context)
                self.configureRecord(&airportRecord, from: airport)
                
                for runway in airport.runways {
                    var baseEndRecord = Runway(context: context)
                    guard self.configureRecord(&baseEndRecord, from: runway, end: runway.baseEnd, airport: airport) else {
                        context.delete(baseEndRecord)
                        continue
                    }
                    baseEndRecord.airport = airportRecord
                    airportRecord.addToRunways(baseEndRecord)
                    
                    if let reciprocalEnd = runway.reciprocalEnd {
                        var reciprocalEndRecord = Runway(context: context)
                        guard self.configureRecord(&reciprocalEndRecord, from: runway, end: reciprocalEnd, airport: airport) else {
                            context.delete(reciprocalEndRecord)
                            continue
                        }
                        reciprocalEndRecord.airport = airportRecord
                        airportRecord.addToRunways(reciprocalEndRecord)
                    }
                }
                
                if airportRecord.runways?.count == 0 { context.delete(airportRecord) }
                childProgress.completedUnitCount += 1
            }
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
        guard let heading = bestGuessTrueHeading(end: end, airport: airport) else { return false }
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
    
    private func bestGuessTrueHeading(end: SwiftNASR.RunwayEnd, airport: SwiftNASR.Airport) -> UInt? {
        if let th = end.trueHeading { return th }
        guard let mv = airport.magneticVariation else { return nil }
        guard let IDNum = Int(end.ID) else { return nil }
        
        var dir = IDNum*10 + mv
        while (dir < 0)  { dir += 360 }
        while (dir > 360) { dir -= 360 }
        
        return UInt(dir)
    }
}
