import SwiftUI
import Defaults

struct SettingsView: View {
    @Default(.emptyWeight) var emptyWeight
    @Default(.fuelDensity) var fuelDensity
    @Default(.safetyFactor) var safetyFactor
    @Default(.g3Wing) var g3Wing
    
    var body: some View {
        NavigationView {
            Form {
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
                
                HStack {
                    Text("G3 Wing")
                    Spacer()
                    Toggle("", isOn: $g3Wing)
                        .accessibilityIdentifier("g3WingToggle")
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
