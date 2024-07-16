import SwiftUI
import Defaults

struct SettingsView: View {
    @Default(.updatedThrustSchedule) var updatedThrustSchedule
    @Default(.emptyWeight) var emptyWeight
    @Default(.fuelDensity) var fuelDensity
    @Default(.safetyFactor) var safetyFactor
    
    var body: some View {
        NavigationView {
            Form {
                VStack(alignment: .leading) {
                    Toggle("Use Updated Thrust Schedule", isOn: $updatedThrustSchedule)
                    Text("Turn this setting on when flying a G2+ Vision Jet or one with SB5X-72-01 completed.")
                        .font(.system(size: 11))
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityIdentifier("updatedThrustScheduleToggle")
                }
                
                HStack {
                    Text("Empty Weight")
                    Spacer()
                    DecimalField("Weight",
                                 value: $emptyWeight,
                                 formatter: numberFormatter(precision: 0, minimum: 0, maximum: maxLandingWeight),
                                 suffix: "lbs")
                    .accessibilityIdentifier("weightField")
                }
                
                HStack {
                    Text("Fuel Density")
                    Spacer()
                    DecimalField("Density",
                                 value: $fuelDensity,
                                 formatter: numberFormatter(precision: 2, minimum: 0),
                                 suffix: "lbs/gal")
                    .accessibilityIdentifier("fuelDensityField")
                }
                
                HStack {
                    Text("Safety Factor")
                    Spacer()
                    DecimalField("Factor",
                                 value: $safetyFactor,
                                 formatter: numberFormatter(precision: 1, minimum: 1.0))
                    .accessibilityIdentifier("safetyFactorField")
                }
            }.navigationTitle("Settings")
        }.navigationViewStyle(navigationStyle)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}
