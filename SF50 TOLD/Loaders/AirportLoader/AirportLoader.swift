import Foundation
import Observation
import SF50_Shared
import SwiftData
import SwiftNASR

/**
 * Downloads and imports airport data from the GitHub repository.
 *
 * ``AirportLoader`` is a `@ModelActor` that handles the complete airport data
 * update pipeline:
 *
 * 1. **Download**: Fetches compressed airport data from GitHub
 * 2. **Decompress**: Extracts LZMA-compressed property list
 * 3. **Import**: Populates SwiftData with `Airport` and `Runway` models
 *
 * ## Data Source
 *
 * Airport data is pre-processed and hosted at:
 * `github.com/RISCfuture/SF50-TOLD-Airports`
 *
 * The data combines FAA NASR (National Airspace System Resources) with
 * OurAirports for international coverage.
 *
 * ## Progress Tracking
 *
 * Monitor the ``state`` property to track loading progress:
 *
 * ```swift
 * let loader = AirportLoader(modelContainer: container)
 * Task {
 *     while true {
 *         print(await loader.state)
 *         try? await Task.sleep(for: .seconds(0.25))
 *     }
 * }
 * let (cycle, lastUpdated) = try await loader.load()
 * ```
 *
 * ## See Also
 *
 * - ``AirportLoaderViewModel``
 * - ``State``
 */
@ModelActor
actor AirportLoader {
  var state: State = .idle

  private let decoder = PropertyListDecoder()

  private var dataURL: URL {
    URL(
      string:
        "https://github.com/RISCfuture/SF50-TOLD-Airports/blob/main/3.0/\(Cycle.current).plist.lzma?raw=true"
    )!
  }

  func load() async throws -> (cycle: Cycle?, lastUpdated: Date?) {
    state = .idle
    defer { state = .finished }

    let data = try await download()
    let nasr = try decompress(data: data)
    let (cycle, lastUpdated) = try await loadAirports(nasr: nasr)

    return (cycle, lastUpdated)
  }

  private func download() async throws -> Data {
    state = .downloading(progress: 0)
    defer { state = .downloading(progress: 1) }

    let session = URLSession(configuration: .ephemeral)
    let (bytes, response) = try await session.bytes(from: self.dataURL)
    guard let response = response as? HTTPURLResponse else { throw Errors.badResponse(response) }
    if response.statusCode == 404 { throw Errors.cycleNotAvailable }
    guard response.statusCode == 200 else { throw Errors.badResponse(response) }

    var compressedData = Data(capacity: Int(response.expectedContentLength))
    for try await byte in bytes {
      compressedData.append(byte)
      let completed = compressedData.count
      if completed.isMultiple(of: 8192) {
        let progress = Double(completed) / Double(response.expectedContentLength)
        state = .downloading(progress: Float(progress))
      }
    }

    return compressedData
  }

  private func decompress(data: Data) throws -> AirportDataCodable {
    state = .extracting(progress: nil)
    defer { state = .extracting(progress: 1) }

    let data = try (data as NSData).decompressed(using: .lzma)  // swiftlint:disable:this legacy_objc_type
    return try decoder.decode(AirportDataCodable.self, from: data as Data)
  }

  private func loadAirports(nasr: AirportDataCodable) async throws -> (
    cycle: Cycle?, lastUpdated: Date?
  ) {
    state = .loading(progress: 0)

    try resetData()

    let totalAirports = nasr.airports.count
    let batchSize = 100
    let batches = stride(from: 0, to: totalAirports, by: batchSize).map { start in
      Array(nasr.airports[start..<min(start + batchSize, totalAirports)])
    }

    for (batchIndex, batch) in batches.enumerated() {
      try await withThrowingDiscardingTaskGroup { group in
        for airport in batch {
          let airportCopy = airport
          group.addTask {
            await self.addAirport(airportCopy)
          }
        }
      }

      try modelContext.save()

      let completed = (batchIndex + 1) * batchSize
      let progress = Float(min(completed, totalAirports)) / Float(totalAirports)
      state = .loading(progress: progress)

      await Task.yield()
    }

    return (nasr.nasrCycle, nasr.ourAirportsLastUpdated)
  }

  private func resetData() throws {
    try modelContext.delete(model: SF50_Shared.Airport.self)
    try modelContext.delete(model: SF50_Shared.Runway.self)
    try modelContext.delete(model: NOTAM.self)
    try modelContext.save()
  }

  private func addAirport(_ airport: AirportDataCodable.AirportCodable) {
    let dataSource = DataSource(rawValue: airport.dataSource) ?? .NASR
    let timeZone = airport.timeZone.flatMap { TimeZone(identifier: $0) }

    let record = Airport(
      recordID: airport.recordID,
      locationID: airport.locationID,
      ICAO_ID: airport.ICAO_ID,
      name: airport.name,
      city: airport.city,
      dataSource: dataSource,
      latitude: .init(value: airport.latitude, unit: .degrees),
      longitude: .init(value: airport.longitude, unit: .degrees),
      elevation: .init(value: airport.elevation, unit: .meters),
      variation: .init(value: airport.variation, unit: .degrees),
      timeZone: timeZone
    )

    // Create a map to find reciprocal runways
    var runwayMap = [String: SF50_Shared.Runway]()

    for runwayData in airport.runways {
      let runway = SF50_Shared.Runway(
        name: runwayData.name,
        elevation: runwayData.elevation.map { .init(value: $0, unit: .meters) },
        trueHeading: .init(value: runwayData.trueHeading, unit: .degrees),
        gradient: runwayData.gradient,
        length: .init(value: runwayData.length, unit: .meters),
        takeoffRun: runwayData.takeoffRun.map { .init(value: $0, unit: .meters) },
        takeoffDistance: runwayData.takeoffDistance.map { .init(value: $0, unit: .meters) },
        landingDistance: runwayData.landingDistance.map { .init(value: $0, unit: .meters) },
        isTurf: runwayData.isTurf,
        airport: record
      )
      runwayMap[runwayData.name] = runway
    }

    // Only insert the airport and runways if we have runways
    guard !runwayMap.isEmpty else { return }

    modelContext.insert(record)
    for runway in runwayMap.values {
      modelContext.insert(runway)
    }

    // Link reciprocal runways
    for runwayData in airport.runways {
      if let reciprocalName = runwayData.reciprocalName,
        let runway = runwayMap[runwayData.name],
        let reciprocal = runwayMap[reciprocalName]
      {
        runway.reciprocal = reciprocal
      }
    }
  }

  /// Current state of the loading process.
  ///
  /// ## Cases
  ///
  /// - ``idle``: Not started
  /// - ``downloading(progress:)``: Downloading from GitHub (0.0-1.0)
  /// - ``extracting(progress:)``: Decompressing LZMA data
  /// - ``loading(progress:)``: Importing into SwiftData (0.0-1.0)
  /// - ``finished``: Complete
  enum State {
    case idle
    case downloading(progress: Float?)
    case extracting(progress: Float?)
    case loading(progress: Float?)
    case finished
  }

  /// Errors that can occur during airport data loading.
  enum Errors: Swift.Error {
    /// The current AIRAC cycle data is not yet available on GitHub.
    case cycleNotAvailable

    /// The server returned an unexpected response.
    case badResponse(_ response: URLResponse)
  }
}
