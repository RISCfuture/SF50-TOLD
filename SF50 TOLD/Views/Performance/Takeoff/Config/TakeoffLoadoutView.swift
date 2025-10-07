import Defaults
import SF50_Shared
import SwiftUI

struct TakeoffLoadoutView: View {
  @Environment(TakeoffPerformanceViewModel.self)
  private var performance

  @Default(.updatedThrustSchedule)
  private var updatedThrustSchedule

  @Default(.emptyWeight)
  private var emptyWeight

  @Default(.payload)
  private var payload

  @Default(.takeoffFuel)
  private var takeoffFuel

  private var limitations: Limitations.Type {
    updatedThrustSchedule ? LimitationsG2Plus.self : LimitationsG1.self
  }

  var body: some View {
    Section("Loading") {
      LabeledContent("Payload") {
        MeasurementField("Payload", value: $payload, unit: defaultWeightUnit, format: .weight)
          .accessibilityIdentifier("payloadField")
      }
      LabeledContent("Takeoff Fuel") {
        MeasurementField(
          "Takeoff Fuel",
          value: $takeoffFuel,
          unit: defaultFuelVolumeUnit,
          format: .fuel
        )
        .accessibilityIdentifier("fuelField")
      }
      LabeledContent("Takeoff Weight") {
        Text(performance.weight.asWeight, format: .weight)
          .bold()
          .multilineTextAlignment(.trailing)
          .foregroundStyle(performance.weight > limitations.maxTakeoffWeight ? .red : .primary)
      }
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    return Form {
      TakeoffLoadoutView()
        .environment(TakeoffPerformanceViewModel(container: preview.container))
    }
  }
}
