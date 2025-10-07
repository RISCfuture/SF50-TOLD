import SF50_Shared
import SwiftUI

struct WithErrorSheet: ViewModifier {
  let state: WithIdentifiableError?
  @State private var errorSheetIsPresented = false

  func body(content: Content) -> some View {
    content
      .sheet(isPresented: $errorSheetIsPresented) {
        ErrorSheet(error: state!.error!)
      }
      .onChange(of: state?.identifiableError) {
        if state?.error != nil {
          errorSheetIsPresented = true
        }
      }
  }
}

extension View {
  func withErrorSheet(state: (any WithIdentifiableError)?) -> some View {
    modifier(WithErrorSheet(state: state))
  }
}
