import Foundation

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
