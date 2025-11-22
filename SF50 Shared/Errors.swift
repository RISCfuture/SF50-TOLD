import Foundation

extension WeatherLoader.Errors: LocalizedError {
  public var errorDescription: String? {
    String(localized: "Weather information couldn’t be read")
  }

  public var failureReason: String? {
    switch self {
      case .badResponse(let response):
        String(localized: "Received HTTP response \(response.statusCode).")
      case .gzipDecompressionFailed:
        String(localized: "Downloaded weather data was corrupted or incomplete.")
    }
  }

  public var recoverySuggestion: String? {
    String(localized: "Try re-downloading weather data later, or manually enter weather.")
  }
}
