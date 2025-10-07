import Defaults
import SF50_Shared
import SwiftUI

struct TakeoffDistanceView: View {
  @Environment(TakeoffPerformanceViewModel.self)
  private var performance

  var body: some View {
    LabeledContent(
      content: {
        InterpolationView(
          value: performance.takeoffDistance,
          maximum: performance.availableTakeoffDistance,
          displayValue: { Text($0, format: .length).fontWeight(.semibold) },
          displayUncertainty: { Text("±\($0, format: .length)") }
        )
        .accessibilityIdentifier("takeoffDistanceValue")
      },
      label: {
        Text("Total Distance")
        Text("over a 50-foot obstacle")
          .font(.system(size: 11))
          .fixedSize(horizontal: false, vertical: true)
      }
    )
  }
}

#Preview("Possible") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setTakeoff(runway: runway)

    return List {
      TakeoffDistanceView()
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
      TakeoffDistanceView()
    }
    .environment(performance)
  }
}

#Preview("N/A") {
  PreviewView(insert: .KSQL) { preview in
    List {
      TakeoffDistanceView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
  }
}
