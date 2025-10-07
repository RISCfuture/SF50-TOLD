extension AirportBuilder {
  public static let K1C9: Self = .init(
    airport: .init(
      recordID: "1C9",
      locationID: "1C9",
      ICAO_ID: nil,
      name: "Frazier Lake Airpark",
      city: "Hollister",
      dataSource: .NASR,
      latitude: .init(value: 36.9528333, unit: .degrees),
      longitude: .init(value: -121.4626389, unit: .degrees),
      elevation: .init(value: 152, unit: .feet),
      variation: .init(value: -15, unit: .degrees)
    ),
    runways: { airport in
      [
        .init(
          name: "5",
          elevation: .init(value: 152, unit: .feet),
          trueHeading: .init(value: 65, unit: .degrees),
          gradient: nil,
          length: .init(value: 2500, unit: .feet),
          takeoffRun: nil,
          takeoffDistance: nil,
          landingDistance: nil,
          isTurf: true,
          airport: airport
        ),
        .init(
          name: "23",
          elevation: .init(value: 153, unit: .feet),
          trueHeading: .init(value: 245, unit: .degrees),
          gradient: nil,
          length: .init(value: 2500, unit: .feet),
          takeoffRun: nil,
          takeoffDistance: nil,
          landingDistance: nil,
          isTurf: true,
          airport: airport
        )
      ]
    }
  )
}
