import Defaults
import SF50_Shared
import SwiftUI

struct LandingDistanceView: View {
  @Environment(LandingPerformanceViewModel.self)
  private var performance

  var body: some View {
    LabeledContent(
      content: {
        InterpolationView(
          value: performance.landingDistance,
          displayValue: { Text($0, format: .length).fontWeight(.semibold) },
          displayUncertainty: { Text("±\($0, format: .length)") }
        )
        .accessibilityIdentifier("landingDistanceValue")
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
    preview.setLanding(runway: runway)

    return List {
      LandingDistanceView()
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
      LandingDistanceView()
    }
    .environment(performance)
  }
}

#Preview("N/A") {
  PreviewView(insert: .KSQL) { preview in
    List {
      LandingDistanceView()
    }
    .environment(LandingPerformanceViewModel(container: preview.container))
  }
}
