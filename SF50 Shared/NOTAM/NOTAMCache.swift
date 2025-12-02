import Foundation
import Logging

/**
 * Actor responsible for caching NOTAM data fetched from the API.
 *
 * ``NOTAMCache`` provides in-memory session-based caching of NOTAM responses.
 * The cache persists for the lifetime of the app session and is only invalidated
 * when new NOTAMs are successfully downloaded for the same location.
 *
 * ## Cache Behavior
 *
 * - **Session-based**: Cache lives in memory, cleared on app termination
 * - **Location-keyed**: Each ICAO location has its own cache entry
 * - **Explicit invalidation**: Call ``invalidate(for:)`` before updating
 *
 * ## Thread Safety
 *
 * As an actor, all cache operations are automatically serialized.
 *
 * ## Usage
 *
 * ```swift
 * // Check cache
 * if let cached = await NOTAMCache.shared.get(for: "KJFK") {
 *     return cached
 * }
 *
 * // Fetch and cache
 * let notams = try await fetchFromAPI()
 * await NOTAMCache.shared.invalidate(for: "KJFK")
 * await NOTAMCache.shared.set(notams, for: "KJFK")
 * ```
 */
public actor NOTAMCache {
  /// Shared singleton instance
  public static let shared = NOTAMCache()

  /// Logger for cache operations
  private static let logger = Logger(label: "codes.tim.SF50-TOLD.NOTAMCache")

  /// Cached NOTAM data by ICAO location
  private var cache: [String: CachedNOTAMs] = [:]

  /// Returns the number of currently cached ICAO locations.
  public var cacheSize: Int {
    cache.count
  }

  /// Private initializer to enforce singleton pattern
  private init() {}

  /// Retrieves cached NOTAMs for an ICAO location.
  ///
  /// - Parameter icao: ICAO airport code
  /// - Returns: Cached NOTAMs if available, nil otherwise
  public func get(for icao: String) -> [NOTAMResponse]? {
    guard let cached = cache[icao.uppercased()] else {
      return nil
    }

    let age = Date().timeIntervalSince(cached.timestamp)
    Self.logger.debug(
      "Cache hit for ICAO",
      metadata: ["icao": "\(icao)", "count": "\(cached.notams.count)", "age": "\(age)s"]
    )
    return cached.notams
  }

  /// Stores NOTAMs in the cache for an ICAO location.
  ///
  /// - Parameters:
  ///   - notams: NOTAMs to cache
  ///   - icao: ICAO airport code
  public func set(_ notams: [NOTAMResponse], for icao: String) {
    cache[icao.uppercased()] = CachedNOTAMs(notams: notams, timestamp: Date())
    Self.logger.debug(
      "Cached NOTAMs for ICAO",
      metadata: ["icao": "\(icao)", "count": "\(notams.count)"]
    )
  }

  /// Invalidates cache for a specific ICAO location.
  ///
  /// - Parameter icao: ICAO airport code
  public func invalidate(for icao: String) {
    cache.removeValue(forKey: icao.uppercased())
    Self.logger.debug("Invalidated cache for ICAO", metadata: ["icao": "\(icao)"])
  }

  /// Clears the entire cache.
  public func clear() {
    let count = cache.count
    cache.removeAll()
    Self.logger.info("Cleared all cache", metadata: ["cleared": "\(count)"])
  }

  /// Cached NOTAM data with timestamp
  private struct CachedNOTAMs {
    let notams: [NOTAMResponse]
    let timestamp: Date
  }
}
