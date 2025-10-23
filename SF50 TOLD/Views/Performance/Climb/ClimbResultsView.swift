import Defaults
import SF50_Shared
import SwiftUI

struct ClimbResultsView: View {
  @Environment(ClimbPerformanceViewModel.self)
  private var performance

  @Default(.speedUnit)
  private var speedUnit

  var body: some View {
    Section {
      // Prominent climb speed display
      VStack {
        Text("Enroute Climb Speed")
          .font(.headline)
          .foregroundStyle(.secondary)

        InterpolationView(
          value: performance.climbSpeed,
          displayValue: { speed in
            Text(speed.converted(to: speedUnit), format: .speed)
              .font(.system(size: 48, weight: .bold, design: .rounded))
              .accessibilityIdentifier("climbSpeedValue")
          }
        )
      }
      .frame(maxWidth: .infinity)

      // Secondary displays
      HStack(spacing: 40) {
        VStack {
          Text("Climb Rate")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          InterpolationView(
            value: performance.climbRate,
            displayValue: { rate in
              Text(rate, format: .rateOfClimb)
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityIdentifier("climbRateValue")
            }
          )
        }

        VStack {
          Text("Climb Gradient")
            .font(.subheadline)
            .foregroundStyle(.secondary)

          InterpolationView(
            value: performance.climbGradient,
            displayValue: { gradient in
              Text(gradient, format: .gradient)
                .font(.title2)
                .fontWeight(.semibold)
                .accessibilityIdentifier("climbGradientValue")
            }
          )
        }
      }
      .frame(maxWidth: .infinity)
    }
  }
}

#Preview {
  PreviewView { preview in
    let performance = ClimbPerformanceViewModel(container: preview.container)

    // Set realistic mid-climb conditions
    // Need at least 150 gal fuel to reach min weight of 4500 lbs
    // (3550 empty + 0 payload + 150 * 6.71 = 4556 lbs)
    performance.fuel = .init(value: 180, unit: .gallons)
    performance.altitude = .init(value: 10000, unit: .feet)
    performance.ISADeviation = .init(value: 0, unit: .celsius)  // Standard ISA conditions
    performance.iceProtection = false

    return List { ClimbResultsView() }
      .environment(performance)
  }
}
