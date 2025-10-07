import Foundation
import SF50_Shared
import SwiftUI

struct ErrorSheet: View {
  var error: Error

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      HStack(alignment: .top) {
        Image(systemName: "xmark.octagon")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxHeight: 40)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 20) {
          if let error = error as? LocalizedError {
            if let errorDescription = error.errorDescription {
              Text(errorDescription)
                .font(.headline)
            } else {
              Text(error.localizedDescription)
                .font(.headline)
            }
            if let failureReason = error.failureReason {
              Text(failureReason)
                .font(.subheadline)
            }
            if let recoverySuggestion = error.recoverySuggestion {
              Text(recoverySuggestion)
                .font(.subheadline)
            }
          } else {
            Text(error.localizedDescription)
              .font(.headline)
          }
        }
      }
    }.padding()
  }
}

#Preview("Localized error") {
  ErrorSheet(error: AirportLoader.Errors.cycleNotAvailable)
}

#Preview("Non-localized error") {
  let error = DecodingError.dataCorrupted(
    .init(codingPath: [], debugDescription: "Test decoding failure.")
  )

  ErrorSheet(error: error)
}
