import CoreLocation
import SwiftUI

@MainActor
@Observable
public final class MockLocationStreamer: LocationStreamer {
  public var location: CLLocation?
  public var error: Error?

  public init() {}

  public func start() {
    location = .init(latitude: 37.819814, longitude: -122.478513)
  }

  public func stop() {}

  public func locationUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
      // Send the mock location immediately
      let location = self.location ?? CLLocation(latitude: 37.819814, longitude: -122.478513)
      continuation.yield(location)

      // Keep the stream alive but don't send more updates
      continuation.onTermination = { _ in
        // Stream terminated
      }
    }
  }
}
