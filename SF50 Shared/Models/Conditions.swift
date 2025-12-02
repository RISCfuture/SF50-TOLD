import CoreLocation
import Foundation
import WeatherKit

private let standardTemperatureDegC = 15.04

/// Standard sea level pressure in hectopascals (ISA standard: 1013.25 hPa).
public let standardSeaLevelPressureHPa = 1013.25

/// Standard temperature at sea level (ISA standard: 15.04°C).
public let standardTemperature = Measurement(
  value: standardTemperatureDegC,
  unit: UnitTemperature.celsius
)

/// Standard sea level pressure (ISA standard: 1013.25 hPa / 29.92 inHg).
public let standardSeaLevelPressure = Measurement(
  value: standardSeaLevelPressureHPa,
  unit: UnitPressure.hectopascals
)

/// Atmospheric conditions used for performance calculations.
///
/// ``Conditions`` represents weather observations or forecasts including wind,
/// temperature, dewpoint, and pressure. Conditions can be sourced from METAR,
/// TAF, WeatherKit forecasts, or manually entered by the user.
///
/// ## Topics
///
/// ### Creating Conditions
///
/// - ``init(windDirection:windSpeed:temperature:seaLevelPressure:)``
/// - ``init(observation:)``
/// - ``init(forecast:)``
/// - ``init(weather:)-(CurrentWeather)``
/// - ``init()``
///
/// ### Wind Properties
///
/// - ``windDirection``
/// - ``windSpeed``
/// - ``windsCalm``
///
/// ### Temperature and Pressure
///
/// - ``temperature``
/// - ``dewpoint``
/// - ``seaLevelPressure``
/// - ``temperature(at:)``
/// - ``densityAltitude(elevation:)``
///
/// ### Metadata
///
/// - ``validTime``
/// - ``source``
/// - ``Source``
///
/// ### Combining Conditions
///
/// - ``adding(conditions:)``
/// - ``userModified(with:)``
public struct Conditions: Sendable, Equatable {
  /// Time interval during which these conditions are valid.
  public let validTime: DateInterval

  /// Data source for these conditions.
  public let source: Source

  /// Wind direction in degrees true, or `nil` for variable winds.
  public let windDirection: Measurement<UnitAngle>?

  /// Wind speed, or `nil` if not reported.
  public let windSpeed: Measurement<UnitSpeed>?

  /// Temperature, or `nil` if not reported.
  public let temperature: Measurement<UnitTemperature>?

  /// Dewpoint temperature, or `nil` if not reported.
  public let dewpoint: Measurement<UnitTemperature>?

  /// Sea level pressure, or `nil` if not reported.
  public let seaLevelPressure: Measurement<UnitPressure>?

  /// Whether winds are calm (less than 1 knot or not reported).
  public var windsCalm: Bool {
    windSpeed.map { $0.converted(to: .knots).value < 1 } ?? true
  }

  private init(
    validTime: DateInterval,
    source: Source,
    windDirection: Measurement<UnitAngle>?,
    windSpeed: Measurement<UnitSpeed>?,
    temperature: Measurement<UnitTemperature>?,
    dewpoint: Measurement<UnitTemperature>?,
    seaLevelPressure: Measurement<UnitPressure>?
  ) {
    self.validTime = validTime
    self.source = source
    self.windDirection = windDirection
    self.windSpeed = windSpeed
    self.temperature = temperature
    self.dewpoint = dewpoint
    self.seaLevelPressure = seaLevelPressure
  }

