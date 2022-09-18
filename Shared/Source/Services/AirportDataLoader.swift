import Foundation
import CoreData
import OSLog
import SwiftNASR

class AirportDataLoader: ObservableObject {
    @Published private(set) var error: Error? = nil
    
    @Published private(set) var downloadProgress = StepProgress.pending
    @Published private(set) var decompressProgress = StepProgress.pending
    @Published private(set) var processingProgress = StepProgress.pending
    
    private let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "AirportDataLoader")
    private let queue = DispatchQueue(label: "SF50-TOLD.AirportService", qos: .background)
    
    private var dataURL: URL {
        URL(string: "https://github.com/RISCfuture/SF50-TOLD-Airports/blob/main/\(Cycle.current).plist.lzma?raw=true")!
    }
    private let decoder = PropertyListDecoder()
    
    func loadNASR() async throws -> Cycle? {
        DispatchQueue.main.async {
            self.downloadProgress = .indeterminate
            self.decompressProgress = .pending
            self.processingProgress = .pending
        }
        
        let session = URLSession(configuration: .ephemeral)
        let (bytes, response) = try await session.bytes(from: self.dataURL)
        guard let response = response as? HTTPURLResponse else { throw Error.badResponse(response) }
        guard response.statusCode == 200 else { throw Error.badResponse(response) }
        DispatchQueue.main.async { self.downloadProgress = .inProgress(current: 0, total: UInt64(response.expectedContentLength)) }
        
        var compressedData = Data(capacity: Int(response.expectedContentLength))
        for try await byte in bytes {
            compressedData.append(byte)
            let completed = compressedData.count
            if completed % 8192 == 0 {
                DispatchQueue.main.async {
                    self.downloadProgress = .inProgress(current: UInt64(completed),
                                                        total: UInt64(response.expectedContentLength))
                }
            }
        }
        
        DispatchQueue.main.async {
            self.downloadProgress = .complete
            self.decompressProgress = .indeterminate
        }
        
        let data = try (compressedData as NSData).decompressed(using: .lzma)
        let nasr = try decoder.decode(NASRData.self, from: data as Data)
        
        DispatchQueue.main.async {
            self.decompressProgress = .complete
            self.processingProgress = .indeterminate
        }
        
        try await loadAirports(nasr)
        DispatchQueue.main.async { self.processingProgress = .complete }
        
        return nasr.cycle
    }
    
    private func loadAirports(_ data: NASRData) async throws {
        let context = PersistentContainer.shared.newBackgroundContext()
        try await deleteExistingAirports(context: context)
        await addNewAirportsFrom(data, context: context)
        try await context.perform { try context.save() }
    }
    
    private func deleteExistingAirports(context: NSManagedObjectContext) async throws {
        try await PersistentContainer.shared.persistentStoreCoordinator.perform {
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Airport")
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
            try context.execute(deleteRequest)
        }
    }
    
    private func addNewAirportsFrom(_ data: NASRData, context: NSManagedObjectContext) async {
        DispatchQueue.main.async {
            self.processingProgress = .inProgress(current: 0, total: UInt64(data.airports!.count))
        }
        
        await context.perform {
            for (index, airport) in data.airports!.enumerated() {
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
                
                DispatchQueue.main.async {
                    self.processingProgress = .inProgress(current: UInt64(index + 1), total: UInt64(data.airports!.count))
                }
            }
        }
    }
    
    private func configureRecord(_ record: inout Airport, from airport: SwiftNASR.Airport) {
        record.id = airport.id
        record.city = airport.city
        record.icao = airport.ICAOIdentifier
        record.lid = airport.LID
        record.name = airport.name
        record.latitude = Double(airport.referencePoint.latitude/3600)
        record.longitude = Double(airport.referencePoint.longitude/3600)
        record.elevation = airport.referencePoint.elevation ?? 0
        record.longestRunway = Int16(airport.runways.filter { $0.isPaved }.max { $0.length ?? 0 < $1.length ?? 0 }?.length ?? 0)
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
