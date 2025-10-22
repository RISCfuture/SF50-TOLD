import Defaults
import SF50_Shared
import SwiftUI

struct LandingGroundRunView: View {
  @Environment(LandingPerformanceViewModel.self)
  private var performance

  @Default(.runwayLengthUnit)
  private var runwayLengthUnit

  var body: some View {
    LabeledContent("Ground Run") {
      InterpolationView(
        value: performance.landingRun,
        maximum: performance.availableLandingRun,
        displayValue: {
          Text($0.converted(to: runwayLengthUnit), format: .length).fontWeight(.semibold)
        },
        displayUncertainty: { Text("±\($0.converted(to: runwayLengthUnit), format: .length)") }
      )
    }
  }
}

#Preview("Possible") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setLanding(runway: runway)

    return List {
      LandingGroundRunView()
    }
    .environment(LandingPerformanceViewModel(container: preview.container))
  }
}

#Preview("Impossible") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setLanding(runway: runway)
    let performance = LandingPerformanceViewModel(container: preview.container)
    performance.conditions = preview.veryHot

    return List {
      LandingGroundRunView()
    }
    .environment(performance)
  }
}

#Preview("N/A") {
  PreviewView(insert: .KSQL) { preview in
    List {
      LandingGroundRunView()
    }
    .environment(LandingPerformanceViewModel(container: preview.container))
  }
}
