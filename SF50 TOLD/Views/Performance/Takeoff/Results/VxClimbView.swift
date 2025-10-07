import SF50_Shared
import SwiftUI

struct VxClimbView: View {
  @Environment(TakeoffPerformanceViewModel.self)
  private var performance

  private var vxText: AttributedString {
    let v = AttributedString("V")
    var x = AttributedString("X")
    x.font = .system(size: 10.0)
    x.baselineOffset = -3.0

    return v + x
  }

  private var requiredClimbGradientIfNotMet: Measurement<UnitSlope>? {
    guard case .value(let takeoffClimbGradient) = performance.takeoffClimbGradient,
      let requiredClimbGradient = performance.requiredClimbGradient
    else {
      return nil
    }
    return takeoffClimbGradient < requiredClimbGradient ? performance.requiredClimbGradient : nil
  }

  private var sufficientRunway: Bool {
    guard let availableTakeoffRun = performance.availableTakeoffRun,
      case .value(let takeoffRun) = performance.takeoffRun
    else {
      return true
    }
    return takeoffRun <= availableTakeoffRun
  }

  var body: some View {
    LabeledContent(
      content: {
        InterpolationView(
          value: performance.takeoffClimbGradient,
          minimum: performance.requiredClimbGradient,
          maxCritical: false,
          displayValue: { Text($0.asGradient, format: .gradient).fontWeight(.semibold) },
          displayUncertainty: { Text("±\($0.asGradient, format: .gradient)") }
        )
      },
      label: {
        Text("\(vxText) Climb Gradient")
      }
    )

    if sufficientRunway, let requiredClimbGradientIfNotMet {
      HStack {
        Label(
          "A climb gradient of \(requiredClimbGradientIfNotMet.asGradient, format: .gradient) is required.",
          systemImage: "exclamationmark.triangle"
        )
        .font(.system(size: 14))
        .foregroundColor(.red)
      }
    }

    LabeledContent(
      content: {
        InterpolationView(
          value: performance.takeoffClimbRate,
          minimum: .init(value: 0, unit: .feetPerMinute),
          maxCritical: false,
          displayValue: { Text($0, format: .rateOfClimb).fontWeight(.semibold) },
          displayUncertainty: { Text("±\($0, format: .rateOfClimb)") }
        )
      },
      label: {
        Text("\(vxText) Climb Rate")
      }
    )
  }
}

#Preview("No Obstacle") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setTakeoff(runway: runway)

    return List {
      VxClimbView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
  }
}

#Preview("Possible") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setTakeoff(runway: runway)
    try preview.addNOTAM(to: runway, obstacleHeight: 100, obstacleDistance: 0.1)

    return List {
      VxClimbView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
  }
}

#Preview("Impossible") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "30")!
    preview.setTakeoff(runway: runway)
    try preview.addNOTAM(to: runway, obstacleHeight: 800, obstacleDistance: 0.1)

    let performance = TakeoffPerformanceViewModel(container: preview.container)
    performance.conditions = preview.veryHot

    return List {
      VxClimbView()
    }
    .environment(performance)
  }
}

#Preview("Exceeds Runway Length") {
  PreviewView(insert: .KSQL) { preview in
    let runway = try preview.load(airportID: "SQL", runway: "30")!
    preview.setTakeoff(runway: runway)
    try preview.addNOTAM(to: runway, obstacleHeight: 100, obstacleDistance: 0.1)

    let performance = TakeoffPerformanceViewModel(container: preview.container)
    performance.conditions = preview.veryHot

    return List {
      VxClimbView()
    }
    .environment(performance)
  }
}

#Preview("N/A") {
  PreviewView(insert: .KSQL) { preview in
    List {
      VxClimbView()
    }
    .environment(TakeoffPerformanceViewModel(container: preview.container))
  }
}
