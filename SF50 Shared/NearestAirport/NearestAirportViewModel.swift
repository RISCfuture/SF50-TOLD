import CoreLocation
import Sentry
import SwiftData

/// View model for finding airports near the user's current location.
///
/// ``NearestAirportViewModel`` uses CoreLocation to track the user's position
/// and queries SwiftData for nearby airports. Results are sorted by distance
/// and limited to the closest 10 airports within a 50 nautical mile radius.
///
/// ## Location Updates
///
/// The view model subscribes to location updates via ``LocationStreamer``
/// and automatically updates the airport list when the user moves.
///
/// ## Usage
///
/// ```swift
/// let viewModel = NearestAirportViewModel(
///     container: modelContainer,
///     locationStreamer: CoreLocationStreamer()
/// )
///
/// // Access nearest airports
/// ForEach(viewModel.airports) { airport in
///     Text(airport.name)
/// }
/// ```
///
/// ## See Also
///
/// - ``LocationStreamer``
/// - ``CoreLocationStreamer``
@Observable
@MainActor
public class NearestAirportViewModel {
  /// Search radius in nautical miles
  private static let searchRadius = 50.0

  /// Airports sorted by distance from user's current location (max 10)
  public private(set) var airports: [Airport] = []

  /// Error from location services or database query
  public private(set) var error: Error?

  /// Current user location
  private var location: CLLocation? {
    didSet { updateAirports() }
  }

  /// Location service provider
  private let streamer: any LocationStreamer

  /// SwiftData container for airport queries
  private let container: ModelContainer

  /// Background task for location updates
  private var updateTask: Task<Void, Never>?

  /**
   * Creates a view model with the specified data container and location streamer.
   *
   * - Parameters:
   *   - container: SwiftData model container for airport queries.
   *   - locationStreamer: Location service provider for tracking user position.
   */
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
      SentrySDK.capture(error: error)
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
