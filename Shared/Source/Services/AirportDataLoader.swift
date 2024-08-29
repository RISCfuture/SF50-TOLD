import Foundation
import Logging
import SwiftData
import SwiftNASR
import Combine

actor AirportDataLoader {
    private let modelContext: ModelContext
    private(set) var error: DataDownloadError? = nil
    private(set) var downloadProgress = StepProgress.pending
    private(set) var decompressProgress = StepProgress.pending
    private(set) var processingProgress = StepProgress.pending
    
    private let logger = Logger(label: "codes.tim.SF50-TOLD.AirportDataLoader")
    
    private var dataURL: URL {
        URL(string: "https://github.com/RISCfuture/SF50-TOLD-Airports/blob/main/\(Cycle.current).plist.lzma?raw=true")!
    }
    private let decoder = PropertyListDecoder()
    
    init(modelContainer: ModelContainer) {
        self.modelContext = ModelContext(modelContainer)
    }
    
    func loadNASR() async throws -> Cycle? {
        logger.debug("loadNASR(): starting")
        
        self.downloadProgress = .indeterminate
        self.decompressProgress = .pending
        self.processingProgress = .pending
        
        let session = URLSession(configuration: .ephemeral)
        let (bytes, response) = try await session.bytes(from: self.dataURL)
        guard let response = response as? HTTPURLResponse else { throw DataDownloadError.badResponse(response) }
        guard response.statusCode == 200 else { throw DataDownloadError.badResponse(response) }
        self.downloadProgress = .inProgress(current: 0, total: UInt64(response.expectedContentLength))
        
        var compressedData = Data(capacity: Int(response.expectedContentLength))
        for try await byte in bytes {
            compressedData.append(byte)
            let completed = compressedData.count
            if completed % 8192 == 0 {
                self.downloadProgress = .inProgress(current: UInt64(completed),
                                                    total: UInt64(response.expectedContentLength))
            }
        }
        
        logger.debug("loadNASR(): decompressing")
        self.downloadProgress = .complete
        self.decompressProgress = .indeterminate
        
        let data = try (compressedData as NSData).decompressed(using: .lzma)
        let nasr = try decoder.decode(NASRData.self, from: data as Data)
        
        logger.debug("loadNASR(): loading")
        self.decompressProgress = .complete
        self.processingProgress = .indeterminate
        
        try await loadAirports(nasr)
        
        logger.debug("loadNASR(): complete")
        self.processingProgress = .complete
        
        return nasr.cycle
    }
    
    private func loadAirports(_ data: NASRData) async throws {
        try await deleteExistingAirports(context: modelContext)
        await addNewAirportsFrom(data, context: modelContext)
        try modelContext.save()
    }
    
    private func deleteExistingAirports(context: ModelContext) async throws {
        try context.delete(model: Airport.self)
    }
    
    private func addNewAirportsFrom(_ data: NASRData, context: ModelContext) async {
        self.processingProgress = .inProgress(current: 0, total: UInt64(data.airports!.count))
        
        for (index, airport) in data.airports!.enumerated() {
            let airportRecord = self.configureRecord(from: airport)
            
            for runway in airport.runways {
                guard self.configureRecord(from: runway, end: runway.baseEnd, airport: airport, airportRecord: airportRecord) != nil else {
                    continue
                }
                
                if let reciprocalEnd = runway.reciprocalEnd {
                    guard self.configureRecord(from: runway, end: reciprocalEnd, airport: airport, airportRecord: airportRecord) != nil else {
                        continue
                    }
                }
            }
            
            if airportRecord.runways.count == 0 { context.delete(airportRecord) }
            
            self.processingProgress = .inProgress(current: UInt64(index + 1), total: UInt64(data.airports!.count))
        }
    }
    
    private func configureRecord(from airport: SwiftNASR.Airport) -> Airport {
        return .init(id: airport.id,
                     icao: airport.ICAOIdentifier,
                     lid: airport.LID,
                     name: airport.name,
                     elevation: Double(airport.referencePoint.elevation ?? 0),
                     city: airport.city,
                     latitude: Double(airport.referencePoint.latitude/3600),
                     longitude: Double(airport.referencePoint.longitude/3600))
    }
    
    private func configureRecord(from runway: SwiftNASR.Runway, end: SwiftNASR.RunwayEnd, airport: SwiftNASR.Airport, airportRecord: Airport) -> Runway? {
        guard let elevation = end.touchdownZoneElevation ?? airport.referencePoint.elevation else { return nil }
        guard let heading = bestGuessTrueHeading(end: end, airport: airport) else { return nil }
        guard let LDA = end.LDA ?? runway.length else { return nil }
        guard let TODA = end.TODA ?? runway.length else { return nil }
        guard let TORA = end.TORA ?? runway.length else { return nil }
        
        let gradient = end.gradient ?? {
            guard let estimatedGradient = runway.estimatedGradient else { return nil }
            return (runway.baseEnd.ID == end.ID) ? estimatedGradient : -estimatedGradient
        }() ?? 0
        
        return Runway(airport: airportRecord,
                      name: end.ID,
                      turf: !runway.isPaved,
                      elevation: Double(elevation),
                      heading: UInt8(heading),
                      slope: gradient,
                      landingDistance: LDA,
                      takeoffDistance: TODA,
                      takeoffRun: TORA)
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
