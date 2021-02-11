import Foundation
import ArgumentParser
import Logging
import SwiftNASR

@main
final class DownloadNASR: AsyncParsableCommand {
    @Option(name: .shortAndLong,
            help: "The cycle to download (use “next” for the next cycle). (default: current cycle)",
            transform: { (value: String) -> Cycle in
        guard let cycle = (value == "next") ? Cycle.current.next : stringToCycle(value) else {
            throw ValidationError("Invalid cycle")
        }
        return cycle
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
        let logger = Logger(label: "codes.tim.SR22-G2-TOLD.DownloadNASR")
        configureLogLevel()
        
        let nasr = NASR(loader: ArchiveDataDownloader(cycle: cycle))
        logger.notice("Loading…")
        try await _ = nasr.load()
        logger.notice("Parsing airports…")
        try await _ = nasr.parseAirports(errorHandler: {
            logger.error("Parse error", metadata: ["error": "\($0.localizedDescription)"])
            return true
        })
        
        logger.notice("Writing to file…")
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .binary
        let data = try encoder.encode(nasr.data)
        try data.write(to: outputLocation.appendingPathComponent("\(cycle).plist"))
        
        logger.notice("Compressing…")
        let compressedData = try (data as NSData).compressed(using: .lzma)
        try compressedData.write(to: outputLocation.appendingPathComponent("\(cycle).plist.lzma"))
        
        logger.notice("Complete")
    }
}

fileprivate func stringToCycle(_ value: String) -> Cycle? {
    let components = value.split(separator: "-")
    guard components.count == 3 else { return nil }
    
    guard let year = UInt(components[0]),
          let month = UInt8(components[1]),
          let day = UInt8(components[2]) else {
        return nil
    }
    
    return Cycle(year: year, month: month, day: day)
}
