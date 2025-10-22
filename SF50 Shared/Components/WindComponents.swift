import Defaults
import SwiftUI

public struct WindComponents: View {
  var runway: Runway
  var conditions: Conditions
  var crosswindLimit: Measurement<UnitSpeed>?
  var tailwindLimit: Measurement<UnitSpeed>?

  @Default(.speedUnit)
  private var speedUnit

  var headwind: Measurement<UnitSpeed> { runway.headwind(conditions: conditions) }
  var crosswind: Measurement<UnitSpeed> { runway.crosswind(conditions: conditions) }

  private var exceedsTailwindLimits: Bool {
    guard let tailwindLimit else { return false }
    return headwind < -tailwindLimit
  }

  private var exceedsCrosswindLimits: Bool {
    guard let crosswindLimit else { return false }
    return crosswind.magnitude > crosswindLimit
  }

  public var body: some View {
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
            .foregroundStyle(exceedsTailwindLimits ? .red : .primary)
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
            .foregroundStyle(exceedsCrosswindLimits ? .red : .primary)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("crosswind")
        }
      } else if crosswind.isNegative {
        HStack(spacing: 0) {
          Image(systemName: "arrowtriangle.right.fill")
            .foregroundStyle(.gray)
            .accessibilityLabel("right crosswind")
          Text(crosswind.converted(to: speedUnit).value.magnitude, format: .speed)
            .foregroundStyle(exceedsCrosswindLimits ? .red : .primary)
            .fixedSize(horizontal: true, vertical: false)
            .accessibilityIdentifier("crosswind")
        }
      }
    }
  }

  public init(
    runway: Runway,
    conditions: Conditions,
    crosswindLimit: Measurement<UnitSpeed>? = nil,
    tailwindLimit: Measurement<UnitSpeed>? = nil
  ) {
    self.runway = runway
    self.conditions = conditions
    self.crosswindLimit = crosswindLimit
    self.tailwindLimit = tailwindLimit
  }
}

extension Measurement where UnitType == UnitSpeed {
  fileprivate var isPositive: Bool { asSpeed.value.rounded() >= 1 }
  fileprivate var isNegative: Bool { asSpeed.value.rounded() <= -1 }
}

#Preview {
  PreviewView(insert: .KOAK) { preview in
    let runway = AirportBuilder.KSQL.unsaved().runways[0]

    return List {
      LabeledContent("ISA") {
        WindComponents(runway: runway, conditions: preview.ISA)
      }
      LabeledContent("Headwind") {
        WindComponents(runway: runway, conditions: preview.lightWinds)
      }
      LabeledContent("Tailwind") {
        WindComponents(
          runway: runway,
          conditions: preview.strongWinds,
          crosswindLimit: .init(value: 18, unit: .knots),
          tailwindLimit: .init(value: 10, unit: .knots)
        )
      }
    }
  }
}
