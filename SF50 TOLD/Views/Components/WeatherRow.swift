import Defaults
import SF50_Shared
import SwiftUI

private let maxDA = Measurement(value: 15_000, unit: UnitLength.feet)

struct WeatherRow: View {
  var elevation: Measurement<UnitLength>

  @Default(.updatedThrustSchedule)
  private var updatedThrustSchedule

  @Environment(WeatherViewModel.self)
  private var weather

  private var limitations: Limitations.Type {
    updatedThrustSchedule ? LimitationsG2Plus.self : LimitationsG1.self
  }

  var body: some View {
    if weather.isLoading {
      HStack(spacing: 10) {
        ProgressView().progressViewStyle(CircularProgressViewStyle())
        Text("Loading weather…").foregroundStyle(.secondary)
          .accessibilityIdentifier("loadingWeatherLabel")
      }
    } else if weather.error != nil {
      Text("Couldn’t load weather — using ISA").foregroundStyle(.red)
        .accessibilityIdentifier("loadingWeatherFailedLabel")
    } else if weather.conditions.source == .ISA {
      Text("No weather — using ISA").foregroundStyle(.secondary)
        .accessibilityIdentifier("noWeatherLabel")
    } else {
      LoadedWeatherRow(
        conditions: weather.conditions,
        elevation: elevation,
        minTemperature: limitations.minTemperature,
        maxTemperature: limitations.maxTemperature
      )
    }
  }
}

private struct LoadedWeatherRow: View {
  var conditions: Conditions
  var elevation: Measurement<UnitLength>

  var minTemperature: Measurement<UnitTemperature>?
  var maxTemperature: Measurement<UnitTemperature>?

  var windColor: Color { conditions.source == .ISA ? .secondary : .primary }
  var tempColor: Color {
    if let maxTemperature,
      conditions.temperature(at: elevation) > maxTemperature
    {
      return .red
    }
    if let minTemperature,
      conditions.temperature(at: elevation) < minTemperature
    {
      return .red
    }
    return conditions.source == .ISA ? .secondary : .primary
  }
  var DAColor: Color {
    if conditions.densityAltitude(elevation: elevation) > maxDA {
      return .red
    }
    return conditions.source == .ISA ? .secondary : .primary
  }

  var body: some View {
    HStack(spacing: 20) {
      IconWithLabel {
        WindText(conditions: conditions)
      } icon: {
        Image(systemName: "wind").accessibilityLabel("Wind")
      }
      .foregroundStyle(windColor)

      IconWithLabel {
        Text(conditions.temperature(at: elevation).asTemperature, format: .temperature)
      } icon: {
        Image(systemName: "thermometer").accessibilityLabel("Temperature")
      }
      .foregroundStyle(tempColor)

      IconWithLabel {
        Text(conditions.densityAltitude(elevation: elevation).asHeight, format: .height)
      } icon: {
        Image(systemName: "mountain.2").accessibilityLabel("Density Altitude")
      }
      .foregroundStyle(DAColor)
    }
    .font(.system(size: 14))
    .accessibilityIdentifier("weatherSummary")
  }
}

private struct IconWithLabel<VI: View, VL: View>: View {
  var label: () -> VL
  var icon: () -> VI

  var body: some View {
    HStack(spacing: 8) {
      icon()
      label()
    }
  }
}

private struct WindText: View {
  var conditions: Conditions

  var body: some View {
    if conditions.windsCalm {
      Text("calm", comment: "wind speed")
    } else if let windDirection = conditions.windDirection,
      let windSpeed = conditions.windSpeed
    {
      Text(
        "\(windDirection.asHeading, format: .heading) @ \(windSpeed.asSpeed, format: .speed)",
        comment: "wind direction @ speed"
      )
    } else {
      Text("calm", comment: "wind speed")
    }
  }
}

#Preview {
  PreviewView(insert: .KSQL) { preview in
    let url = URL(string: "https://example.com")!
    let httpResponse = HTTPURLResponse(
      url: url,
      statusCode: 404,
      httpVersion: "1.1",
      headerFields: [:]
    )!
    let badResponse = WeatherLoader.Errors.badResponse(httpResponse)

    return List {
      Section("Weather") {
        let mockLoader = MockWeatherLoader()
        let weather = WeatherViewModel(
          operation: .takeoff,
          container: preview.container,
          loader: mockLoader
        )
        WeatherRow(elevation: .init(value: 0.0, unit: .feet))
          .environment(weather)
          .onAppear { weather.conditions = preview.lightWinds }
      }
      Section("High DA") {
        let mockLoader = MockWeatherLoader()
        let weather = WeatherViewModel(
          operation: .takeoff,
          container: preview.container,
          loader: mockLoader
        )
        WeatherRow(elevation: .init(value: 15_000.0, unit: .feet))
          .environment(weather)
          .onAppear { weather.conditions = preview.lightWinds }
      }
      Section("Below Min Temp") {
        let mockLoader = MockWeatherLoader()
        let weather = WeatherViewModel(
          operation: .takeoff,
          container: preview.container,
          loader: mockLoader
        )
        WeatherRow(elevation: .init(value: 0.0, unit: .feet))
          .environment(weather)
          .onAppear { weather.conditions = preview.veryCold }
      }
      Section("Above Max Temp") {
        let mockLoader = MockWeatherLoader()
        let weather = WeatherViewModel(
          operation: .takeoff,
          container: preview.container,
          loader: mockLoader
        )
        WeatherRow(elevation: .init(value: 0.0, unit: .feet))
          .environment(weather)
          .onAppear { weather.conditions = preview.veryHot }
      }
      Section("ISA") {
        let mockLoader = MockWeatherLoader()
        let weather = WeatherViewModel(
          operation: .takeoff,
          container: preview.container,
          loader: mockLoader
        )
        WeatherRow(elevation: .init(value: 0.0, unit: .feet))
          .environment(weather)
          .onAppear { weather.conditions = preview.ISA }
      }
      Section("Loading") {
        let mockLoader = MockWeatherLoader()
        let weather = WeatherViewModel(
          operation: .takeoff,
          container: preview.container,
          loader: mockLoader
        )
        WeatherRow(elevation: .init(value: 0.0, unit: .feet))
          .environment(weather)
          .task {
            await mockLoader.setMockConditions(.loading)
          }
      }
      Section("Error") {
        let mockLoader = MockWeatherLoader()
        let weather = WeatherViewModel(
          operation: .takeoff,
          container: preview.container,
          loader: mockLoader
        )
        WeatherRow(elevation: .init(value: 0.0, unit: .feet))
          .environment(weather)
          .task {
            await mockLoader.setMockError(badResponse)
          }
      }
    }
  }
}
