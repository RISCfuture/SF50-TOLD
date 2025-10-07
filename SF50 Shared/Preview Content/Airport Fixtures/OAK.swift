import SwiftData

extension AirportBuilder {
  public static let KOAK: Self = .init(
    airport: .init(
      recordID: "OAK",
      locationID: "OAK",
      ICAO_ID: "KOAK",
      name: "San Francisco Bay Area Metropolitan Oakland International Airport",
      city: "Oakland",
      dataSource: .NASR,
      latitude: .init(value: 37.7212614, unit: .degrees),
      longitude: .init(value: -122.2211506, unit: .degrees),
      elevation: .init(value: 9, unit: .feet),
      variation: .init(value: -14, unit: .degrees)
    ),
    runways: { airport in
      [
        .init(
          name: "12",
          elevation: .init(value: 8.3, unit: .feet),
          trueHeading: .init(value: 130, unit: .degrees),
          gradient: nil,
          length: .init(value: 10520, unit: .feet),
          takeoffRun: .init(value: 10000, unit: .feet),
          takeoffDistance: .init(value: 10000, unit: .feet),
          landingDistance: .init(value: 10000, unit: .feet),
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "30",
          elevation: .init(value: 9, unit: .feet),
          trueHeading: .init(value: 310, unit: .degrees),
          gradient: nil,
          length: .init(value: 10520, unit: .feet),
          takeoffRun: .init(value: 10000, unit: .feet),
          takeoffDistance: .init(value: 10520, unit: .feet),
          landingDistance: .init(value: 10000, unit: .feet),
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "10R",
          elevation: .init(value: 8, unit: .feet),
          trueHeading: .init(value: 112, unit: .degrees),
          gradient: nil,
          length: .init(value: 6213, unit: .feet),
          takeoffRun: .init(value: 6213, unit: .feet),
          takeoffDistance: .init(value: 6213, unit: .feet),
          landingDistance: .init(value: 6213, unit: .feet),
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "28L",
          elevation: .init(value: 8.2, unit: .feet),
          trueHeading: .init(value: 292, unit: .degrees),
          gradient: nil,
          length: .init(value: 6213, unit: .feet),
          takeoffRun: .init(value: 6213, unit: .feet),
          takeoffDistance: .init(value: 6213, unit: .feet),
          landingDistance: .init(value: 6213, unit: .feet),
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "10L",
          elevation: .init(value: 5.5, unit: .feet),
          trueHeading: .init(value: 112, unit: .degrees),
          gradient: nil,
          length: .init(value: 5457, unit: .feet),
          takeoffRun: .init(value: 5457, unit: .feet),
          takeoffDistance: .init(value: 5457, unit: .feet),
          landingDistance: .init(value: 5336, unit: .feet),
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "28R",
          elevation: .init(value: 5.8, unit: .feet),
          trueHeading: .init(value: 292, unit: .degrees),
          gradient: nil,
          length: .init(value: 5457, unit: .feet),
          takeoffRun: .init(value: 5457, unit: .feet),
          takeoffDistance: .init(value: 5457, unit: .feet),
          landingDistance: .init(value: 5457, unit: .feet),
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "15",
          elevation: .init(value: 1.4, unit: .feet),
          trueHeading: .init(value: 164, unit: .degrees),
          gradient: nil,
          length: .init(value: 3376, unit: .feet),
          takeoffRun: nil,
          takeoffDistance: nil,
          landingDistance: nil,
          isTurf: false,
          airport: airport
        ),
        .init(
          name: "33",
          elevation: .init(value: 3.9, unit: .feet),
          trueHeading: .init(value: 344, unit: .degrees),
          gradient: nil,
          length: .init(value: 3376, unit: .feet),
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
