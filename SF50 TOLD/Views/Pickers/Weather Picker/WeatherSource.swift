import SF50_Shared
import SwiftUI

struct WeatherSource: View {
  @Environment(WeatherViewModel.self)
  private var weather

  private var downloadButtonTitle: String {
    if weather.error != nil { return String(localized: "Try Again") }
    switch weather.conditions.source {
      case .entered: return String(localized: "Use Downloaded Weather")
      default: return String(localized: "Update Weather")
    }
  }

  private var formattedForecast: Loadable<String?> {
    return weather.TAF.map { forecast in
      guard let forecast else { return nil }
      let words = forecast.split(separator: " ")
      var formatted = [[String]]()

      formatted.append([])
      for word in words {
        if word.starts(with: "FM") || word == "BECMG" {
          formatted.append([])
        }
        formatted[formatted.count - 1].append(String(word))
      }

      return formatted.map { $0.joined(separator: " ") }.joined(separator: "\n  ")
    }
  }

  var body: some View {
    Section("Source") {
      HStack {
        switch weather.conditions.source {
          case .NWS, .augmented:
            Text("Using downloaded weather from NWS")
              .font(.system(size: 14))
          case .WeatherKit:
            Text("Using downloaded weather from Apple Weather")
              .font(.system(size: 14))
          case .entered:
            Text("Using your custom weather")
              .font(.system(size: 14))
          case .ISA:
            if weather.error != nil {
              Text("Couldn’t load weather — using ISA")
                .font(.system(size: 14))
                .foregroundStyle(.red)
            } else {
              Text("Using ISA weather")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            }
        }

        Spacer()
        Button {
          Task { await weather.load(force: true) }
        } label: {
          Text(downloadButtonTitle)
            .foregroundStyle(Color.accentColor).bold()
        }.accessibilityIdentifier("updateWeatherButton")
      }

      RawWeather(rawText: weather.METAR)
      RawWeather(rawText: formattedForecast)
    }
  }
}

#Preview("NWS weather") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    let mockLoader = MockWeatherLoader(
      mockMETAR: .value(preview.METARString),
      mockTAF: .value(preview.TAFString)
    )
    let weatherViewModel = WeatherViewModel(
      operation: .takeoff,
      container: preview.container,
      loader: mockLoader
    )

    return List { WeatherSource() }
      .environment(weatherViewModel)
      .task { await mockLoader.setMockConditions(.value(preview.NWS)) }
  }
}

#Preview("Custom weather") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    let mockLoader = MockWeatherLoader(mockConditions: .value(preview.lightWinds))
    let weatherViewModel = WeatherViewModel(
      operation: .takeoff,
      container: preview.container,
      loader: mockLoader
    )

    return List { WeatherSource() }
      .environment(weatherViewModel)
  }
}

#Preview("Reset due to error") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    let httpResponse = HTTPURLResponse(
      url: URL(string: "https://example.com")!,
      statusCode: 500,
      httpVersion: nil,
      headerFields: nil
    )!
    let mockLoader = MockWeatherLoader(mockError: WeatherLoader.Errors.badResponse(httpResponse))
    let weatherViewModel = WeatherViewModel(
      operation: .takeoff,
      container: preview.container,
      loader: mockLoader
    )

    return List { WeatherSource() }
      .environment(weatherViewModel)
  }
}

#Preview("Observation error") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    let httpResponse = HTTPURLResponse(
      url: URL(string: "https://example.com")!,
      statusCode: 500,
      httpVersion: nil,
      headerFields: nil
    )!
    let mockLoader = MockWeatherLoader(
      mockMETAR: .error(WeatherLoader.Errors.badResponse(httpResponse))
    )
    let weatherViewModel = WeatherViewModel(
      operation: .takeoff,
      container: preview.container,
      loader: mockLoader
    )

    return List { WeatherSource() }
      .environment(weatherViewModel)
  }
}

#Preview("Forecast error") {
  PreviewView(insert: .KOAK) { preview in
    let runway = try preview.load(airportID: "OAK", runway: "28R")!
    preview.setTakeoff(runway: runway)

    let httpResponse = HTTPURLResponse(
      url: URL(string: "https://example.com")!,
      statusCode: 500,
      httpVersion: nil,
      headerFields: nil
    )!
    let mockLoader = MockWeatherLoader(
      mockTAF: .error(WeatherLoader.Errors.badResponse(httpResponse))
    )
    let weatherViewModel = WeatherViewModel(
      operation: .takeoff,
      container: preview.container,
      loader: mockLoader
    )

    return List { WeatherSource() }
      .environment(weatherViewModel)
  }
}
