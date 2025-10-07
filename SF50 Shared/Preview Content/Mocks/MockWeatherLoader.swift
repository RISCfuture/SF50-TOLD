import CoreLocation
import Foundation

public actor MockWeatherLoader: WeatherLoaderProtocol {

  private var mockConditions: Loadable<Conditions> = .notLoaded
  private var mockMETAR: Loadable<String?> = .notLoaded
  private var mockTAF: Loadable<String?> = .notLoaded
  private var mockError: Error?

  public init(
    mockConditions: Loadable<Conditions> = .notLoaded,
    mockMETAR: Loadable<String?> = .notLoaded,
    mockTAF: Loadable<String?> = .notLoaded,
    mockError: Error? = nil
  ) {
    self.mockConditions = mockConditions
    self.mockMETAR = mockMETAR
    self.mockTAF = mockTAF
    self.mockError = mockError
  }

  public func setMockConditions(_ conditions: Loadable<Conditions>) {
    mockConditions = conditions
  }

  public func setMockMETAR(_ metar: Loadable<String?>) {
    mockMETAR = metar
  }

  public func setMockTAF(_ taf: Loadable<String?>) {
    mockTAF = taf
  }

  public func setMockError(_ error: Error?) {
    mockError = error
  }

  public func load(force _: Bool = false) {
    // Mock implementation - does nothing
  }

  public func cancelLoading() {
    // Mock implementation - does nothing
  }

  public func streamConditions(for _: WeatherLoader.Key) -> AsyncStream<Loadable<Conditions>> {
    AsyncStream { continuation in
      continuation.yield(mockConditions)

      // Keep the stream alive until cancelled
      continuation.onTermination = { _ in
        // Stream terminated
      }
    }
  }

  public func streamMETAR(for _: WeatherLoader.Key) -> AsyncStream<Loadable<String?>> {
    AsyncStream { continuation in
      continuation.yield(mockMETAR)

      // Keep the stream alive until cancelled
      continuation.onTermination = { _ in
        // Stream terminated
      }
    }
  }

  public func streamTAF(for _: WeatherLoader.Key) -> AsyncStream<Loadable<String?>> {
    AsyncStream { continuation in
      continuation.yield(mockTAF)

      // Keep the stream alive until cancelled
      continuation.onTermination = { _ in
        // Stream terminated
      }
    }
  }
}
