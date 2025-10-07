import CoreLocation
import SwiftData

@Observable
@MainActor
public class NearestAirportViewModel {
  private static let searchRadius = 50.0  // Nmi, roughly

  public private(set) var airports: [Airport] = []
  public private(set) var error: Error?
  private var location: CLLocation? {
    didSet { updateAirports() }
  }

  private let streamer: any LocationStreamer
  private let container: ModelContainer

  private var updateTask: Task<Void, Never>?

  public init(container: ModelContainer, locationStreamer: any LocationStreamer) {
    self.streamer = locationStreamer
    self.container = container

    updateTask = Task {
      await streamer.start()

      // Get initial values
      location = streamer.location
      error = streamer.error

      // Subscribe to location updates
      for await newLocation in streamer.locationUpdates() where !Task.isCancelled {
        await MainActor.run {
          self.location = newLocation
          self.error = nil
        }
      }
    }
  }

  private func updateAirports() {
    do {
      let context = ModelContext(container)

      guard let predicate = makePredicate() else {
        airports = []
        return
      }
      let descriptor = FetchDescriptor(predicate: predicate)
      let unsortedAirports = try context.fetch(descriptor)

      airports = sort(airports: unsortedAirports)
    } catch {
      self.error = error
    }
  }

  private func makePredicate() -> Predicate<Airport>? {
    guard let location else { return nil }

    let lat = location.coordinate.latitude
    let lon = location.coordinate.longitude

    let latDelta = Self.searchRadius / 60.0
    let clampedMinLat = max(-90.0, lat - latDelta)
    let clampedMaxLat = min(90.0, lat + latDelta)

    let cosLat = cos(lat * .pi / 180)
    let  // Avoid divide-by-zero near poles
    lonDelta = Self.searchRadius / (60.0 * max(cosLat, 0.00001))
    var minLon = lon - lonDelta
    var maxLon = lon + lonDelta

    // Wrap around at -180/180
    if minLon < -180.0 { minLon += 360.0 }
    if maxLon > 180.0 { maxLon -= 360.0 }

    if minLon < maxLon {
      // Normal case: no wrap-around
      return #Predicate { airport in
        airport._latitude >= clampedMinLat && airport._latitude <= clampedMaxLat
          && airport._longitude >= minLon && airport._longitude <= maxLon
      }
    }
    // Wrap-around case: split longitude range
    return #Predicate { airport in
      airport._latitude >= clampedMinLat && airport._latitude <= clampedMaxLat
        && (airport._longitude >= minLon || airport._longitude <= maxLon)
    }
  }

  private func sort(airports: [Airport]) -> [Airport] {
    guard let location else { return airports }
    return
      airports
      .map { ($0, location.distance(from: $0.location)) }
      .sorted { $0.1 < $1.1 }
      .prefix(10)
      .map(\.0)
  }
}
