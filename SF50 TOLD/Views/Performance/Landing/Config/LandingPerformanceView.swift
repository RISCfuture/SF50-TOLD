import SF50_Shared
import SwiftData
import SwiftUI

struct LandingPerformanceView: View {
  var body: some View {
    LandingLoadoutView()
    LandingConfigurationView()
    LandingAirportView()
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setLanding(runway: runway)

    return Form { LandingPerformanceView() }
      .environment(WeatherViewModel(operation: .landing, container: preview.container))
      .environment(LandingPerformanceViewModel(container: preview.container))
  }
}
