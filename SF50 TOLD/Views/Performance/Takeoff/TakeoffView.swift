import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct TakeoffView: View {
  @Environment(\.modelContext)
  private var modelContext

  @Default(.takeoffRunway)
  private var runwayID

  @State private var performance: TakeoffPerformanceViewModel?
  @State private var weather: WeatherViewModel?

  var body: some View {
    NavigationView {
      Form {
        TakeoffPerformanceView()
        TakeoffResultsView()
        TakeoffReportButton()
      }.navigationTitle("Takeoff")
    }
    .navigationViewStyle(navigationStyle)
    .environment(performance)
    .environment(weather)
    .environment(\.operation, .takeoff)
    .withErrorSheet(state: performance)
    .withErrorSheet(state: weather)
    .onAppear {
      if performance == nil {
        performance = .init(container: modelContext.container)
      }
      if weather == nil {
        weather = .init(operation: .takeoff, container: modelContext.container)
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
    preview.setTakeoff(runway: runway)

    return TakeoffView()
  }
}
