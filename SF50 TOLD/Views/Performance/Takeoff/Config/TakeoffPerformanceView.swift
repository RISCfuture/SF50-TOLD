import SF50_Shared
import SwiftData
import SwiftUI

struct TakeoffPerformanceView: View {
  var body: some View {
    TakeoffLoadoutView()
    TakeoffConfigurationView()
    TakeoffAirportView()
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    return Form { TakeoffPerformanceView() }
      .environment(WeatherViewModel(operation: .takeoff, container: preview.container))
      .environment(TakeoffPerformanceViewModel(container: preview.container))
  }
}
