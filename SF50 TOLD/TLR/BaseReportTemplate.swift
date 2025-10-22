import Defaults
import Foundation
import SF50_Shared
import SwiftHtml

#if canImport(UIKit)
  import UIKit
#endif

// MARK: - Base Report Template

class BaseReportTemplate<PerformanceType, ScenarioType> {
  // MARK: - Instance Properties

  let input: PerformanceInput
  let useAirportLocalTime: Bool

  let weightUnit: UnitMass
  let runwayLengthUnit: UnitLength
  let speedUnit: UnitSpeed
  let temperatureUnit: UnitTemperature
  let pressureUnit: UnitPressure

  var reportDateFormat: Date.FormatStyle {
    let displayTimeZone = TimeZone.displayTimeZone(
      for: nil,  // We'll use the actual Airport object when available
      useAirportLocalTime: useAirportLocalTime
    )
    return Date.FormatStyle(
      date: .omitted,
      time: .shortened,
      locale: Locale.current,
      calendar: Calendar.current,
      timeZone: displayTimeZone,
      capitalizationContext: .unknown
    )
    .month(.abbreviated)
    .day()
    .hour()
    .minute()
    .timeZone()
  }

  // MARK: - Initialization

  init(input: PerformanceInput, useAirportLocalTime: Bool = false) {
    self.input = input
    self.useAirportLocalTime = useAirportLocalTime

    // Read unit preferences once during initialization
    self.weightUnit = Defaults[.weightUnit]
    self.runwayLengthUnit = Defaults[.runwayLengthUnit]
    self.speedUnit = Defaults[.speedUnit]
    self.temperatureUnit = Defaults[.temperatureUnit]
    self.pressureUnit = Defaults[.pressureUnit]
  }

  // MARK: - Instance Methods

  func reportDateFormat(for airport: AirportInput?) -> Date.FormatStyle {
    let displayTimeZone: TimeZone
    if useAirportLocalTime {
      displayTimeZone = airport?.timeZone ?? .current
    } else {
      displayTimeZone = TimeZone(identifier: "UTC") ?? .current
    }
    return Date.FormatStyle(
      date: .omitted,
      time: .shortened,
      locale: Locale.current,
      calendar: Calendar.current,
      timeZone: displayTimeZone,
      capitalizationContext: .unknown
    )
    .month(.abbreviated)
    .day()
    .hour()
    .minute()
    .timeZone()
  }

  // MARK: - Template Methods (to be overridden)

  func reportTitle() -> String {
    fatalError("Subclasses must override reportTitle()")
  }

  func generateDataTable() -> Table {
    fatalError("Subclasses must override generateDataTable()")
  }

  func generateRunwaysTable(_: [RunwayInput: RunwayInfo]) -> Table {
    fatalError("Subclasses must override generateRunwaysTable(_:)")
  }

  func generatePerformanceTable(_: [RunwayInput: PerformanceType]) -> Table {
    fatalError("Subclasses must override generatePerformanceTable(_:)")
  }

  func extractPerformances(from _: ScenarioType) -> [RunwayInput: PerformanceType] {
    fatalError("Subclasses must override extractPerformances(from:)")
  }

  func extractScenarioName(from _: ScenarioType) -> String {
    fatalError("Subclasses must override extractScenarioName(from:)")
  }

  // MARK: - Common Rendering

  func render(runways: [RunwayInput: RunwayInfo], scenarios: [ScenarioType]) -> String {
    let aircraft = input.aircraftInfo
    let forecastDate = input.date
    let generatedAt = Date.now
    let title = reportTitle()

    let doc = Document(.html) {
      Html {
        generateHead(title: title)
        Body {
          generateHeader(
            title: title,
            aircraft: aircraft,
            forecastDate: forecastDate,
            generatedAt: generatedAt
          )

          H2(String(localized: "\(operationType()) Data"))
          generateDataTable()

          H3(String(localized: "Available Runways"))
          generateRunwaysTable(runways)

          generateScenarioSections(scenarios: scenarios)
        }
      }
    }

    return DocumentRenderer(minify: false, indent: 2).render(doc)
  }

