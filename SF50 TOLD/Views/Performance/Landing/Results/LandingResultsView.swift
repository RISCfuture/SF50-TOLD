import Defaults
import SF50_Shared
import SwiftUI

struct LandingResultsView: View {
  @Environment(LandingPerformanceViewModel.self)
  private var performance

  @Default(.useRegressionModel)
  private var useRegressionModel

  var body: some View {
    Section("Performance") {
      VREFView()
      LandingGroundRunView()
      LandingDistanceView()
      GoAroundClimbGradientView()

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
    helper.setLanding(runway: runway)

    return List { LandingResultsView() }
      .environment(LandingPerformanceViewModel(container: helper.container))
      .environment(WeatherViewModel(operation: .landing, container: helper.container))
  }
}