  /**
   * Creates conditions with manually entered values.
   *
   * - Parameters:
   *   - windDirection: Wind direction in degrees true.
   *   - windSpeed: Wind speed.
   *   - temperature: Temperature.
   *   - seaLevelPressure: Sea level pressure (altimeter setting).
   */
  public init(
    windDirection: Measurement<UnitAngle>? = nil,
    windSpeed: Measurement<UnitSpeed>? = nil,
    temperature: Measurement<UnitTemperature>? = nil,
    seaLevelPressure: Measurement<UnitPressure>? = nil
  ) {
    validTime = .init(start: .now, duration: 3600)
    self.windDirection = windDirection
    self.windSpeed = windSpeed
    self.temperature = temperature
    dewpoint = nil
    self.seaLevelPressure = seaLevelPressure
    source = .entered
  }

  /// Creates conditions from a METAR observation.
  public init(observation: METAR) {
    validTime = .init(start: observation.observationTime, duration: 3600)

    if let windDir = observation.windDirection {
      windDirection = .init(value: Double(windDir), unit: .degrees)
    } else {
      windDirection = nil  // VRB wind
    }
    windSpeed = .init(value: Double(observation.windSpeed), unit: .knots)

    temperature = observation.temperature.map { .init(value: $0, unit: .celsius) }
    dewpoint = observation.dewpoint.map { .init(value: $0, unit: .celsius) }

    // Prefer sea level pressure if available, otherwise use altimeter
    if let slp = observation.seaLevelPressure {
      seaLevelPressure = .init(value: slp, unit: .millibars)
    } else if let alt = observation.altimeter {
      seaLevelPressure = .init(value: alt, unit: .inchesOfMercury)
    } else {
      seaLevelPressure = nil
    }

    source = .NWS
  }

  /// Creates conditions from a TAF forecast, or `nil` if the forecast is invalid.
  public init?(forecast: TAF) {
    validTime = .init(start: forecast.validFrom, end: forecast.validTo)

    if let windDir = forecast.windDirection {
      windDirection = .init(value: Double(windDir), unit: .degrees)
    } else {
      windDirection = nil  // VRB wind
    }

    if let speed = forecast.windSpeed {
      windSpeed = .init(value: Double(speed), unit: .knots)
    } else {
      windSpeed = nil
    }

    temperature = nil
    dewpoint = nil

    if let alt = forecast.altimeter {
      seaLevelPressure = .init(value: alt, unit: .inchesOfMercury)
    } else {
      seaLevelPressure = nil
    }

    source = .NWS
  }

  /// Creates conditions from WeatherKit current weather.
  public init(weather: CurrentWeather) {
    validTime = .init(start: weather.date, duration: 3600)

    windDirection = weather.wind.direction
    windSpeed = weather.wind.speed
    temperature = weather.temperature
    dewpoint = weather.dewPoint
    seaLevelPressure = weather.pressure
    source = .WeatherKit
  }

  /// Creates conditions from WeatherKit hourly forecast.
  public init(weather: HourWeather) {
    validTime = .init(start: weather.date, duration: 3600)

    windDirection = weather.wind.direction
    windSpeed = weather.wind.speed
    temperature = weather.temperature
    dewpoint = weather.dewPoint
    seaLevelPressure = weather.pressure
    source = .WeatherKit
  }

  /// Creates ISA standard conditions (sea level, 15°C, 1013.25 hPa, calm winds).
  public init() {
    validTime = .init(start: .now, duration: 3600)
    windDirection = .init(value: 0, unit: .degrees)
    windSpeed = .init(value: 0, unit: .knots)
    temperature = standardTemperature
    dewpoint = nil
    seaLevelPressure = standardSeaLevelPressure
    source = .ISA
  }

  /// Returns conditions with missing values filled from WeatherKit current weather.
  func adding(weather: CurrentWeather) -> Self {
    .init(
      validTime: validTime,
      source: .augmented,
      windDirection: windDirection ?? weather.wind.direction,
      windSpeed: windSpeed ?? weather.wind.speed,
      temperature: temperature ?? weather.temperature,
      dewpoint: dewpoint ?? weather.dewPoint,
      seaLevelPressure: seaLevelPressure ?? weather.pressure
    )
  }

