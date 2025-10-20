import SF50_Shared
import SwiftData
import SwiftUI

struct ScenarioDetailView: View {
  @Bindable var scenario: Scenario

  var body: some View {
    Form {
      Section("Scenario Name") {
        TextField("Name", text: $scenario.name)
          .accessibilityIdentifier("scenarioNameField")
      }

      Section("Adjustments") {
        LabeledContent("OAT Delta") {
          MeasurementField(
            "Temperature",
            value: $scenario.deltaTemperature,
            unit: .celsius,
            format: .temperature(plusSign: true)
          )
          .accessibilityIdentifier("oatDeltaField")
        }

        LabeledContent("Wind Speed Delta") {
          MeasurementField(
            "Speed",
            value: $scenario.deltaWindSpeed,
            unit: .knots,
            format: .speed(plusSign: true)
          )
          .accessibilityIdentifier("windSpeedDeltaField")
        }

        LabeledContent("Weight Delta") {
          MeasurementField(
            "Weight",
            value: $scenario.deltaWeight,
            unit: .pounds,
            format: .weight(plusSign: true)
          )
          .accessibilityIdentifier("weightDeltaField")
        }
      }

      Section("Overrides") {
        Picker("Flap Setting", selection: $scenario.flapSettingOverride) {
          Text("None").tag(nil as String?)
          Text("Flaps Up").tag("flapsUp" as String?)
          Text("Flaps Up ICE").tag("flapsUpIce" as String?)
          Text("Flaps 50").tag("flaps50" as String?)
          Text("Flaps 50 ICE").tag("flaps50Ice" as String?)
          Text("Flaps 100").tag("flaps100" as String?)
        }
        .accessibilityIdentifier("flapSettingPicker")

        Picker("Contamination", selection: $scenario.contaminationOverride) {
          Text("None").tag(nil as String?)
          Text("Dry").tag("dry" as String?)
          Text("Water/Slush").tag("waterOrSlush" as String?)
          Text("Slush/Wet Snow").tag("slushOrWetSnow" as String?)
          Text("Dry Snow").tag("drySnow" as String?)
          Text("Compact Snow").tag("compactSnow" as String?)
        }
        .accessibilityIdentifier("contaminationPicker")
        .onChange(of: scenario.contaminationOverride) { oldValue, newValue in
          // Handle "dry" selection
          if newValue == "dry" {
            scenario.isDryOverride = true
            scenario.contaminationOverride = nil
            scenario.contaminationDepth = nil
          } else if oldValue == nil && scenario.isDryOverride {
            // Clear dry override when switching to actual contamination
            scenario.isDryOverride = false
          }

          // Clear depth for non-depth contamination types
          if newValue != "waterOrSlush" && newValue != "slushOrWetSnow" {
            scenario.contaminationDepth = nil
          } else if scenario.contaminationDepth == nil {
            // Set default depth for depth-based contamination
            scenario.contaminationDepth = .init(value: 0.5, unit: .inches)
          }
        }

        if scenario.contaminationOverride == "waterOrSlush"
          || scenario.contaminationOverride == "slushOrWetSnow"
        {
          LabeledContent("Contamination Depth") {
            MeasurementField(
              "Depth",
              value: Binding(
                get: { scenario.contaminationDepth ?? .init(value: 0, unit: .inches) },
                set: { scenario.contaminationDepth = $0 }
              ),
              unit: .inches,
              format: .depth,
              minimum: .init(value: 0, unit: .inches)
            )
            .accessibilityIdentifier("contaminationDepthField")
          }
        }
      }
    }
    .navigationTitle(scenario.name.isEmpty ? "New Scenario" : scenario.name)
    .navigationBarTitleDisplayMode(.inline)
  }
}

#Preview {
  NavigationStack {
    ScenarioDetailView(
      scenario: Scenario(
        name: "OAT +10°C",
        operation: .takeoff,
        deltaTemperature: .init(value: 10, unit: .celsius)
      )
    )
  }
}
