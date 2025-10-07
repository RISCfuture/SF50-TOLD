import SwiftData
import SwiftUI

public struct PreviewView<Content: View>: View {
  private let result: Result<Content, Error>
  private let container: ModelContainer?

  public var body: some View {
    switch result {
      case .success(let view):
        if let container {
          view.modelContainer(container)
        } else {
          view
        }
      case .failure(let error):
        VStack(spacing: 8) {
          Label("Preview Failed", systemImage: "exclamationmark.triangle")
            .font(.title2)
            .foregroundColor(.red)
          Text(error.localizedDescription)
            .font(.body)
            .multilineTextAlignment(.center)

          if let error = error as? LocalizedError {
            if let failureReason = error.failureReason {
              Text(failureReason)
                .font(.body)
                .multilineTextAlignment(.center)
            }
            if let recoverySuggestion = error.recoverySuggestion {
              Text(recoverySuggestion)
                .font(.body)
                .multilineTextAlignment(.center)
            }
          }
        }
        .padding()
    }
  }

  public init(insert airports: AirportBuilder..., builder: (PreviewHelper) throws -> Content) {
    do {
      let helper = try PreviewHelper()
      try helper.reset()
      for airport in airports { try helper.insert(airport: airport) }
      result = .success(try builder(helper))
      container = helper.container
    } catch {
      result = .failure(error)
      container = nil
    }
  }
}
