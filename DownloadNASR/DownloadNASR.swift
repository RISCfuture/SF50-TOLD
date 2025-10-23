import ArgumentParser
import Foundation
import Logging
import SwiftNASR
import SwiftTimeZoneLookup

@main
final class DownloadNASR: AsyncParsableCommand {
  @Option(
    name: .shortAndLong,
    help: "The cycle to download (use \"next\" for the next cycle). (default: current cycle)",
    transform: { value in
      guard let cycle = (value == "next") ? Cycle.current.next : stringToCycle(value) else {
        throw ValidationError("Invalid cycle")
      }
      return cycle
    }
  )
  var cycle = Cycle.current

  @Argument(
    help: "The location to write the plist files. (default: current directory)",
    transform: { .init(fileURLWithPath: $0) }
  )
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
    let logger = Logger(label: "codes.tim.SF50-TOLD.DownloadNASR")
    configureLogLevel()

    // Initialize timezone lookup database
    logger.notice("Initializing timezone lookup database…")
    let timezoneLookup = try SwiftTimeZoneLookup()

    // Load NASR data
    logger.notice("Loading NASR data for cycle \(cycle)…")
    let NASRAirports = try await loadNASRData(logger: logger, timezoneLookup: timezoneLookup)

    // Load OurAirports data
    logger.notice("Loading OurAirports data…")
    let ourAirportsLoader = OurAirportsLoader(logger: logger)
    let (ourAirports, ourAirportsLastUpdated) = try await ourAirportsLoader.loadAirports()

    // Merge and de-duplicate
    logger.notice("Merging and de-duplicating airport data…")
    let mergedAirports = mergeAirports(
      NASRAirports: NASRAirports,
      ourAirports: ourAirports,
      logger: logger,
      timezoneLookup: timezoneLookup
    )

    // Create codable data structure
    let codableData = AirportDataCodable(
      nasrCycle: cycle,
      ourAirportsLastUpdated: ourAirportsLastUpdated,
      airports: mergedAirports
    )

    logger.notice("Writing to file…")
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(codableData)
    try data.write(to: outputLocation.appendingPathComponent("\(cycle).plist"))

    logger.notice("Compressing…")
    // swiftlint:disable:next legacy_objc_type
    let compressedData = try NSData(data: data).compressed(using: .lzma)
    try compressedData.write(to: outputLocation.appendingPathComponent("\(cycle).plist.lzma"))

