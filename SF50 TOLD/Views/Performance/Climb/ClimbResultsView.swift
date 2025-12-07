import Defaults
import SF50_Shared
import SwiftUI

struct ClimbResultsView: View {
  @Environment(ClimbPerformanceViewModel.self)
  private var performance

  @Default(.speedUnit)
  private var speedUnit

  private var showMach: Bool {
    performance.altitude.converted(to: .feet).value >= 18400
  }

  var body: some View {
    Section {
      // Prominent climb speed display
      VStack {
        Text("En Route Climb Speed")
          .font(.headline)
          .foregroundStyle(.secondary)

        if showMach {
          // Mach display with secondary airspeed
          InterpolationView(
            value: performance.climbMach,
            displayValue: { mach in
              HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("M")
                  .font(.system(size: 48, weight: .light, design: .rounded))
                Text(mach, format: .mach)
                  .font(.system(size: 48, weight: .bold, design: .rounded))
                  .padding(.trailing, 4)

                // Secondary IAS display
                if case .value(let speed) = performance.climbSpeed {
                  Text(speed.converted(to: speedUnit), format: .speed)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                } else if case .valueWithUncertainty(let speed, _) = performance.climbSpeed {
                  Text("(\(speed.converted(to: speedUnit), format: .speed))")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                }
              }
              .accessibilityElement(children: .combine)
              .accessibilityIdentifier("climbSpeedValue")
            }
          )
        } else {
          // Standard IAS display
          InterpolationView(
            value: performance.climbSpeed,
            displayValue: { speed in
              Text(speed.converted(to: speedUnit), format: .speed)
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .accessibilityIdentifier("climbSpeedValue")
            }
          )
        }
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

#Preview("Offscale Low") {
  PreviewView { preview in
    // Set defaults BEFORE creating view model (it observes these)
    Defaults[.takeoffFuel] = .init(value: 50, unit: .gallons)

    let performance = ClimbPerformanceViewModel(container: preview.container)
    // Low fuel causes offscale low
    performance.altitude = .init(value: 3000, unit: .feet)

    return List { ClimbResultsView() }
      .environment(performance)
  }
}

#Preview("IAS Display") {
  PreviewView { preview in
    // Set defaults BEFORE creating view model (it observes these)
    Defaults[.takeoffFuel] = .init(value: 180, unit: .gallons)

    let performance = ClimbPerformanceViewModel(container: preview.container)
    // Mid-altitude climb (below 18,400 ft) - shows IAS
    performance.altitude = .init(value: 10000, unit: .feet)

    return List { ClimbResultsView() }
      .environment(performance)
  }
}

#Preview("Mach Display") {
  PreviewView { preview in
    // Set defaults BEFORE creating view model (it observes these)
    Defaults[.takeoffFuel] = .init(value: 180, unit: .gallons)

    let performance = ClimbPerformanceViewModel(container: preview.container)
    // High altitude climb (above 18,400 ft) - shows Mach
    performance.altitude = .init(value: 25000, unit: .feet)
    performance.ISADeviation = .init(value: -15, unit: .celsius)

    return List { ClimbResultsView() }
      .environment(performance)
  }
}
