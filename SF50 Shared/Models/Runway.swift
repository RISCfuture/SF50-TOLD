import Foundation
import SwiftData

/// A runway at an airport with performance-critical dimensions and properties.
///
/// `Runway` represents a single runway direction with associated metadata including
/// length, elevation, heading, gradient, and declared distances for takeoff and landing.
@Model
public final class Runway {
  /// Runway identifier (e.g., "28L", "09", "16R")
  public var name: String

  private var _elevation: Double?  // meters
  private var _trueHeading: Double  // degrees

  /// Runway gradient as a fraction (positive = upslope, negative = downslope)
  public var gradient: Float?  // fraction

  private var _length: Double  // meters
  private var _takeoffRun: Double?  // meters
  private var _takeoffDistance: Double?  // meters
  private var _landingDistance: Double?  // meters

  /// Whether the runway surface is turf (grass) rather than paved
  public var isTurf: Bool

  /// The airport this runway belongs to
  @Relationship(deleteRule: .nullify, inverse: \Airport.runways)
  public var airport: Airport

  /// Active NOTAM affecting this runway
  @Relationship(deleteRule: .cascade, inverse: \NOTAM.runway)
  public var notam: NOTAM?

  /// The reciprocal runway (opposite direction on same surface)
  @Relationship(deleteRule: .nullify)
  public var reciprocal: Runway?

  #Unique<Runway>([\.airport, \.name])

  /// Runway threshold elevation above sea level
  public var elevation: Measurement<UnitLength>? {
    get { _elevation.map { .init(value: $0, unit: .meters) } }
    set { _elevation = newValue?.converted(to: .meters).value }
  }

  /// Runway true heading in degrees
  public var trueHeading: Measurement<UnitAngle> {
    get { .init(value: _trueHeading, unit: .degrees) }
    set { _trueHeading = newValue.converted(to: .degrees).value }
  }

  /// Total runway length
  public var length: Measurement<UnitLength> {
    get { .init(value: _length, unit: .meters) }
    set { _length = newValue.converted(to: .meters).value }
  }

  /// Declared takeoff run available (TORA)
  public var takeoffRun: Measurement<UnitLength>? {
    get { _takeoffRun.map { .init(value: $0, unit: .meters) } }
    set { _takeoffRun = newValue?.converted(to: .meters).value }
  }

  /// Declared takeoff distance available (TODA)
  public var takeoffDistance: Measurement<UnitLength>? {
    get { _takeoffDistance.map { .init(value: $0, unit: .meters) } }
    set { _takeoffDistance = newValue?.converted(to: .meters).value }
  }

  /// Declared landing distance available (LDA)
  public var landingDistance: Measurement<UnitLength>? {
    get { _landingDistance.map { .init(value: $0, unit: .meters) } }
    set { _landingDistance = newValue?.converted(to: .meters).value }
  }

  /// Returns runway elevation, or airport elevation if runway elevation is not available
  public var elevationOrAirportElevation: Measurement<UnitLength> { elevation ?? airport.elevation }

  /// Returns runway gradient, or estimates it from reciprocal runway elevation if available
  public var gradientOrBestGuess: Float {
    if let gradient { return gradient }
    guard let reciprocal else { return 0 }

    let myEndElevation = elevationOrAirportElevation
    let otherEndElevation = reciprocal.elevationOrAirportElevation

    return Float((otherEndElevation - myEndElevation) / length)
  }

  /// Returns declared TORA, or total length if TORA is not declared
  public var takeoffRunOrLength: Measurement<UnitLength> { takeoffRun ?? length }

  /// Returns declared TODA, or total length if TODA is not declared
  public var takeoffDistanceOrLength: Measurement<UnitLength> { takeoffDistance ?? length }

  /// Returns declared LDA, or total length if LDA is not declared
  public var landingDistanceOrLength: Measurement<UnitLength> { landingDistance ?? length }

  public var magneticHeading: Measurement<UnitAngle> { trueHeading + airport.variation }

  public var notamedTakeoffDistance: Measurement<UnitLength> {
    if let shortening = notam?.takeoffDistanceShortening {
      takeoffDistanceOrLength - shortening
    } else {
      takeoffDistanceOrLength
    }
  }

  public var notamedTakeoffRun: Measurement<UnitLength> {
    if let shortening = notam?.takeoffDistanceShortening {
      takeoffRunOrLength - shortening
    } else {
      takeoffRunOrLength
    }
  }

  public var notamedLandingDistance: Measurement<UnitLength> {
    if let shortening = notam?.landingDistanceShortening {
      landingDistanceOrLength - shortening
    } else {
      landingDistanceOrLength
    }
  }

  public var hasTakeoffDistanceNOTAM: Bool { notam?.takeoffDistanceShortening.value ?? 0 > 0 }

  public var hasLandingDistanceNOTAM: Bool { notam?.landingDistanceShortening.value ?? 0 > 0 }

  public init(
    name: String,
    elevation: Measurement<UnitLength>?,
    trueHeading: Measurement<UnitAngle>,
    gradient: Float?,
    length: Measurement<UnitLength>,
    takeoffRun: Measurement<UnitLength>?,
    takeoffDistance: Measurement<UnitLength>?,
    landingDistance: Measurement<UnitLength>?,
    isTurf: Bool,
    airport: Airport
  ) {
    self.name = name
    _elevation = elevation?.converted(to: .meters).value
    _trueHeading = trueHeading.converted(to: .degrees).value
    self.gradient = gradient
    _length = length.converted(to: .meters).value
    _takeoffRun = takeoffRun?.converted(to: .meters).value
    _takeoffDistance = takeoffDistance?.converted(to: .meters).value
    _landingDistance = landingDistance?.converted(to: .meters).value
    self.isTurf = isTurf
    self.airport = airport
    reciprocal = nil
    notam = nil
  }

  public func headwind(conditions: Conditions) -> Measurement<UnitSpeed> {
    guard let windDirection = conditions.windDirection,
      let windSpeed = conditions.windSpeed
    else { return .init(value: 0, unit: .knots) }
    let angle = windDirection - trueHeading
    return windSpeed * cos(angle)
  }

  public func crosswind(conditions: Conditions) -> Measurement<UnitSpeed> {
    guard let windDirection = conditions.windDirection,
      let windSpeed = conditions.windSpeed
    else { return .init(value: 0, unit: .knots) }
    let angle = windDirection - trueHeading
    return windSpeed * sin(angle)
  }
}
