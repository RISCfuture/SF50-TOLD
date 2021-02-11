import SwiftUI
import CoreData

struct WeatherPicker: View {
    var downloadWeather: () -> Void
    var elevation: Float? = nil
    @EnvironmentObject var state: WeatherState
    
    private var densityAltitude: Double? {
        guard let elevation = self.elevation else { return nil }
        return state.weather.densityAltitude(elevation: Double(elevation))
    }
    
    var body: some View {
        Form {
            if WeatherService.instance.loading  {
                HStack(spacing: 10) {
                    ProgressView().progressViewStyle(CircularProgressViewStyle())
                    Text("Loading weather…").foregroundColor(.secondary)
                }
            } else {
                WeatherSource(downloadWeather: downloadWeather)
                WeatherForm()
                if let densityAltitude = densityAltitude {
                    Text("Density altitude: \(integerFormatter.string(for: densityAltitude)) ft.")
                        .foregroundColor(.secondary)
                        .font(.system(size: 14))
                }
            }
        }.navigationTitle("Weather")
    }
}

struct WeatherPicker_Previews: PreviewProvider {
    static let weather = WeatherState(wind: .init(direction: 280, speed: 15),
                                      temperature: .value(-5),
                                      altimeter: 30.12,
                                      source: .downloaded,
                                      observation: "KSFO 172156Z 00000KT 10SM FEW200 19/08 A3004 RMK AO2 SLP173 T01940078",
                                      forecast: "KSFO 172057Z 1721/1824 VRB04KT P6SM SKC WS020/02025KT FM172200 31008KT P6SM SKC FM180100 28013KT P6SM FEW200 FM180800 28006KT P6SM FEW200 FM181000 VRB05KT P6SM SKC WS020/02030KT FM181500 36008KT P6SM SKC WS015/03030KT FM182000 36012KT P6SM SKC WS015/03035KT")
    
    static var previews: some View {
        WeatherPicker(downloadWeather: {}, elevation: 1234)
            .environmentObject(weather)
    }
}
