import SwiftUI

struct LocationErrorView: View {
  let error: Error

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
              VStack(alignment: .leading) {
                Text("Unable to determine location.")
                  .font(.headline)
                Text(errorDescription)
                  .font(.subheadline)
              }
            } else {
              VStack(alignment: .leading) {
                Text("Unable to determine location.")
                  .font(.headline)
                Text(error.localizedDescription)
                  .font(.subheadline)
              }
            }
            if let failureReason = error.failureReason {
              Text(failureReason)
            }
            if let recoverySuggestion = error.recoverySuggestion {
              Text(recoverySuggestion)
            }
          } else {
            VStack(alignment: .leading) {
              Text("Unable to determine location.")
                .font(.headline)
              Text(error.localizedDescription)
                .font(.subheadline)
            }
          }
        }
      }
    }.padding()
  }
}

#Preview {
  LocationErrorView(error: AirportLoader.Errors.cycleNotAvailable)
}
