import SwiftUI

struct WeatherForm: View {
    @EnvironmentObject var weather: WeatherState
    
    private let headingFormatter = numberFormatter(precision: 0, minimum: 0, maximum: 360)
    private let speedFormatter = numberFormatter(precision: 0, minimum: 0)
    private let tempFormatter = numberFormatter(precision: 0)
    private let altimeterFormatter = numberFormatter(precision: 2, minimum: 0)
    
    var body: some View {
        Section(header: Text("Customize Weather")) {
            HStack {
                Text("Winds")
                Spacer()
                DecimalField("Direction", value: $weather.windDirection, formatter: headingFormatter, suffix: "°T", onEditingChanged: { editing in
                    if editing { weather.source = .entered }
                })
                Text("@").foregroundColor(.secondary)
                DecimalField("Speed", value: $weather.windSpeed, formatter: speedFormatter, suffix: "kts.", onEditingChanged: { editing in
                    if editing { weather.source = .entered }
                })
                .frame(maxWidth: 70)
            }
            
            HStack {
                Text("Temperature")
                DecimalField("Temperature", value: $weather.userEditedTemperature, formatter: tempFormatter, suffix: "°C", onEditingChanged: { editing in
                    if editing { weather.source = .entered }
                })
                .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Altimeter")
                Spacer()
                DecimalField("Altimeter", value: $weather.altimeter, formatter: altimeterFormatter, suffix: "inHg", onEditingChanged: { editing in
                    if editing { weather.source = .entered }
                })
            }
        }
    }
}

struct WeatherForm_Previews: PreviewProvider {
    static var previews: some View {
        Form { WeatherForm().environmentObject(WeatherState()) }
    }
}
