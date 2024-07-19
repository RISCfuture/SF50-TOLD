import SwiftUI

fileprivate func windString(_ conditions: Weather, compact: Bool = false) -> String {
    if conditions.wind == Wind.calm {
        return "calm"
    }
    
    let dir = integerFormatter.string(for: conditions.wind.direction)
    let speed = integerFormatter.string(for: conditions.wind.speed)
    return compact ? "\(dir)@\(speed)" : "\(dir)° @ \(speed) kt"
}

fileprivate func tempString(_ conditions: Weather, elevation: Double, compact: Bool = false) -> String {
    let temp = integerFormatter.string(for: conditions.temperature(at: elevation))
    return compact ? temp : "\(temp) °C"
}

fileprivate func densityAltString(_ conditions: Weather, elevation: Double, compact: Bool = false) -> String {
    let daStr = integerFormatter.string(for: conditions.densityAltitude(elevation: elevation))
    return compact ? daStr : "\(daStr) ft"
}

struct WeatherRow: View {
    @ObservedObject var conditions: WeatherState
    var elevation: Double
    
    var windColor: Color { conditions.source == .ISA ? .secondary : .primary }
    var tempColor: Color {
        if conditions.weather.temperature(at: elevation) > maxTemperature { return .red }
        if conditions.weather.temperature(at: elevation) < minTemperature { return .red }
        return conditions.source == .ISA ? .secondary : .primary
    }
    var daColor: Color {
        if conditions.weather.densityAltitude(elevation: elevation) > 15000 { return .red }
        return conditions.source == .ISA ? .secondary : .primary
    }
    
    var body: some View {
        if conditions.loading {
            HStack(spacing: 10) {
                ProgressView().progressViewStyle(CircularProgressViewStyle())
                Text("Loading weather…").foregroundColor(.secondary)
                    .accessibilityIdentifier("loadingWeatherLabel")
            }
        } else if conditions.source == .ISA {
            if conditions.observationError != nil || conditions.forecastError != nil {
                Text("Couldn’t load weather — using ISA").foregroundColor(.red)
                    .accessibilityIdentifier("loadingWeatherFailedLabel")
            } else {
                Text("No weather — using ISA").foregroundColor(.secondary)
                    .accessibilityIdentifier("noWeatherLabel")
            }
        } else {
            HStack(spacing: 15) {
                Label(windString(conditions.weather), systemImage: "wind")
                //                    .labelStyle(CompactLabelStyle(compact: windString(conditions.weather, compact: true)))
                    .foregroundColor(windColor)
                Label(tempString(conditions.weather, elevation: elevation), systemImage: "thermometer")
                //                    .labelStyle(CompactLabelStyle(compact: tempString(conditions.weather, elevation: elevation, compact: true)))
                    .foregroundColor(tempColor)
                Label(densityAltString(conditions.weather, elevation: elevation), image: "Mountain")
                //                    .labelStyle(CompactLabelStyle(compact: densityAltString(conditions.weather, elevation: elevation, compact: true)))
                    .foregroundColor(daColor)
            }
            .font(.system(size: 14))
            .accessibilityIdentifier("weatherSummary")
        }
        
        
    }
}

#Preview {
    WeatherRow(conditions: WeatherState.init(wind: .calm,
                                             temperature: .value(9),
                                             altimeter: 29.97,
                                             source: .downloaded),
               elevation: 0.0)
}
