import Foundation

enum DataDownloadError: Swift.Error {
    case cycleNotAvailable
    case badResponse(_ response: URLResponse)
    case unknown(error: Swift.Error)
}

enum WeatherDownloadError: Swift.Error {
    case noData
    case badCSV
    case unexpectedEncoding
    case badResponse
    case badStatusCode(_ code: Int)
}

extension DataDownloadError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .cycleNotAvailable:
                return NSLocalizedString("The latest database cycle is not available for download yet. Try again later.", comment: "error")
            case .badResponse(_):
                return NSLocalizedString("Couldn’t download the latest database cycle. Try again later.", comment: "error")
            case let .unknown(error): return error.localizedDescription
        }
    }
}

extension WeatherDownloadError: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .noData:
                return NSLocalizedString("The Aviation Weather Service did not return any weather data.", comment: "error")
            case .badCSV, .unexpectedEncoding:
                return NSLocalizedString("Couldn’t read Aviation Weather Service weather data.", comment: "error")
            case .badResponse:
                return NSLocalizedString("The Aviation Weather Service returned an unexpected response.", comment: "error")
            case let .badStatusCode(code):
                let format = NSLocalizedString("The Aviation Weather Service returned an unexpected status code %d.", comment: "error")
                return String(format: format, code)
        }
    }
}
