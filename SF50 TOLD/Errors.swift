import Foundation
import SF50_Shared

extension AirportLoader.Errors: LocalizedError {
  var errorDescription: String? {
    String(localized: "Airport data couldn’t be downloaded")
  }

  var failureReason: String? {
    switch self {
      case .badResponse(let response):
        if let response = response as? HTTPURLResponse {
          String(localized: "Received HTTP response \(response.statusCode).")
        } else {
          String(localized: "Received bad HTTP response.")
        }
      case .cycleNotAvailable:
        String(localized: "Airport data for the current cycle is not yet available.")
    }
  }

  var recoverySuggestion: String? {
    String(
      localized: "Try re-downloading airport data later, or continue with out-of-date airport data."
    )
  }
}

extension NOTAMLoader.Errors: @retroactive LocalizedError {
  public var errorDescription: String? {
    String(localized: "NOTAM information couldn’t be loaded")
  }

  public var failureReason: String? {
    switch self {
      case .invalidURL:
        String(localized: "The request URL was invalid.")
      case .invalidResponse:
        String(localized: "The server returned an invalid response.")
      case .badResponse(let response):
        String(localized: "Received HTTP response \(response.statusCode).")
      case .apiError(let statusCode, let code, let message):
        if statusCode == 401 {
          String(localized: "Authentication failed. The API token may be invalid or expired.")
        } else if statusCode == 404 {
          String(localized: "The requested NOTAM was not found.")
        } else {
          String(localized: "API error (\(code)): \(message)")
        }
      case .decodingFailed:
        String(localized: "The NOTAM data was corrupted or in an unexpected format.")
      case .networkError(let error):
        String(localized: "Network error: \(error.localizedDescription)")
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .invalidURL, .invalidResponse, .decodingFailed:
        String(localized: "Please contact support if this problem persists.")
      case .badResponse, .apiError:
        String(
          localized:
            "Try again later, or manually enter NOTAM information if available from other sources."
        )
      case .networkError:
        String(
          localized:
            "Check your internet connection and try again. You can manually enter NOTAM information if needed."
        )
    }
  }
}
