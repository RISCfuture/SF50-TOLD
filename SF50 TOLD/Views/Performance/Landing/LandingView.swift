import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct LandingView: View {
  @Environment(\.modelContext)
  private var modelContext

  @Default(.landingRunway)
  private var runwayID

  @State private var performance: LandingPerformanceViewModel?
  @State private var weather: WeatherViewModel?
  @State private var landingTime = Date()

  var body: some View {
    NavigationView {
      if performance != nil && weather != nil {
        Form {
          LandingPerformanceView()
          LandingResultsView()
          LandingReportButton()
        }.navigationTitle("Landing")
      } else {
        ProgressView()
          .controlSize(.extraLarge)
          .navigationTitle("Landing")
      }
    }
    .navigationViewStyle(navigationStyle)
    .environment(performance)
    .environment(weather)
    .environment(\.operation, .landing)
    .withErrorSheet(state: performance)
    .onAppear {
      if performance == nil {
        performance = .init(container: modelContext.container)
      }
      if weather == nil {
        weather = .init(operation: .landing, container: modelContext.container)
      }
    }
    .onChange(of: weather?.conditions) {
      performance?.conditions = weather?.conditions ?? .init()
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setLanding(runway: runway)

    return LandingView()
  }
}
