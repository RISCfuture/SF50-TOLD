import SwiftUI

struct SettingsView: View {
    @ObservedObject var state: SettingsState
    
    var body: some View {
        NavigationView {
            Form {
                VStack(alignment: .leading) {
                    Toggle("Use Updated Thrust Schedule", isOn: $state.updatedThrustSchedule)
                    Text("Turn this setting on when flying a G2+ Vision Jet or one with SB5X-72-01 completed.")
                        .font(.system(size: 11))
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                HStack {
                    Text("Empty Weight")
                    Spacer()
                    DecimalField("Weight",
                                 value: $state.emptyWeight,
                                 formatter: numberFormatter(precision: 0, minimum: 0, maximum: maxLandingWeight),
                                 suffix: "lbs")
                }
                
                HStack {
                    Text("Fuel Density")
                    Spacer()
                    DecimalField("Density",
                                 value: $state.fuelDensity,
                                 formatter: numberFormatter(precision: 2, minimum: 0),
                                 suffix: "lbs/gal")
                }
                
                HStack {
                    Text("Safety Factor")
                    Spacer()
                    DecimalField("Factor",
                                 value: $state.safetyFactor,
                                 formatter: numberFormatter(precision: 1, minimum: 1.0))
                }
            }.navigationTitle("Settings")
        }.navigationViewStyle(navigationStyle)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(state: SettingsState())
    }
}
