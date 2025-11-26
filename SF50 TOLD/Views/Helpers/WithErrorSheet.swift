import SF50_Shared
import SwiftUI

struct WithErrorSheet: ViewModifier {
  let state: WithIdentifiableError?
  @State private var presentedError: IdentifiableError?

  func body(content: Content) -> some View {
    content
      .sheet(item: $presentedError) { identifiableError in
        ErrorSheet(error: identifiableError.error)
      }
      .onChange(of: state?.identifiableError) {
        // Capture the error at presentation time to avoid race conditions
        presentedError = state?.identifiableError
      }
  }
}

extension View {
  func withErrorSheet(state: (any WithIdentifiableError)?) -> some View {
    modifier(WithErrorSheet(state: state))
  }
}
