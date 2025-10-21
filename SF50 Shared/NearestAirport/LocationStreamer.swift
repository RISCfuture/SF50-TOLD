import CoreLocation
import Sentry
import SwiftUI

public enum LocationError: Error {
  case permissionDenied
  case locationUnavailable
}

@MainActor
public protocol LocationStreamer: Sendable {
  var location: CLLocation? { get }
  var error: Error? { get }

  func start() async
  func stop() async
  func locationUpdates() -> AsyncStream<CLLocation>
}

@MainActor
@Observable
public final class CoreLocationStreamer: NSObject, LocationStreamer {
  public private(set) var location: CLLocation?
  public private(set) var error: Error?

  private var updateTask: Task<Void, Never>?
  private var listenerCount = 0
  private let manager = CLLocationManager()
  private var locationContinuations = Set<UUID>()
  private var continuationMap = [UUID: AsyncStream<CLLocation>.Continuation]()

  override public init() {
    super.init()
    manager.delegate = self
    manager.desiredAccuracy = kCLLocationAccuracyBest
    manager.requestWhenInUseAuthorization()
  }

  public func start() {
    listenerCount += 1
    if listenerCount == 1 {
      _start()
    }
  }

  public func stop() {
    listenerCount -= 1
    if listenerCount == 0 { _stop() }
  }

  private func _start() {
    guard updateTask == nil else { return }

    // Check authorization first
    let authStatus = manager.authorizationStatus
    switch authStatus {
      case .denied, .restricted:
        error = LocationError.permissionDenied
        return
      case .notDetermined:
        // Already requested in init, wait for response
        return
      case .authorizedWhenInUse, .authorizedAlways:
        break
      @unknown default:
        break
    }

    updateTask = Task {
      do {
        for try await locationUpdate in CLLocationUpdate.liveUpdates() where !Task.isCancelled {
          await MainActor.run {
            guard let newLocation = locationUpdate.location else { return }
            location = newLocation
            error = nil

            for continuation in continuationMap.values {
              continuation.yield(newLocation)
            }
          }
        }
      } catch {
        SentrySDK.capture(error: error)
        await MainActor.run {
          self.error = error
        }
      }
    }
  }

  private func _stop() {
    updateTask?.cancel()
    updateTask = nil

    // Finish all continuations
    for (_, continuation) in continuationMap {
      continuation.finish()
    }
    continuationMap.removeAll()
    locationContinuations.removeAll()
  }

  public func locationUpdates() -> AsyncStream<CLLocation> {
    AsyncStream { continuation in
      let id = UUID()

      Task { @MainActor in
        self.locationContinuations.insert(id)
        self.continuationMap[id] = continuation

        if let location = self.location { continuation.yield(location) }

        if self.listenerCount == 0 { self.start() }

        continuation.onTermination = { _ in
          Task { @MainActor in
            self.locationContinuations.remove(id)
            self.continuationMap.removeValue(forKey: id)

            if self.locationContinuations.isEmpty && self.listenerCount == 0 {
              self.stop()
            }
          }
        }
      }
    }
  }
}

extension CoreLocationStreamer: CLLocationManagerDelegate {
  nonisolated public func locationManager(
    _: CLLocationManager,
    didChangeAuthorization status: CLAuthorizationStatus
  ) {
    Task { @MainActor in
      handleAuthorizationChange(status)
    }
  }

  private func handleAuthorizationChange(_ status: CLAuthorizationStatus) {
    switch status {
      case .authorizedWhenInUse, .authorizedAlways:
        // Permission granted, start location updates if we have listeners
        if listenerCount > 0 && updateTask == nil {
          _start()
        }
      case .denied, .restricted:
        error = LocationError.permissionDenied
        _stop()
      case .notDetermined:
        break
      @unknown default:
        break
    }
  }
}

private struct LocationStreamerKey: EnvironmentKey {
  static let defaultValue: any LocationStreamer = {
    MainActor.assumeIsolated {
      CoreLocationStreamer()
    }
  }()
}

extension EnvironmentValues {
  public var locationStreamer: LocationStreamer {
    get { self[LocationStreamerKey.self] }
    set { self[LocationStreamerKey.self] = newValue }
  }
}
