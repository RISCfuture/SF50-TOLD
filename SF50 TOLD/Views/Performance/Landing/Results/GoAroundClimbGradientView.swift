import SF50_Shared
import SwiftUI

struct GoAroundClimbGradientView: View {
  @Environment(LandingPerformanceViewModel.self)
  private var performance

  var body: some View {

    LabeledContent("Meets Go-Around Climb Gradient") {
      InterpolationView(
        value: performance.meetsGoAroundClimbGradient,
        displayValue: { meets in
          if meets {
            Text("Yes", comment: "Meets go-around climb gradient?").bold()
          } else {
            Text("No", comment: "Meets go-around climb gradient?").bold().foregroundColor(.red)
          }
        }
      )
    }
  }
}

#Preview("Yes") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setLanding(runway: runway)

    return List {
      GoAroundClimbGradientView()
    }
    .environment(LandingPerformanceViewModel(container: preview.container))
  }
}

#Preview("No") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setLanding(runway: runway)
    let performance = LandingPerformanceViewModel(container: preview.container)
    performance.conditions = preview.veryHot

    return List {
      GoAroundClimbGradientView()
    }
    .environment(performance)
  }
}

#Preview("No Obstacle") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setLanding(runway: runway)
    let performance = LandingPerformanceViewModel(container: preview.container)
    performance.conditions = preview.veryHot

    return List {
      GoAroundClimbGradientView()
    }
    .environment(performance)
  }
}
