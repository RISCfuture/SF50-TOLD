import SwiftUI

enum Model {
    case g1, g2, g2Plus
}

struct WelcomeView: View {
    @State private var model: Model = .g2
    @State private var updatedThrustSchedule = false
    @State private var showForm = false
    @State private var formOpacity = 0.0
    
    @ObservedObject var state: SettingsState
    
    var body: some View {
        VStack {
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
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
                    HStack {
                        Text("Model")
                        Spacer()
                        Picker("", selection: $model) {
                            Text("G1").tag(Model.g1)
                            Text("G2").tag(Model.g2)
                            Text("G2+").tag(Model.g2Plus)
                        }.pickerStyle(.segmented).frame(maxWidth: 200)
                    }
                    
                    if model == .g2 {
                        VStack(alignment: .leading) {
                            Toggle("Use Updated Thrust Schedule", isOn: $state.updatedThrustSchedule)
                            Text("Turn this setting on if your Vision Jet has SB5X-72-01 completed (G2+ equivalent).")
                                .font(.system(size: 11))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    
                    HStack {
                        Text("Empty Weight")
                        Spacer()
                        DecimalField("Weight",
                                     value: $state.emptyWeight,
                                     formatter: numberFormatter(precision: 0, minimum: 0, maximum: maxLandingWeight),
                                     suffix: "lbs")
                    }
                }.opacity(formOpacity)
                Spacer()
                
                Button("Continue") {
                    switch model {
                        case .g1: state.updatedThrustSchedule = false
                        case .g2: state.updatedThrustSchedule = updatedThrustSchedule
                        case .g2Plus: state.updatedThrustSchedule = true
                    }
                    state.initialSetupComplete = true
                }.opacity(formOpacity)
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
}

#Preview {
    WelcomeView(state: SettingsState())
}
