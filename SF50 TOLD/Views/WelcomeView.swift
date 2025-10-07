import Defaults
import SF50_Shared
import SwiftUI

struct WelcomeView: View {
  @Default(.updatedThrustSchedule)
  private var updatedThrustSchedule

  @Default(.initialSetupComplete)
  private var initialSetupComplete

  @Default(.emptyWeight)
  private var emptyWeight

  @State private var model: Model = .g2
  @State private var g2UseUpdatedThrustSchedule = false
  @State private var showForm = false
  @State private var formOpacity = 0.0

  var body: some View {
    VStack {
      VStack {
        Image("Logo")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(maxWidth: 200, alignment: /*@START_MENU_TOKEN@*/ .center /*@END_MENU_TOKEN@*/)
          .accessibilityHidden(true)
        Text("Welcome to SF50 TOLD")
          .fontWeight(.bold)
          .multilineTextAlignment(.center)
          .padding(.bottom)
        if showForm {
          Text("Let’s start by getting some information about your Vision Jet.")
            .multilineTextAlignment(.leading)
            .opacity(formOpacity)
        }
      }.padding()

      if showForm {
        Spacer()
        Form {
          Section {
            LabeledContent("Model") {
              Picker("", selection: $model) {
                Text("G1").tag(Model.g1)
                Text("G2").tag(Model.g2)
                Text("G2+").tag(Model.g2Plus)
              }
              .pickerStyle(.segmented)
              .frame(maxWidth: 200)
              .accessibilityIdentifier("modelPicker")
            }

            if model == .g2 {
              VStack(alignment: .leading) {
                Toggle("Use Updated Thrust Schedule", isOn: $g2UseUpdatedThrustSchedule)
                  .accessibilityIdentifier("updatedThrustScheduleToggle")
                Text(
                  "Turn this setting on if your Vision Jet has SB5X-72-01 completed (G2+ equivalent)."
                )
                .font(.system(size: 11))
                .fixedSize(horizontal: false, vertical: true)
              }
            }

            LabeledContent("Empty Weight") {
              MeasurementField(
                "Weight",
                value: $emptyWeight,
                unit: defaultWeightUnit,
                format: .weight
              )
              .accessibilityIdentifier("emptyWeightField")
            }
          }

          Section {
            ModelToggleView()
          }
        }.opacity(formOpacity)
        Spacer()

        Button("Continue") {
          switch model {
            case .g1: updatedThrustSchedule = false
            case .g2: updatedThrustSchedule = g2UseUpdatedThrustSchedule
            case .g2Plus: updatedThrustSchedule = true
          }
          initialSetupComplete = true
        }.opacity(formOpacity)
          .accessibilityIdentifier("continueButton")
      }
    }
    .onAppear {
      withAnimation(Animation.easeInOut(duration: 0.5).delay(2)) {
        showForm = true
      }
      withAnimation(Animation.easeInOut(duration: 0.5).delay(2.5)) {
        formOpacity = 1.0
      }
    }
  }

  private var maxLandingWeight: Measurement<UnitMass> {
    switch model {
      case .g1, .g2: LimitationsG1.maxLandingWeight
      case .g2Plus: LimitationsG2Plus.maxLandingWeight
    }
  }

  private enum Model {
    case g1, g2, g2Plus
  }
}

#Preview {
  WelcomeView()
}
