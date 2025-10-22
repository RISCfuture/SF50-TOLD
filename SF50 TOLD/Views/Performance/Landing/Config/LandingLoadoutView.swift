import Defaults
import SF50_Shared
import SwiftUI

struct LandingLoadoutView: View {
  @Environment(LandingPerformanceViewModel.self)
  private var performance

  @Default(.updatedThrustSchedule)
  private var updatedThrustSchedule

  @Default(.emptyWeight)
  private var emptyWeight

  @Default(.payload)
  private var payload

  @Default(.landingFuel)
  private var landingFuel

  @Default(.weightUnit)
  private var weightUnit

  @Default(.fuelVolumeUnit)
  private var fuelVolumeUnit

  private var limitations: Limitations.Type {
    updatedThrustSchedule ? LimitationsG2Plus.self : LimitationsG1.self
  }

  var body: some View {
    Section("Loading") {
      LabeledContent("Payload") {
        MeasurementField("Payload", value: $payload, unit: weightUnit, format: .weight)
          .accessibilityIdentifier("payloadField")
      }
      LabeledContent("Landing Fuel") {
        MeasurementField(
          "Landing Fuel",
          value: $landingFuel,
          unit: fuelVolumeUnit,
          format: .fuel
        )
        .accessibilityIdentifier("fuelField")
      }
      LabeledContent("Landing Weight") {
        Text(performance.weight.converted(to: weightUnit), format: .weight)
          .bold()
          .multilineTextAlignment(.trailing)
          .foregroundStyle(performance.weight > limitations.maxLandingWeight ? .red : .primary)
      }
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setLanding(runway: runway)

    return Form {
      LandingLoadoutView()
        .environment(LandingPerformanceViewModel(container: preview.container))
    }
  }
}
