import SwiftData

extension AirportBuilder {
  public static let KSQL: Self = .init(
    airport: .init(
      recordID: "SQL",
      locationID: "SQL",
      ICAO_ID: "KSQL",
      name: "San Carlos Airport",
      city: "San Carlos",
      dataSource: .NASR,
      latitude: .init(value: 37.5118611, unit: .degrees),
      longitude: .init(value: -122.2495311, unit: .degrees),
      elevation: .init(value: 5.5, unit: .feet),
      variation: .init(value: -15, unit: .degrees)
    ),
    runways: { airport in
      [
        .init(
          name: "30",
          elevation: .init(value: 5.1, unit: .feet),
          trueHeading: .init(value: 318, unit: .degrees),
          gradient: nil,
          length: .init(value: 2621, unit: .feet),
          takeoffRun: nil,
          takeoffDistance: nil,
          landingDistance: nil,
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "12",
          elevation: .init(value: 5.0, unit: .feet),
          trueHeading: .init(value: 138, unit: .degrees),
          gradient: nil,
          length: .init(value: 2621, unit: .feet),
          takeoffRun: nil,
          takeoffDistance: nil,
          landingDistance: nil,
          isTurf: false,
          airport: airport
        )
      ]
    }
  )
}
