import Defaults
import SF50_Shared
import SwiftUI
import WidgetKit

struct RunwayListItem: View {
  var runway: RunwaySnapshot
  var takeoffDistance: Value<Measurement<UnitLength>>?
  var conditions: Conditions?

  @Default(.runwayLengthUnit)
  private var runwayLengthUnit

  private let integerFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    return formatter
  }()

  var body: some View {
    HStack {
      Text(runway.name).bold()
        .fixedSize(horizontal: true, vertical: false)

      if let conditions {
        SnapshotWindComponents(runway: runway, conditions: conditions)
      }

      Spacer()

      switch takeoffDistance {
        case .value(let measurement), .valueWithUncertainty(let measurement, _):
          if measurement > runway.takeoffDistanceOrLength {
            Text(measurement.converted(to: runwayLengthUnit), format: .length)
              .foregroundColor(.red)
          } else {
            Text(measurement.converted(to: runwayLengthUnit), format: .length)
              .foregroundColor(.green)
          }
          Text("/")
          Text(
            runway.takeoffDistanceOrLength.converted(to: runwayLengthUnit),
            format: .length
          )
        case .offscaleHigh:
          Text("Exceeds Limits")
            .foregroundColor(.red)
            .bold()
        case .notAuthorized:
          Text("Config N/A")
            .foregroundColor(.red)
            .bold()
        case .invalid, .notAvailable, .offscaleLow:
          Text("N/A")
            .foregroundColor(.gray)
        case .none:
          Text("10,000′ / 10,000′")
            .redacted(reason: .placeholder)
      }
    }
  }
}

/// Wind components view for RunwaySnapshot (widget-specific version)
private struct SnapshotWindComponents: View {
  var runway: RunwaySnapshot
  var conditions: Conditions

  @Default(.speedUnit)
  private var speedUnit

  var headwind: Measurement<UnitSpeed> { runway.headwind(conditions: conditions) }
  var crosswind: Measurement<UnitSpeed> { runway.crosswind(conditions: conditions) }

  var body: some View {
    HStack {
      if headwind.isPositive {
        HStack(spacing: 0) {
          Image(systemName: "arrowtriangle.down.fill")
            .foregroundStyle(.green)
            .accessibilityLabel("headwind")
          Text(headwind.converted(to: speedUnit).value.magnitude, format: .speed)
            .fixedSize(horizontal: true, vertical: false)
            .foregroundStyle(.primary)
            .accessibilityIdentifier("headwind")
        }
      } else if headwind.isNegative {
        HStack(spacing: 0) {
          Image(systemName: "arrowtriangle.up.fill")
            .foregroundStyle(.red)
            .accessibilityLabel("tailwind")
          Text(headwind.converted(to: speedUnit).value.magnitude, format: .speed)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("headwind")
        }
      }
      if crosswind.isPositive {
        HStack(spacing: 0) {
          Image(systemName: "arrowtriangle.left.fill")
            .foregroundStyle(.gray)
            .accessibilityLabel("left crosswind")
          Text(crosswind.converted(to: speedUnit).value.magnitude, format: .speed)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("crosswind")
        }
      } else if crosswind.isNegative {
        HStack(spacing: 0) {
          Image(systemName: "arrowtriangle.right.fill")
            .foregroundStyle(.gray)
            .accessibilityLabel("right crosswind")
          Text(crosswind.converted(to: speedUnit).value.magnitude, format: .speed)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("crosswind")
        }
      }
    }
  }
}

extension Measurement where UnitType == UnitSpeed {
  fileprivate var isPositive: Bool { asSpeed.value.rounded() >= 1 }
  fileprivate var isNegative: Bool { asSpeed.value.rounded() <= -1 }
}
