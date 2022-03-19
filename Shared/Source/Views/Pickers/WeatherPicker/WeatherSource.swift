import SwiftUI

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
                }
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

struct WeatherSource_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            WeatherSource(weather: WeatherState(), downloadWeather: {})
        }
    }
}
