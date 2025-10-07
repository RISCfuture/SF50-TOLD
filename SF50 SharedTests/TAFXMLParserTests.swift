import Foundation
import Testing

@testable import SF50_Shared

@Suite("TAF XML Parser Tests")
struct TAFXMLParserTests {

  @Test("Parse TAF with multiple forecast periods")
  func parseMultipleForecasts() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <TAF>
            <raw_text><![CDATA[TAF KTEST 021044Z 0211/0306 34007KT P6SM FEW035]]></raw_text>
            <station_id>KTEST</station_id>
            <forecast>
              <fcst_time_from>2025-10-02T11:00:00.000Z</fcst_time_from>
              <fcst_time_to>2025-10-02T14:00:00.000Z</fcst_time_to>
              <wind_dir_degrees>340</wind_dir_degrees>
              <wind_speed_kt>7</wind_speed_kt>
            </forecast>
            <forecast>
              <fcst_time_from>2025-10-02T14:00:00.000Z</fcst_time_from>
              <fcst_time_to>2025-10-03T00:00:00.000Z</fcst_time_to>
              <wind_dir_degrees>40</wind_dir_degrees>
              <wind_speed_kt>12</wind_speed_kt>
              <wind_gust_kt>20</wind_gust_kt>
            </forecast>
          </TAF>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var tafs: [(String, TAFData)] = []

    for await taf in TAFXMLParser.parse(data: data) {
      tafs.append(taf)
    }

    #expect(tafs.count == 1)
    let (stationID, tafData) = tafs[0]
    #expect(stationID == "KTEST")
    #expect(tafData.forecasts.count == 2)
    #expect(tafData.rawText == "TAF KTEST 021044Z 0211/0306 34007KT P6SM FEW035")

    let forecast1 = tafData.forecasts[0]
    #expect(forecast1.windDirection == 340)
    #expect(forecast1.windSpeed == 7)
    #expect(forecast1.windGust == nil)

    let forecast2 = tafData.forecasts[1]
    #expect(forecast2.windDirection == 40)
    #expect(forecast2.windSpeed == 12)
    #expect(forecast2.windGust == 20)
  }

  @Test("Parse TAF with VRB wind")
  func parseVRBWind() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <TAF>
            <raw_text><![CDATA[TAF KTEST 021044Z 0211/0306 VRB05KT P6SM]]></raw_text>
            <station_id>KTEST</station_id>
            <forecast>
              <fcst_time_from>2025-10-02T11:00:00.000Z</fcst_time_from>
              <fcst_time_to>2025-10-03T06:00:00.000Z</fcst_time_to>
              <wind_dir_degrees>VRB</wind_dir_degrees>
              <wind_speed_kt>5</wind_speed_kt>
            </forecast>
          </TAF>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var tafs: [(String, TAFData)] = []

    for await taf in TAFXMLParser.parse(data: data) {
      tafs.append(taf)
    }

    #expect(tafs.count == 1)
    let (_, tafData) = tafs[0]
    #expect(tafData.forecasts.count == 1)
    #expect(tafData.forecasts[0].windDirection == nil)  // VRB should be nil
    #expect(tafData.forecasts[0].windSpeed == 5)
  }

  @Test("Parse TAF with altimeter")
  func parseAltimeter() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <TAF>
            <raw_text><![CDATA[TAF KTEST 021044Z 0211/0306 32005KT P6SM QNH2993INS]]></raw_text>
            <station_id>KTEST</station_id>
            <forecast>
              <fcst_time_from>2025-10-02T11:00:00.000Z</fcst_time_from>
              <fcst_time_to>2025-10-03T06:00:00.000Z</fcst_time_to>
              <wind_dir_degrees>320</wind_dir_degrees>
              <wind_speed_kt>5</wind_speed_kt>
              <altim_in_hg>29.93</altim_in_hg>
            </forecast>
          </TAF>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var tafs: [(String, TAFData)] = []

    for await taf in TAFXMLParser.parse(data: data) {
      tafs.append(taf)
    }

    #expect(tafs.count == 1)
    let (_, tafData) = tafs[0]
    #expect(tafData.forecasts[0].altimeter == 29.93)
  }

  @Test("Parse TAF with missing optional fields")
  func parseMissingFields() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <TAF>
            <raw_text><![CDATA[TAF KTEST 021044Z 0211/0306]]></raw_text>
            <station_id>KTEST</station_id>
            <forecast>
              <fcst_time_from>2025-10-02T11:00:00.000Z</fcst_time_from>
              <fcst_time_to>2025-10-03T06:00:00.000Z</fcst_time_to>
            </forecast>
          </TAF>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var tafs: [(String, TAFData)] = []

    for await taf in TAFXMLParser.parse(data: data) {
      tafs.append(taf)
    }

    #expect(tafs.count == 1)
    let (_, tafData) = tafs[0]
    #expect(tafData.forecasts.count == 1)
    #expect(tafData.forecasts[0].windDirection == nil)
    #expect(tafData.forecasts[0].windSpeed == nil)
    #expect(tafData.forecasts[0].altimeter == nil)
  }

  @Test("Parse multiple TAFs and continue on error")
  func parseMultipleTAFs() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <TAF>
            <raw_text><![CDATA[TAF KTEST1 021044Z 0211/0306]]></raw_text>
            <station_id>KTEST1</station_id>
            <forecast>
              <fcst_time_from>2025-10-02T11:00:00.000Z</fcst_time_from>
              <fcst_time_to>2025-10-03T06:00:00.000Z</fcst_time_to>
              <wind_dir_degrees>100</wind_dir_degrees>
              <wind_speed_kt>10</wind_speed_kt>
            </forecast>
          </TAF>
          <TAF>
            <raw_text><![CDATA[INVALID TAF]]></raw_text>
          </TAF>
          <TAF>
            <raw_text><![CDATA[TAF KTEST2 021044Z 0211/0306]]></raw_text>
            <station_id>KTEST2</station_id>
            <forecast>
              <fcst_time_from>2025-10-02T11:00:00.000Z</fcst_time_from>
              <fcst_time_to>2025-10-03T06:00:00.000Z</fcst_time_to>
              <wind_dir_degrees>200</wind_dir_degrees>
              <wind_speed_kt>15</wind_speed_kt>
            </forecast>
          </TAF>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var tafs: [(String, TAFData)] = []

    for await taf in TAFXMLParser.parse(data: data) {
      tafs.append(taf)
    }

    // Should parse 2 valid TAFs, skip invalid one
    #expect(tafs.count == 2)
    #expect(tafs[0].0 == "KTEST1")
    #expect(tafs[1].0 == "KTEST2")
  }
}
