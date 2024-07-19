import SwiftUI
import SwiftMETAR

struct WeatherSource: View {
    @ObservedObject var weather: WeatherState
    
    var downloadWeather: () -> Void
    
    private var downloadButtonTitle: String {
        if weather.resetDueToError { return "Try Again" }
        switch weather.source {
            case .ISA: return "Update Weather"
            case .downloaded: return "Update Weather"
            case .entered: return "Use Downloaded Weather"
        }
    }
    
    private var formattedForecast: String? {
        guard let forecast = weather.forecast else { return nil }
        let words = forecast.split(separator: " ")
        var formatted = Array<Array<String>>()
        
        formatted.append([])
        for word in words {
            if word.starts(with: "FM") || word == "BECMG" {
                formatted.append([])
            }
            formatted[formatted.count - 1].append(String(word))
        }
        
        return formatted.map { $0.joined(separator: " ") }.joined(separator: "\n  ")
    }
    
    var body: some View {
        Section(header: Text("Source")) {
            HStack {
                if weather.resetDueToError {
                    VStack(alignment: .leading) {
                        Text("Couldn’t load weather — using ISA")
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                    }
                } else {
                    switch weather.source {
                        case .downloaded:
                            Text("Using downloaded weather")
                                .font(.system(size: 14))
                        case .entered:
                            Text("Using your custom weather")
                                .font(.system(size: 14))
                        case .ISA:
                            Text("Using ISA weather")
                                .font(.system(size: 14))
                                .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                Button {
                    downloadWeather()
                } label: {
                    Text(downloadButtonTitle)
                        .foregroundColor(.accentColor).bold()
                }.accessibilityIdentifier("updateWeatherButton")
            }
            
            if let observation = weather.observation {
                RawWeather(rawText: observation, error: weather.observationError)
            }
            
            if let forecast = formattedForecast {
                RawWeather(rawText: forecast, error: weather.forecastError)
            }
        }
    }
}

#Preview {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "ddHHmm'Z'"
    dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
    
    let utcDate = dateFormatter.string(from: Date())
    
    let metar = "KSFO \(utcDate) 00000KT 10SM BKN180 18/13 A3010 RMK AO2 SLP192 T01830128 VISNO $"
    let taf = "KSFO \(utcDate) 1721/1824 VRB04KT P6SM SKC WS020/02025KT FM172200 31008KT P6SM SKC FM180100 28013KT P6SM FEW200 FM180800 28006KT P6SM FEW200 FM181000 VRB05KT P6SM SKC WS020/02030KT FM181500 36008KT P6SM SKC WS015/03030KT FM182000 36012KT P6SM SKC WS015/03035KT"
    
    return Form {
        WeatherSource(weather: WeatherState(date: Date(),
                                            observation: try! METAR.from(string: metar),
                                            forecast: try! TAF.from(string: taf)),
                      downloadWeather: {})
    }
}
