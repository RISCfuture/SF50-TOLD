import Defaults
import SF50_Shared
import SwiftUI

struct TakeoffGroundRunView: View {
  @Environment(TakeoffPerformanceViewModel.self)
  private var performance

  @Default(.runwayLengthUnit)
  private var runwayLengthUnit

  var body: some View {
    LabeledContent("Ground Run") {
      InterpolationView(
        value: performance.takeoffRun,
        maximum: performance.availableTakeoffRun,
        displayValue: {
          Text($0.converted(to: runwayLengthUnit), format: .length).fontWeight(.semibold)
        },
        displayUncertainty: { Text("±\($0.converted(to: runwayLengthUnit), format: .length)") }
      )
      .accessibilityIdentifier("takeoffGroundRunValue")
    }
  }
}

#Preview("Possible") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setTakeoff(runway: runway)

    return List {
      TakeoffGroundRunView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
  }
}

#Preview("Impossible") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setTakeoff(runway: runway)
    let performance = TakeoffPerformanceViewModel(container: preview.container)
    performance.conditions = preview.veryHot

    return List {
      TakeoffGroundRunView()
    }
    .environment(performance)
  }
}

#Preview("N/A") {
  PreviewView(insert: .KSQL) { preview in
    List {
      TakeoffGroundRunView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
  }
}
