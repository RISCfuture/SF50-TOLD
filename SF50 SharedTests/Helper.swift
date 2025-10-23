import Foundation

@testable import SF50_Shared

enum Helper {

  static func createTestConditions(
    temperature: Double? = nil,
    windDirection: Double = 0,
    windSpeed: Double = 0
  ) -> Conditions {
    let temp = temperature.map { Measurement(value: $0, unit: UnitTemperature.celsius) }
    let windDir = Measurement(value: windDirection, unit: UnitAngle.degrees)
    let windSpd = Measurement(value: windSpeed, unit: UnitSpeed.knots)

    return Conditions(
      windDirection: windDir,
      windSpeed: windSpd,
      temperature: temp
    )
  }

  static func createTestConfiguration(
    weight: Double = 6000,
    flapSetting: FlapSetting = .flaps50,
    iceProtection: Bool = false
  ) -> Configuration {
    Configuration(
      weight: Measurement(value: weight, unit: UnitMass.pounds),
      flapSetting: flapSetting,
      iceProtection: iceProtection
    )
  }

  static func createTestAirport(elevation: Double = 0) -> Airport {
    Airport(
      recordID: "TEST",
      locationID: "TEST",
      ICAO_ID: "TEST",
      name: "Test Airport",
      city: "Test City",
      dataSource: .NASR,
      latitude: Measurement(value: 0, unit: .degrees),
      longitude: Measurement(value: 0, unit: .degrees),
      elevation: Measurement(value: elevation, unit: .feet),
      variation: Measurement(value: 0, unit: .degrees)
    )
  }

  static func createTestRunway(
    elevation: Double = 0,
    heading: Double = 360,
    slope: Double = 0,
    isTurf: Bool = false
  ) -> Runway {
    let airport = Self.createTestAirport(elevation: elevation)
    return Runway(
      name: "36",
      elevation: nil,
      trueHeading: Measurement(value: heading, unit: .degrees),
      gradient: Float(slope / 100),
      length: Measurement(value: 5000, unit: .feet),
      takeoffRun: nil,
      takeoffDistance: nil,
      landingDistance: nil,
      isTurf: isTurf,
      airport: airport
    )
  }

  static func createTestRunwayInput(
    elevation: Double = 0,
    heading: Double = 360,
    slope: Double = 0,
    isTurf: Bool = false
  ) -> RunwayInput {
    let runway = Self.createTestRunway(
      elevation: elevation,
      heading: heading,
      slope: slope,
      isTurf: isTurf
    )
    return RunwayInput(from: runway, airport: runway.airport)
  }
}
