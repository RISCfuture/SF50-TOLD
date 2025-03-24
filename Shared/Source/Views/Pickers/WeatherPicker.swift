import SwiftUI
import CoreData

struct WeatherPicker: View {
    @ObservedObject var state: WeatherState
    
    var downloadWeather: () -> Void
    var cancelDownload: () -> Void
    var elevation: Float? = nil
    
    private var densityAltitude: Double? {
        elevation.map { state.weather.densityAltitude(elevation: Double($0)) }
    }
    
    var body: some View {
        Form {
            if state.loading  {
                HStack(spacing: 10) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                    Text("Loading weather…").foregroundColor(.secondary)
                    Spacer()
                    Button("Cancel") { cancelDownload() }.accessibilityIdentifier("cancelWeatherUpdateButton")
                }
            } else {
                WeatherSource(weather: state, downloadWeather: downloadWeather)
                WeatherForm(weather: state)
                if let densityAltitude {
                    Text("Density altitude: \(integerFormatter.string(for: densityAltitude)) ft")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
        }.navigationTitle("Weather")
    }
}

#Preview {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "ddHHmm'Z'"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let utcDate = dateFormatter.string(from: Date())
    
    let weather = WeatherState(wind: .init(direction: 280, speed: 15),
                               temperature: .value(-5),
                               altimeter: 30.12,
                               source: .downloaded,
                               observation: "KSFO \(utcDate) 00000KT 10SM FEW200 19/08 A3004 RMK AO2 SLP173 T01940078",
                               forecast: "KSFO \(utcDate) 1721/1824 VRB04KT P6SM SKC WS020/02025KT FM172200 31008KT P6SM SKC FM180100 28013KT P6SM FEW200 FM180800 28006KT P6SM FEW200 FM181000 VRB05KT P6SM SKC WS020/02030KT FM181500 36008KT P6SM SKC WS015/03030KT FM182000 36012KT P6SM SKC WS015/03035KT")
    
    return WeatherPicker(state: weather, downloadWeather: {}, cancelDownload: {}, elevation: 1234)
}