  /// Returns conditions with missing values filled from WeatherKit hourly forecast.
  func adding(weather: HourWeather) -> Self {
    .init(
      validTime: validTime,
      source: .augmented,
      windDirection: windDirection ?? weather.wind.direction,
      windSpeed: windSpeed ?? weather.wind.speed,
      temperature: temperature ?? weather.temperature,
      dewpoint: dewpoint ?? weather.dewPoint,
      seaLevelPressure: seaLevelPressure ?? weather.pressure
    )
  }

  /// Returns conditions with missing values filled from another conditions instance.
  public func adding(conditions: Self) -> Self {
    .init(
      validTime: validTime,
      source: conditions.source,
      windDirection: conditions.windDirection ?? windDirection,
      windSpeed: conditions.windSpeed ?? windSpeed,
      temperature: conditions.temperature ?? temperature,
      dewpoint: conditions.dewpoint ?? dewpoint,
      seaLevelPressure: conditions.seaLevelPressure ?? seaLevelPressure
    )
  }

  /// Returns conditions modified by user-entered values, changing the source to `.entered`.
  public func userModified(with conditions: Self) -> Self {
    .init(
      validTime: validTime,
      source: .entered,
      windDirection: conditions.windDirection ?? windDirection,
      windSpeed: conditions.windSpeed ?? windSpeed,
      temperature: conditions.temperature ?? temperature,
      dewpoint: conditions.dewpoint ?? dewpoint,
      seaLevelPressure: conditions.seaLevelPressure ?? seaLevelPressure
    )
  }

  /// Returns the temperature at the given elevation, using ISA lapse rate if not reported.
  public func temperature(at elevation: Measurement<UnitLength>) -> Measurement<UnitTemperature> {
    if source == .ISA {
      return ISATemperature(at: elevation)
    }
    return temperature ?? ISATemperature(at: elevation)
  }

  /// Calculates density altitude at the given elevation using NWS dry-air formula.
  public func densityAltitude(elevation: Measurement<UnitLength>) -> Measurement<UnitLength> {
    // NWS formula uses station pressure (actual pressure at the elevation), not altimeter setting
    let stationPressureInHg = absolutePressure(elevation: elevation)
      .converted(to: .inchesOfMercury).value
    let tempDegF = temperature(at: elevation).converted(to: .fahrenheit).value

    // NWS dry-air density altitude approximation
    let DA = 145442.16 * (1.0 - pow((17.326 * stationPressureInHg) / (459.67 + tempDegF), 0.235))

    return .init(value: DA, unit: .feet)
  }

  private func ISATemperature(at altitude: Measurement<UnitLength>) -> Measurement<UnitTemperature>
  {
    let altFt = altitude.converted(to: .feet).value
    let tempC = standardTemperatureDegC - 0.001978152 * altFt
    return .init(value: tempC, unit: .celsius)
  }

  private func absolutePressure(elevation: Measurement<UnitLength>) -> Measurement<UnitPressure> {
    let SLP = seaLevelPressure ?? .init(value: standardSeaLevelPressureHPa, unit: .hectopascals)
    return pressure(altimeter: SLP, altitude: elevation)
  }

  private func pressure(altimeter: Measurement<UnitPressure>, altitude: Measurement<UnitLength>)
    -> Measurement<UnitPressure>
  {
    let altHpa = altimeter.converted(to: .hectopascals).value
    let altM = altitude.converted(to: .meters).value

    let pressure = altHpa * pow(1.0 + altM * -0.0000225616, 5.25143)
    return .init(value: pressure, unit: .hectopascals)
  }

  /// Data source for weather conditions.
  public enum Source: Sendable {
    /// National Weather Service (METAR/TAF).
    case NWS
    /// Apple WeatherKit.
    case WeatherKit
    /// NWS data augmented with WeatherKit.
    case augmented
    /// International Standard Atmosphere defaults.
    case ISA
    /// Manually entered by user.
    case entered
  }
}