    logger.notice("Complete - processed \(mergedAirports.count) airports")
  }

  private func loadNASRData(logger: Logger, timezoneLookup: SwiftTimeZoneLookup) async throws
    -> [AirportDataCodable.AirportCodable]
  {
    let nasr = NASR(loader: ArchiveFileDownloader(cycle: cycle))
    logger.notice("Loading NASR archive…")
    try await nasr.load()
    logger.notice("Parsing NASR airports…")
    try await nasr.parse(.airports) { error in
      logger.error("Parse error", metadata: ["error": "\(error.localizedDescription)"])
      return true
    }

    let NASRData = await nasr.data
    guard let airports = await NASRData.airports else {
      return []
    }

    var codableAirports = [AirportDataCodable.AirportCodable]()

    for airport in airports {
      guard let elevationFt = airport.referencePoint.elevation else { continue }

      let latitudeSec = airport.referencePoint.latitude
      let longitudeSec = airport.referencePoint.longitude
      let variationDeg =
        airport.magneticVariation.map { Double($0) }
        ?? calculateMagneticVariation(Double(latitudeSec), Double(longitudeSec))

      var runways = [AirportDataCodable.RunwayCodable]()

      for runway in airport.runways {
        if runway.materials.contains(.water) { continue }
        guard let length = runway.length, length >= 500 else { continue }

        // Process base end
        if let baseRunway = makeRunwayCodable(
          runway: runway,
          end: runway.baseEnd,
          reciprocalName: runway.reciprocalEnd?.ID
        ) {
          runways.append(baseRunway)
        }

        // Process reciprocal end
        if let reciprocalEnd = runway.reciprocalEnd,
          let reciprocalRunway = makeRunwayCodable(
            runway: runway,
            end: reciprocalEnd,
            reciprocalName: runway.baseEnd.ID
          )
        {
          runways.append(reciprocalRunway)
        }
      }

      if runways.isEmpty { continue }

      // Lookup timezone for this airport
      let latitudeDeg = Double(latitudeSec) / 3600.0
      let longitudeDeg = Double(longitudeSec) / 3600.0
      let timeZone = timezoneLookup.simple(
        latitude: Float(latitudeDeg),
        longitude: Float(longitudeDeg)
      )

      let codableAirport = AirportDataCodable.AirportCodable(
        recordID: airport.id,
        locationID: airport.LID,
        ICAO_ID: airport.ICAOIdentifier,
        name: airport.name,
        city: airport.city,
        dataSource: "nasr",
        latitude: latitudeDeg,  // Convert arcseconds to degrees
        longitude: longitudeDeg,
        elevation: Double(elevationFt) * 0.3048,  // Convert feet to meters
        variation: variationDeg,
        timeZone: timeZone,
        runways: runways
      )

      codableAirports.append(codableAirport)
    }

    return codableAirports
  }

  private func makeRunwayCodable(
    runway: SwiftNASR.Runway,
    end: RunwayEnd,
    reciprocalName: String?
  ) -> AirportDataCodable.RunwayCodable? {
    guard let length = runway.length else { return nil }

    // Calculate true heading
    let trueHeading: Double
    if let existingHeading = end.trueHeading {
      trueHeading = Double(existingHeading)
    } else if let baseEndLat = runway.baseEnd.threshold?.latitude,
      let baseEndLon = runway.baseEnd.threshold?.longitude,
      let recipEndLat = runway.reciprocalEnd?.threshold?.latitude,
      let recipEndLon = runway.reciprocalEnd?.threshold?.longitude
    {
      // Calculate bearing for the current runway end
      if end.ID == runway.baseEnd.ID {
        trueHeading = Double(
          calculateBearing(from: (baseEndLat, baseEndLon), to: (recipEndLat, recipEndLon))
        )
      } else {
        trueHeading = Double(
          calculateBearing(from: (recipEndLat, recipEndLon), to: (baseEndLat, baseEndLon))
        )
      }
    } else if let reciprocal = runway.reciprocalEnd,
      let reciprocalHeading = reciprocal.trueHeading
    {
      let heading = (Int(reciprocalHeading) + 180) % 360
      trueHeading = Double(heading)
    } else {
      return nil
    }

    let elevationMeters = end.touchdownZoneElevation.map { Double($0) * 0.3048 }

    return AirportDataCodable.RunwayCodable(
      name: end.ID,
      elevation: elevationMeters,
      trueHeading: trueHeading,
      gradient: end.gradient.map { $0 / 100 },
      length: Double(length) * 0.3048,  // Convert feet to meters
      takeoffRun: end.TORA.map { Double($0) * 0.3048 },
      takeoffDistance: end.TODA.map { Double($0) * 0.3048 },
      landingDistance: end.LDA.map { Double($0) * 0.3048 },
      isTurf: !runway.isPaved,
      reciprocalName: reciprocalName
    )
  }

  private func mergeAirports(
    NASRAirports: [AirportDataCodable.AirportCodable],
    ourAirports: [OurAirportData],
    logger: Logger,
    timezoneLookup: SwiftTimeZoneLookup
  ) -> [AirportDataCodable.AirportCodable] {
    var mergedAirports = [AirportDataCodable.AirportCodable]()
    var NASRLocationIds = Set<String>()

    // Add all NASR airports first (they have priority)
    for airport in NASRAirports {
      mergedAirports.append(airport)
      NASRLocationIds.insert(airport.locationID)
    }

    // Add OurAirports data that doesn't exist in NASR
    var ourAirportsAdded = 0
    for ourAirport in ourAirports {
      // Skip if this airport's local_id matches a NASR locationID
      if !ourAirport.localId.isEmpty && NASRLocationIds.contains(ourAirport.localId) {
        continue
      }

      // Convert OurAirports data to our codable format
      var runways = [AirportDataCodable.RunwayCodable]()
      for runway in ourAirport.runways {
        let takeoffRun = runway.lengthFt - runway.displacedThresholdFt

        runways.append(
          AirportDataCodable.RunwayCodable(
            name: runway.name,
            elevation: runway.elevationFt.map { $0 * 0.3048 },  // Convert feet to meters
            trueHeading: runway.trueHeading,
            gradient: nil,  // OurAirports doesn't provide gradient
            length: runway.lengthFt * 0.3048,  // Convert feet to meters
            takeoffRun: takeoffRun > 0 ? takeoffRun * 0.3048 : nil,
            takeoffDistance: nil,  // Not available in OurAirports
            landingDistance: nil,  // Not available in OurAirports
            isTurf: runway.isTurf,
            reciprocalName: runway.reciprocalName
          )
        )
      }

      if runways.isEmpty { continue }

      // Calculate magnetic variation for this location
      let variation = calculateMagneticVariation(ourAirport.latitude, ourAirport.longitude)

      // Lookup timezone for this airport
      let timeZone = timezoneLookup.simple(
        latitude: Float(ourAirport.latitude),
        longitude: Float(ourAirport.longitude)
      )

      let codableAirport = AirportDataCodable.AirportCodable(
        recordID: ourAirport.id,
        locationID: ourAirport.localId,
        ICAO_ID: ourAirport.ICAO_ID,
        name: ourAirport.name,
        city: ourAirport.municipality,
        dataSource: "ourAirports",
        latitude: ourAirport.latitude,
        longitude: ourAirport.longitude,
        elevation: ourAirport.elevationFt * 0.3048,  // Convert feet to meters
        variation: variation,
        timeZone: timeZone,
        runways: runways
      )

      mergedAirports.append(codableAirport)
      ourAirportsAdded += 1
    }

    logger.notice("Added \(ourAirportsAdded) airports from OurAirports (non-duplicates)")
    logger.notice("Total airports after merge: \(mergedAirports.count)")

    return mergedAirports
  }

  private func calculateBearing(from: (Float, Float), to: (Float, Float)) -> Float {
    let lat1 = from.0 / 3600 * .pi / 180
    let lat2 = to.0 / 3600 * .pi / 180
    let deltaLon = (to.1 / 3600 - from.1 / 3600) * .pi / 180

    let x = sin(deltaLon) * cos(lat2)
    let y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLon)

    let bearing = atan2(x, y) * 180 / .pi
    return (bearing + 360).truncatingRemainder(dividingBy: 360)
  }

  private func calculateMagneticVariation(_ latitudeDeg: Double, _ longitudeDeg: Double) -> Double {
    let geomagnetism = Geomagnetism(longitude: longitudeDeg, latitude: latitudeDeg)
    return geomagnetism.declination
  }
}

private func stringToCycle(_ value: String) -> Cycle? {
  let components = value.split(separator: "-")
  guard components.count == 3 else { return nil }

  guard let year = UInt(components[0]),
    let month = UInt8(components[1]),
    let day = UInt8(components[2])
  else {
    return nil
  }

  return Cycle(year: year, month: month, day: day)
}
