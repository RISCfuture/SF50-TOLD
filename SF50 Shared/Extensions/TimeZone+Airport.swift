import Defaults
import Foundation

extension TimeZone {
  /// Returns the appropriate timezone for displaying times based on user preference.
  ///
  /// - Parameters:
  ///   - airport: The airport to get the timezone for (optional)
  ///   - useAirportLocalTime: Whether to use airport-local time or UTC
  /// - Returns: The appropriate timezone: airport's timezone if available and enabled,
  ///            current timezone if no airport and enabled, otherwise UTC
  public static func displayTimeZone(
    for airport: Airport?,
    useAirportLocalTime: Bool
  ) -> TimeZone {
    guard useAirportLocalTime else {
      return TimeZone(identifier: "UTC") ?? .current
    }

    // If we have an airport and it has a timezone, use it
    if let airportTimeZone = airport?.timeZone {
      return airportTimeZone
    }

    // If no airport or no timezone data, use current timezone
    return .current
  }
}
