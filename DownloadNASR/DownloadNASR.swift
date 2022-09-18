import Foundation
import ArgumentParser
import OSLog
import SwiftNASR

@main
final class DownloadNASR: AsyncParsableCommand {
    @Option(name: .shortAndLong,
            help: "The cycle to download.",
            transform: { (value: String) -> Cycle in
        let components = value.split(separator: "-")
        guard components.count == 3 else {
            throw ValidationError("Invalid cycle")
        }
        guard let year = UInt(components[0]),
              let month = UInt8(components[1]),
              let day = UInt8(components[2]) else {
            throw ValidationError("Invalid cycle")
        }
        return Cycle(year: year, month: month, day: day)
    })
    var cycle = Cycle.current
    
    @Argument(help: "The location to write the plist files. (default: current directory)",
            transform: { URL(fileURLWithPath: $0) })
    var outputLocation = URL(fileURLWithPath: "")
    
    func validate() throws {
        guard cycle.year >= Cycle.datum.year else {
            throw ValidationError("Year must be on or after \(Cycle.datum.year)")
        }
        guard (1...12).contains(cycle.month) else {
            throw ValidationError("Invalid month")
        }
        guard (1...31).contains(cycle.day) else {
            throw ValidationError("Invalid day")
        }
    }
    
    func run() async throws {
        let logger = Logger(subsystem: "codes.tim.SF50-TOLD", category: "DownloadNASR")
        
        let nasr = NASR(loader: ArchiveDataDownloader(cycle: cycle))
        logger.info("Loading…")
        try await _ = nasr.load()
        logger.info("Parsing airports…")
        try await _ = nasr.parseAirports(errorHandler: {
            logger.error("Parse error: \($0.localizedDescription)")
            return true
        })
        
        logger.info("Writing to file…")
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(nasr.data)
        try data.write(to: outputLocation.appendingPathComponent("\(cycle).plist"))
        
        logger.info("Compressing…")
        let compressedData = try (data as NSData).compressed(using: .lzma)
        try compressedData.write(to: outputLocation.appendingPathComponent("\(cycle).plist.lzma"))
        
        logger.info("Complete")
    }
}