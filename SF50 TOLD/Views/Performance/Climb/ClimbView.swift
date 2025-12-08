import SF50_Shared
import SwiftData
import SwiftUI

struct ClimbView: View {
  @Environment(\.modelContext)
  private var modelContext

  @State private var performance: ClimbPerformanceViewModel?

  var body: some View {
    NavigationView {
      if performance != nil {
        Form {
          ClimbConfigView()
          ClimbResultsView()
        }.navigationTitle("Climb")
      } else {
        ProgressView()
          .controlSize(.extraLarge)
          .navigationTitle("Climb")
      }
    }
    .navigationViewStyle(navigationStyle)
    .environment(performance)
    .onAppear {
      if performance == nil {
        performance = .init(container: modelContext.container)
      }
    }
  }
}

#Preview {
  PreviewView { _ in
    ClimbView()
  }
}
