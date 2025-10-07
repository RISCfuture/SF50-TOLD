import Defaults
import SF50_Shared
import SwiftUI

struct TakeoffResultsView: View {
  @Environment(TakeoffPerformanceViewModel.self)
  private var performance

  @Default(.useRegressionModel)
  private var useRegressionModel

  var body: some View {
    Section("Performance") {
      TakeoffGroundRunView()
      TakeoffDistanceView()
      VxClimbView()

      if useRegressionModel && (performance.offscaleLow || performance.offscaleHigh) {
        OffscaleWarningView(
          offscaleLow: performance.offscaleLow,
          offscaleHigh: performance.offscaleHigh
        )
      }
    }
  }
}

#Preview {
  PreviewView(insert: .KSQL) { helper in
    let runway = try helper.load(airportID: "SQL", runway: "30")!
    helper.setTakeoff(runway: runway)

    return List { TakeoffResultsView() }
      .environment(TakeoffPerformanceViewModel(container: helper.container))
      .environment(WeatherViewModel(operation: .takeoff, container: helper.container))
  }
}