  func operationType() -> String {
    fatalError("Subclasses must override operationType()")
  }

  // MARK: - Common HTML Components

  func generateHead(title: String) -> Head {
    Head {
      Title(title)
      Meta().charset("utf-8")
      Meta().name("viewport").content("width=device-width, initial-scale=1.0")
      Style(loadCSS(named: "normalize.css"))
      Style(loadCSS(named: "tlr.css"))
    }
  }

  @TagBuilder
  func generateHeader(
    title: String,
    aircraft: AircraftInfo,
    forecastDate: Date,
    generatedAt: Date
  ) -> Tag {
    let format = reportDateFormat(for: input.airport)
    H1(title)
    P(String(localized: "\(input.airport.locationID) • \(forecastDate, format: format)"))
      .class("h1-subtitle")
    P(
      String(
        localized:
          "\(aircraft.model) • BEW \(aircraft.emptyWeight.converted(to: weightUnit).formatted(.weight))"
      )
    )
    .class("h1-subtitle")
    P(formatWeatherSource())
      .class("h1-subtitle")
    P(String(localized: "Generated \(generatedAt, format: format)"))
      .class("h1-subtitle-small")
  }

  @TagBuilder
  func generateScenarioSections(scenarios: [ScenarioType]) -> Tag {
    for (index, scenario) in scenarios.enumerated() {
      let name = extractScenarioName(from: scenario)
      let performances = extractPerformances(from: scenario)
      let allInvalid = areAllPerformancesInvalid(performances)

      if index == 0 {
        // First scenario (Forecast Conditions) - always visible
        H3(String(localized: "\(operationType()) Performance • \(name)"))
          .class(allInvalid ? "scenario-invalid" : "")
        generatePerformanceTable(performances)
      } else {
        // Other scenarios - accordion
        accordionSection(
          id: "\(operationType().lowercased())-scenario-\(index)",
          title: String(localized: "\(operationType()) Performance • \(name)"),
          isInvalid: allInvalid
        ) {
          generatePerformanceTable(performances)
        }
      }
    }
  }

  // MARK: - Formatting Helpers

  func formatWeatherSource() -> String {
    let conditions = input.conditions
    let source = conditions.source
    let validTime = conditions.validTime

    switch source {
      case .NWS:
        // For NWS weather (METAR/TAF), show source and valid period
        let validPeriod = format(interval: validTime)
        return String(localized: "Weather: NWS (\(validPeriod))")

      case .WeatherKit:
        // For Apple WeatherKit, show source and valid period
        let validPeriod = format(interval: validTime)
        return String(localized: "Weather: Apple (\(validPeriod))")

      case .augmented:
        // For augmented weather (combination of sources), show valid period
        let validPeriod = format(interval: validTime)
        return String(localized: "Weather: Augmented (\(validPeriod))")

      case .ISA:
        return String(localized: "Weather: ISA")

      case .entered:
        return String(localized: "Weather: User")
    }
  }

  func format(interval: DateInterval) -> String {
    let start = interval.start
    let end = interval.end
    let duration = interval.duration
    let format = reportDateFormat(for: input.airport)

    // If duration is 1 hour or less, show as "Valid at [time]"
    if duration <= 3600 {
      return String(localized: "valid \(start, format: format)")
    }
    // Show as "Valid [start] to [end]"
    let startFormatted = start.formatted(format)
    let endFormatted = end.formatted(format)
    return String(localized: "valid \(startFormatted) to \(endFormatted)")
  }

  func format(windDirection direction: Measurement<UnitAngle>?, speed: Measurement<UnitSpeed>?)
    -> String
  {
    if let direction, let speed {
      return String(
        localized:
          "\(direction.asHeading, format: .heading)/\(speed.converted(to: speedUnit), format: .speed)"
      )
    }
    if let speed {
      return String(localized: "VRB/\(speed.converted(to: speedUnit), format: .speed)")
    }
    return String(localized: "calm")
  }

