import Foundation

/// Sendable snapshot of NOTAM data for background performance calculations
public struct NOTAMSnapshot: Sendable, Equatable {
  public let contaminationType: String?
  public let contaminationDepth: Measurement<UnitLength>
  public let takeoffDistanceShortening: Measurement<UnitLength>
  public let landingDistanceShortening: Measurement<UnitLength>
  public let obstacleHeight: Measurement<UnitLength>
  public let obstacleDistance: Measurement<UnitLength>

  public var contamination: Contamination? {
    guard let type = contaminationType else { return nil }
    return Contamination(type: type, depth: contaminationDepth.converted(to: .meters).value)
  }

  public init(from notam: NOTAM) {
    self.contaminationType = notam.contamination?.type
    self.contaminationDepth = .init(value: notam.contamination?.depth ?? 0, unit: .meters)
    self.takeoffDistanceShortening = notam.takeoffDistanceShortening
    self.landingDistanceShortening = notam.landingDistanceShortening
    self.obstacleHeight = notam.obstacleHeight
    self.obstacleDistance = notam.obstacleDistance
  }

  public init(
    contaminationType: String?,
    contaminationDepth: Measurement<UnitLength>,
    takeoffDistanceShortening: Measurement<UnitLength>,
    landingDistanceShortening: Measurement<UnitLength>,
    obstacleHeight: Measurement<UnitLength>,
    obstacleDistance: Measurement<UnitLength>
  ) {
    self.contaminationType = contaminationType
    self.contaminationDepth = contaminationDepth
    self.takeoffDistanceShortening = takeoffDistanceShortening
    self.landingDistanceShortening = landingDistanceShortening
    self.obstacleHeight = obstacleHeight
    self.obstacleDistance = obstacleDistance
  }
}

/// Sendable snapshot of Runway data for background performance calculations
public struct RunwayInput: Identifiable, Hashable, Sendable, Comparable {
  // MARK: - Properties

  public let id: String

  public let elevation: Measurement<UnitLength>
  public let trueHeading: Measurement<UnitAngle>
  public let gradient: Float
  public let length: Measurement<UnitLength>
  public let takeoffRun: Measurement<UnitLength>?
  public let takeoffDistance: Measurement<UnitLength>
  public let landingDistance: Measurement<UnitLength>?
  public let isTurf: Bool
  public let notam: NOTAMSnapshot?
  public let airportVariation: Measurement<UnitAngle>

  public var name: String { id }

  // MARK: - Initialization

  public init(from runway: Runway, airport: Airport) {
    self.id = runway.name
    self.elevation = runway.elevationOrAirportElevation
    self.trueHeading = runway.trueHeading
    self.gradient = runway.gradientOrBestGuess
    self.length = runway.length
    self.takeoffRun = runway.takeoffRun
    self.takeoffDistance = runway.notamedTakeoffDistance
    self.landingDistance = runway.landingDistance
    self.isTurf = runway.isTurf
    self.notam = runway.notam.map { NOTAMSnapshot(from: $0) }
    self.airportVariation = airport.variation
  }

  public init(
    id: String,
    elevation: Measurement<UnitLength>,
    trueHeading: Measurement<UnitAngle>,
    gradient: Float,
    length: Measurement<UnitLength>,
    takeoffRun: Measurement<UnitLength>?,
    takeoffDistance: Measurement<UnitLength>,
    landingDistance: Measurement<UnitLength>?,
    isTurf: Bool,
    notam: NOTAMSnapshot?,
    airportVariation: Measurement<UnitAngle>
  ) {
    self.id = id
    self.elevation = elevation
    self.trueHeading = trueHeading
    self.gradient = gradient
    self.length = length
    self.takeoffRun = takeoffRun
    self.takeoffDistance = takeoffDistance
    self.landingDistance = landingDistance
    self.isTurf = isTurf
    self.notam = notam
    self.airportVariation = airportVariation
  }

  // MARK: - Type Methods

  // Comparable implementation for sorting
  public static func < (lhs: Self, rhs: Self) -> Bool {
    let num1 = Int(lhs.name.filter(\.isNumber)) ?? 0
    let num2 = Int(rhs.name.filter(\.isNumber)) ?? 0

    if num1 != num2 {
      return num1 < num2
    }

    // If numbers are equal, compare the letters
    let letter1 = lhs.name.filter(\.isLetter)
    let letter2 = rhs.name.filter(\.isLetter)

    // Order: no letter < L < C < R
    let letterOrder = ["": 0, "L": 1, "C": 2, "R": 3]
    let val1 = letterOrder[letter1] ?? 4
    let val2 = letterOrder[letter2] ?? 4

    return val1 < val2
  }

  // MARK: - Instance Methods

  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  public func headwind(conditions: Conditions) -> Measurement<UnitSpeed> {
    guard let windDirection = conditions.windDirection,
      let windSpeed = conditions.windSpeed
    else {
      return .init(value: 0, unit: .knots)
    }

    // Wind direction in METAR/TAF is in true degrees, runway heading is also true
    let windDirectionDeg = windDirection.converted(to: .degrees).value
    let runwayTrueHeadingDeg = trueHeading.converted(to: .degrees).value

    let angleDiff = windDirectionDeg - runwayTrueHeadingDeg
    let headwindComponent = cos(angleDiff * .pi / 180) * windSpeed.converted(to: .knots).value

    return .init(value: headwindComponent, unit: .knots)
  }

  /// Creates a copy of this runway with contamination override applied
  public func withContamination(_ contamination: Contamination?) -> Self {
    let newNotam: NOTAMSnapshot?
    if let notam {
      // Create a new NOTAM with the contamination override but keep other values
      newNotam = NOTAMSnapshot(
        contaminationType: contamination?.type,
        contaminationDepth: .init(value: contamination?.depth ?? 0, unit: .meters),
        takeoffDistanceShortening: notam.takeoffDistanceShortening,
        landingDistanceShortening: notam.landingDistanceShortening,
        obstacleHeight: notam.obstacleHeight,
        obstacleDistance: notam.obstacleDistance
      )
    } else if let contamination {
      // Create a new NOTAM with just the contamination
      newNotam = NOTAMSnapshot(
        contaminationType: contamination.type,
        contaminationDepth: .init(value: contamination.depth ?? 0, unit: .meters),
        takeoffDistanceShortening: .init(value: 0, unit: .meters),
        landingDistanceShortening: .init(value: 0, unit: .meters),
        obstacleHeight: .init(value: 0, unit: .meters),
        obstacleDistance: .init(value: 0, unit: .meters)
      )
    } else {
      newNotam = nil
    }

    return Self(
      id: id,
      elevation: elevation,
      trueHeading: trueHeading,
      gradient: gradient,
      length: length,
      takeoffRun: takeoffRun,
      takeoffDistance: takeoffDistance,
      landingDistance: landingDistance,
      isTurf: isTurf,
      notam: newNotam,
      airportVariation: airportVariation
    )
  }
}

/// Sendable snapshot of Airport data for background performance calculations
public struct AirportInput: Sendable {
  public let recordID: String
  public let locationID: String
  public let name: String
  public let elevation: Measurement<UnitLength>
  public let variation: Measurement<UnitAngle>
  public let timeZone: TimeZone?
  public let runways: [RunwayInput]

  public init(from airport: Airport) {
    self.recordID = airport.recordID
    self.locationID = airport.locationID
    self.name = airport.name
    self.elevation = airport.elevation
    self.variation = airport.variation
    self.timeZone = airport.timeZone
    self.runways = airport.runways.map { RunwayInput(from: $0, airport: airport) }
  }
}
