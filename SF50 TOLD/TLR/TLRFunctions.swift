import Defaults
import SF50_Shared

func generateTakeoffReport(input: PerformanceInput) throws -> String {
  let reportData = TakeoffReportData(input: input)
  let output = try reportData.generate()

  let useAirportLocalTime = Defaults[.useAirportLocalTime]
  let template = TakeoffReportTemplate(input: input, useAirportLocalTime: useAirportLocalTime)
  return template.render(runways: output.runwayInfo, scenarios: output.scenarios)
}

func generateLandingReport(input: PerformanceInput) throws -> String {
  let reportData = LandingReportData(input: input)
  let output = try reportData.generate()

  let useAirportLocalTime = Defaults[.useAirportLocalTime]
  let template = LandingReportTemplate(input: input, useAirportLocalTime: useAirportLocalTime)
  return template.render(runways: output.runwayInfo, scenarios: output.scenarios)
}

func format(flapSetting setting: FlapSetting, short: Bool = false) -> String {
  if short {
    switch setting {
      case .flapsUp: return String(localized: "Up")
      case .flapsUpIce: return String(localized: "Up ICE")
      case .flaps50: return String(localized: "50")
      case .flaps50Ice: return String(localized: "50 ICE")
      case .flaps100: return String(localized: "100")
    }
  } else {
    switch setting {
      case .flapsUp: return String(localized: "Flaps Up")
      case .flapsUpIce: return String(localized: "Flaps Up ICE")
      case .flaps50: return String(localized: "Flaps 50")
      case .flaps50Ice: return String(localized: "Flaps 50 ICE")
      case .flaps100: return String(localized: "Flaps 100")
    }
  }
}
