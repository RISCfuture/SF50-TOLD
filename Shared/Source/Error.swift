import Foundation

enum Error: Swift.Error {
    case cycleNotAvailable
    case badResponse(_ response: URLResponse)
    case unknown(error: Swift.Error)
}

extension Error: LocalizedError {
    var errorDescription: String? {
        switch self {
            case .cycleNotAvailable:
                return NSLocalizedString("The latest database cycle is not available for download yet. Try again later.", comment: "error")
            case .badResponse(_):
                return NSLocalizedString("Couldn’t download the latest database cycle. Try again later.", comment: "error")
            case let .unknown(error):
                return error.localizedDescription
        }
    }
}
