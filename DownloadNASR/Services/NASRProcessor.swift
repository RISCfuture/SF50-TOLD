import Foundation
import Logging
import SwiftNASR
import SwiftTimeZoneLookup

struct NASRProcessor {
  let cycle: Cycle
  let outputLocation: URL
  let logger: Logger
  let progress: Progress
  var onUploadError: (@MainActor @Sendable (_ error: Error) -> Void)?

  func process() async throws {
    // Create child progress objects for each major step
    // Total: 7 steps (timezone init, NASR load, OurAirports load, merge, write, compress, upload)
    progress.totalUnitCount = 7

    // Initialize timezone lookup database
    logger.notice("Initializing timezone lookup database…")
    progress.localizedDescription = "Initializing timezone lookup database…"
    let timezoneLookup = try SwiftTimeZoneLookup()
    progress.completedUnitCount = 1

    // Load NASR data
    logger.notice("Loading NASR data for cycle \(cycle)…")
    progress.localizedDescription = "Loading NASR data…"
    let nasrProgress = Progress(totalUnitCount: 100, parent: progress, pendingUnitCount: 1)
    let NASRAirports = try await loadNASRData(
      timezoneLookup: timezoneLookup,
      progress: nasrProgress
    )

    // Load OurAirports data
    logger.notice("Loading OurAirports data…")
    progress.localizedDescription = "Loading OurAirports data…"
    let ourAirportsProgress = Progress(totalUnitCount: 100, parent: progress, pendingUnitCount: 1)
    let ourAirportsLoader = OurAirportsLoader(logger: logger, progress: ourAirportsProgress)
    let (ourAirports, ourAirportsLastUpdated) = try await ourAirportsLoader.loadAirports()

    // Merge and de-duplicate
    logger.notice("Merging and de-duplicating airport data…")
    progress.localizedDescription = "Merging and de-duplicating airport data…"
    let mergedAirports = mergeAirports(
      NASRAirports: NASRAirports,
      ourAirports: ourAirports,
      timezoneLookup: timezoneLookup
    )
    progress.completedUnitCount = 4

    // Create codable data structure
    let codableData = AirportDataCodable(
      nasrCycle: cycle,
      ourAirportsLastUpdated: ourAirportsLastUpdated,
      airports: mergedAirports
    )

    logger.notice("Writing to file…")
    progress.localizedDescription = "Writing to file…"
    let encoder = PropertyListEncoder()
    encoder.outputFormat = .binary
    let data = try encoder.encode(codableData)
    try data.write(to: outputLocation.appendingPathComponent("\(cycle).plist"))
    progress.completedUnitCount = 5

    logger.notice("Compressing…")
    progress.localizedDescription = "Compressing…"
    // swiftlint:disable:next legacy_objc_type
    let compressedData = try NSData(data: data).compressed(using: .lzma)
    let lzmaFile = outputLocation.appendingPathComponent("\(cycle).plist.lzma")
    try compressedData.write(to: lzmaFile)
    progress.completedUnitCount = 6

    // Upload to GitHub if token is configured
    if let token = try? KeychainManager.shared.getToken(), !token.isEmpty {
      logger.notice("Uploading to GitHub…")
      progress.localizedDescription = "Uploading to GitHub…"

      do {
        let uploader = GitHubUploader(token: token)
        let targetPath = "3.0/\(cycle).plist.lzma"
        try await uploader.uploadFile(
          filePath: lzmaFile,
          targetPath: targetPath,
          commitMessage: "Update airport data for cycle \(cycle)"
        )
        logger.notice("Successfully uploaded to GitHub")
      } catch {
        // Don't fail the entire process if upload fails
        logger.warning("GitHub upload failed: \(error.localizedDescription)")
        if let onUploadError, let error = error as? Error {
          onUploadError(error)
        }
      }
    } else {
      logger.info("GitHub token not configured, skipping upload")
    }
    progress.completedUnitCount = 7

    logger.notice("Complete - processed \(mergedAirports.count) airports")
    progress.localizedDescription = "Complete!"
  }

  private func loadNASRData(timezoneLookup: SwiftTimeZoneLookup, progress: Progress) async throws
    -> [AirportDataCodable.AirportCodable]
  {
    progress.totalUnitCount = 2

    let nasr = NASR(loader: ArchiveFileDownloader(cycle: cycle))
    logger.notice("Loading NASR archive…")
    progress.localizedDescription = "Loading NASR archive…"
    try await nasr.load()
    progress.completedUnitCount = 1

    logger.notice("Parsing NASR airports…")
    progress.localizedDescription = "Parsing NASR airports…"
    try await nasr.parse(.airports) { error in
      var metadata: Logger.Metadata = ["error": "\(error.localizedDescription)"]

      // Add additional localized error information if available
      if let localizedError = error as? LocalizedError {
        if let errorDescription = localizedError.errorDescription {
          metadata["errorDescription"] = "\(errorDescription)"
        }
        if let failureReason = localizedError.failureReason {
          metadata["failureReason"] = "\(failureReason)"
        }
        if let recoverySuggestion = localizedError.recoverySuggestion {
          metadata["recoverySuggestion"] = "\(recoverySuggestion)"
        }
      }

      logger.error("Parse error", metadata: metadata)
      return true
    }
    progress.completedUnitCount = 2

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
