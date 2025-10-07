import Foundation
import Testing

@testable import SF50_Shared

@Suite("METAR XML Parser Tests")
struct METARXMLParserTests {

  @Test("Parse normal METAR with all fields")
  func parseNormalMETAR() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <METAR>
            <raw_text>METAR KLOT 021045Z 10005KT 10SM CLR 14/09 A3025</raw_text>
            <station_id>KLOT</station_id>
            <observation_time>2025-10-02T10:45:00.000Z</observation_time>
            <temp_c>14</temp_c>
            <dewpoint_c>9</dewpoint_c>
            <wind_dir_degrees>100</wind_dir_degrees>
            <wind_speed_kt>5</wind_speed_kt>
            <altim_in_hg>30.25</altim_in_hg>
            <sea_level_pressure_mb>1024.5</sea_level_pressure_mb>
          </METAR>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var observations: [(String, METAR)] = []

    for await observation in METARXMLParser.parse(data: data) {
      observations.append(observation)
    }

    #expect(observations.count == 1)
    let (stationID, obs) = observations[0]
    #expect(stationID == "KLOT")
    #expect(obs.temperature == 14.0)
    #expect(obs.dewpoint == 9.0)
    #expect(obs.windDirection == 100)
    #expect(obs.windSpeed == 5)
    #expect(obs.altimeter == 30.25)
    #expect(obs.seaLevelPressure == 1024.5)
    #expect(obs.rawText == "METAR KLOT 021045Z 10005KT 10SM CLR 14/09 A3025")
  }

  @Test("Parse METAR with VRB wind")
  func parseVRBWind() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <METAR>
            <raw_text>METAR KTEST 021045Z VRB02KT 10SM CLR 14/09 A3025</raw_text>
            <station_id>KTEST</station_id>
            <observation_time>2025-10-02T10:45:00.000Z</observation_time>
            <temp_c>14</temp_c>
            <dewpoint_c>9</dewpoint_c>
            <wind_dir_degrees>VRB</wind_dir_degrees>
            <wind_speed_kt>2</wind_speed_kt>
            <altim_in_hg>30.25</altim_in_hg>
          </METAR>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var observations: [(String, METAR)] = []

    for await observation in METARXMLParser.parse(data: data) {
      observations.append(observation)
    }

    #expect(observations.count == 1)
    let (_, obs) = observations[0]
    #expect(obs.windDirection == nil)  // VRB should be nil
    #expect(obs.windSpeed == 2)
  }

  @Test("Parse METAR with calm wind")
  func parseCalmWind() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <METAR>
            <raw_text>METAR KTEST 021045Z 00000KT 10SM CLR 14/09 A3025</raw_text>
            <station_id>KTEST</station_id>
            <observation_time>2025-10-02T10:45:00.000Z</observation_time>
            <temp_c>14</temp_c>
            <dewpoint_c>9</dewpoint_c>
            <wind_dir_degrees>0</wind_dir_degrees>
            <wind_speed_kt>0</wind_speed_kt>
            <altim_in_hg>30.25</altim_in_hg>
          </METAR>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var observations: [(String, METAR)] = []

    for await observation in METARXMLParser.parse(data: data) {
      observations.append(observation)
    }

    #expect(observations.count == 1)
    let (_, obs) = observations[0]
    #expect(obs.windDirection == 0)
    #expect(obs.windSpeed == 0)
  }

  @Test("Parse METAR with missing optional fields")
  func parseMissingFields() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <METAR>
            <raw_text>METAR KTEST 021045Z 10005KT 10SM CLR A3025</raw_text>
            <station_id>KTEST</station_id>
            <observation_time>2025-10-02T10:45:00.000Z</observation_time>
            <wind_dir_degrees>100</wind_dir_degrees>
            <wind_speed_kt>5</wind_speed_kt>
            <altim_in_hg>30.25</altim_in_hg>
          </METAR>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var observations: [(String, METAR)] = []

    for await observation in METARXMLParser.parse(data: data) {
      observations.append(observation)
    }

    #expect(observations.count == 1)
    let (_, obs) = observations[0]
    #expect(obs.temperature == nil)
    #expect(obs.dewpoint == nil)
    #expect(obs.seaLevelPressure == nil)
    #expect(obs.altimeter == 30.25)
  }

  @Test("Parse multiple METARs and continue on error")
  func parseMultipleMETARs() async throws {
    let xml = """
      <?xml version="1.0" encoding="UTF-8"?>
      <response>
        <data>
          <METAR>
            <raw_text>METAR KTEST1 021045Z 10005KT 10SM CLR 14/09 A3025</raw_text>
            <station_id>KTEST1</station_id>
            <observation_time>2025-10-02T10:45:00.000Z</observation_time>
            <temp_c>14</temp_c>
            <wind_dir_degrees>100</wind_dir_degrees>
            <wind_speed_kt>5</wind_speed_kt>
          </METAR>
          <METAR>
            <raw_text>INVALID METAR</raw_text>
          </METAR>
          <METAR>
            <raw_text>METAR KTEST2 021045Z 20010KT 10SM CLR 20/15 A3020</raw_text>
            <station_id>KTEST2</station_id>
            <observation_time>2025-10-02T10:45:00.000Z</observation_time>
            <temp_c>20</temp_c>
            <wind_dir_degrees>200</wind_dir_degrees>
            <wind_speed_kt>10</wind_speed_kt>
          </METAR>
        </data>
      </response>
      """

    let data = xml.data(using: .utf8)!
    var observations: [(String, METAR)] = []

    for await observation in METARXMLParser.parse(data: data) {
      observations.append(observation)
    }

    // Should parse 2 valid METARs, skip invalid one
    #expect(observations.count == 2)
    #expect(observations[0].0 == "KTEST1")
    #expect(observations[1].0 == "KTEST2")
  }
}
