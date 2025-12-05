import SF50_Shared
import SwiftUI

private enum ContaminationType {
  case none
  case waterOrSlush
  case slushOrWetSnow
  case drySnow
  case compactSnow
  case wetRunway

  var hasDepth: Bool {
    self == .waterOrSlush || self == .slushOrWetSnow
  }

  init(from contamination: Contamination?) {
    switch contamination {
      case .waterOrSlush: self = .waterOrSlush
      case .slushOrWetSnow: self = .slushOrWetSnow
      case .drySnow: self = .drySnow
      case .compactSnow: self = .compactSnow
      case .wetRunway: self = .wetRunway
      case .none: self = .none
    }
  }
}

struct ContaminationView: View {
  @Binding var contamination: Contamination?

  @State private var contaminationType = ContaminationType.none
  @State private var contaminationDepth = 0.0

  private var contaminationDepthMeasurement: Measurement<UnitLength> {
    .init(value: contaminationDepth, unit: .inches)
  }

  private let minDepth = Measurement(value: 0, unit: UnitLength.inches)
  private let maxDepth = Measurement(value: 0.5, unit: UnitLength.inches)

  var body: some View {
    Section("Contamination") {
      HStack {
        Text("Contamination")
        Picker("", selection: $contaminationType) {
          Text("None").tag(ContaminationType.none)
          Text("Wet Runway").tag(ContaminationType.wetRunway)
          Text("Water/Slush").tag(ContaminationType.waterOrSlush)
          Text("Slush/Wet Snow").tag(ContaminationType.slushOrWetSnow)
          Text("Dry Snow").tag(ContaminationType.drySnow)
          Text("Compact Snow").tag(ContaminationType.compactSnow)
        }.accessibilityIdentifier("contaminationTypePicker")
      }

      if contaminationType.hasDepth {
        VStack {
          LabeledContent("Depth") {
            Text(contaminationDepthMeasurement, format: .depth)
          }

          HStack {
            Text(minDepth, format: .depth)
              .foregroundStyle(.secondary)
            Slider(
              value: $contaminationDepth,
              in: minDepth.value...maxDepth.value,
              step: 0.1
            )
            .accessibilityIdentifier("contaminationDepthSlider")
            Text(maxDepth, format: .depth)
              .foregroundStyle(.secondary)
          }
        }
      }
    }
    .onAppear {
      contaminationType = .init(from: contamination)
      contaminationDepth = contamination?.depth ?? 0
    }
    .onChange(of: contaminationType) {
      contamination = makeContamination()
    }
    .onChange(of: contaminationDepth) {
      contamination = makeContamination()
    }
  }

  private func makeContamination() -> Contamination? {
    switch contaminationType {
      case .none: return nil
      case .waterOrSlush:
        return .waterOrSlush(depth: .init(value: contaminationDepth, unit: .inches))
      case .slushOrWetSnow:
        return .slushOrWetSnow(
          depth: .init(value: contaminationDepth, unit: .inches)
        )
      case .drySnow: return .drySnow
      case .compactSnow: return .compactSnow
      case .wetRunway: return .wetRunway
    }
  }
}

extension Contamination {
  fileprivate var depth: Double {
    switch self {
      case .waterOrSlush(let depth):
        depth.converted(to: .inches).value
      case .slushOrWetSnow(let depth):
        depth.converted(to: .inches).value
      case .drySnow, .compactSnow, .wetRunway:
        0.0
    }
  }
}

#Preview {
  @State @Previewable var contamination: Contamination? = .waterOrSlush(
    depth: .init(value: 0.2, unit: .inches)
  )

  List {
    ContaminationView(contamination: $contamination)
  }
}
