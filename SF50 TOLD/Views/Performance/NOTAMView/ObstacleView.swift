import Defaults
import SF50_Shared
import SwiftUI

struct ObstacleView: View {
  @Bindable var notam: NOTAM

  @Default(.heightUnit)
  private var heightUnit

  @Default(.distanceUnit)
  private var distanceUnit

  var body: some View {
    Section("Obstacle") {
      LabeledContent("Obstacle Height") {
        MeasurementField(
          "Height",
          value: $notam.obstacleHeight,
          unit: heightUnit,
          format: .height
        )
        .accessibilityIdentifier("obstacleHeightField")
      }

      LabeledContent("Obstacle Distance") {
        MeasurementField(
          "Distance",
          value: $notam.obstacleDistance,
          unit: distanceUnit,
          format: .distance
        )
        .accessibilityIdentifier("obstacleDistanceField")
      }
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "30")!
    let notam = try preview.addNOTAM(
      to: runway,
      obstacleHeight: 75,
      obstacleDistance: 0.4
    )

    return List {
      ObstacleView(notam: notam)
    }
  }
}
