import SwiftUI
import Defaults

enum Model {
    case g1, g2, g2Plus
}

struct WelcomeView: View {
    @Default(.g3Wing) var g3Wing
    @Default(.initialSetupComplete) var initialSetupComplete
    @Default(.emptyWeight) var emptyWeight
    
    @State private var showForm = false
    @State private var formOpacity = 0.0
    
    var body: some View {
        VStack {
            VStack {
                Image("Logo")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                Text("Welcome to SR22-G2 TOLD")
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.bottom)
                if showForm {
                    Text("Let’s start by getting some information about your Cirrus.")
                        .multilineTextAlignment(.leading)
                        .opacity(formOpacity)
                }
            }.padding()
            
            if showForm {
                Spacer()
                Form {
                    
                    
                        VStack(alignment: .leading) {
                            Toggle("G3 Wing", isOn: $g3Wing)
                                .accessibilityIdentifier("g3WingToggle")
                            Text("Turn this setting on if your SR22 G2 has the G3 wing installed.")
                                .font(.system(size: 11))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    
                    HStack {
                        Text("Empty Weight")
                        Spacer()
                        DecimalField("Weight",
                                     value: $emptyWeight,
                                     formatter: numberFormatter(precision: 0, minimum: 0, maximum: maxLandingWeight),
                                     suffix: "lbs")
                        .accessibilityIdentifier("emptyWeightField")
                    }
                }.opacity(formOpacity)
                Spacer()
                
                Button("Continue") {
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
}

#Preview {
    WelcomeView()
}