  func format(contamination: Contamination?) -> String {
    switch contamination {
      case .waterOrSlush(let depth):
        String(localized: "Water/Slush \(depth.converted(to: .inches), format: .depth)")
      case .slushOrWetSnow(let depth):
        String(localized: "Slush/Wet Snow \(depth.converted(to: .inches), format: .depth)")
      case .drySnow:
        String(localized: "Dry Snow")
      case .compactSnow:
        String(localized: "Compact Snow")
      case nil:
        String(localized: "Dry")
    }
  }

  func format(performanceDistance value: Value<PerformanceDistance>?) -> [Tag] {
    return format(value: value) { perfDist in
      let marginClass = perfDist.margin.value >= 0 ? "margin-positive" : "margin-negative"

      return [
        Text(
          perfDist.distance.converted(to: runwayLengthUnit).formatted(
            .measurement(width: .narrow, usage: .asProvided, numberFormatStyle: .length)
          )
        ),
        Span(
          String(
            localized:
              " (\(perfDist.margin.converted(to: runwayLengthUnit), format: .length(plusSign: true)))"
          )
        ).class(marginClass)
      ]
    }
  }

  func format<T>(value: Value<T>, formatter: (T) -> [Tag]) -> [Tag] {
    switch value {
      case .value(let v), .valueWithUncertainty(let v, _):
        return formatter(v)
      case .invalid:
        return [Span(String(localized: "Inv")).class("invalid")]
      case .notAvailable:
        return [Span(String(localized: "-")).class("not-available")]
      case .notAuthorized:
        return [Span(String(localized: "N/A")).class("invalid")]
      case .offscaleHigh:
        return [Span(String(localized: "N/A")).class("not-available")]
      case .offscaleLow:
        return [Span(String(localized: "N/A")).class("not-available")]
    }
  }

  func format<T>(value: Value<T>?, formatter: (T) -> [Tag]) -> [Tag] {
    guard let value else {
      return [Span(String(localized: "-")).class("not-available")]
    }

    return format(value: value, formatter: formatter)
  }

  func format(speed value: Value<Measurement<UnitSpeed>>?) -> [Tag] {
    format(value: value) { [Text($0.converted(to: speedUnit).formatted(.speed))] }
  }

  func format(slope value: Value<Measurement<UnitSlope>>?) -> [Tag] {
    format(value: value) { [Text($0.asGradient.formatted(.gradient))] }
  }

  func format(bool value: Value<Bool>?) -> [Tag] {
    format(value: value) { bool in
      [Text(String(localized: "\(bool ? "✓" : "✗")"))]
    }
  }

  // MARK: - Utility Methods

  func loadCSS(named name: String) -> String {
    #if canImport(UIKit)
      if let asset = NSDataAsset(name: name),
        let cssString = String(data: asset.data, encoding: .utf8)
      {
        return cssString
      }
    #endif
    return ""
  }

  func accordionSection(id: String, title: String, isInvalid: Bool = false, content: () -> Tag)
    -> Tag
  {
    Div {
      Input()
        .type(.checkbox)
        .id(id)
        .class("accordion-toggle")
      Label {
        H3(title)
          .class(isInvalid ? "scenario-invalid" : "")
      }
      .for(id)
      .class("accordion-header")
      Div(content())
        .class("accordion-content")
    }
    .class("accordion-item")
  }

  // MARK: - Performance Validation

  func areAllPerformancesInvalid(_ performances: [RunwayInput: PerformanceType]) -> Bool {
    guard !performances.isEmpty else { return true }

    // Check if all performances are invalid
    // This will be overridden or we'll check a common property
    for (_, performance) in performances {
      // Use mirror to check if the performance has an isValid property
      let mirror = Mirror(reflecting: performance)
      if let isValid = mirror.children.first(where: { $0.label == "isValid" })?.value as? Bool {
        if isValid {
          return false  // Found at least one valid performance
        }
      }
    }
    return true  // All performances are invalid
  }
}
