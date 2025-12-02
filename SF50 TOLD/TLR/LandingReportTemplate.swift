import Foundation
import SF50_Shared
import SwiftHtml

#if canImport(UIKit)
  import UIKit
#endif

// MARK: - Landing Report Template

/// Renders landing performance data to HTML format.
///
/// ``LandingReportTemplate`` extends ``BaseReportTemplate`` with landing-specific
/// table layouts showing:
/// - Landing data (airport, runway, OAT, wind, QNH, LW, config)
/// - Runway analysis (ALD, MLW, limiting factor, condition)
/// - Performance tables (Vref, landing run, landing distance, go-around compliance)
class LandingReportTemplate: BaseReportTemplate<
  LandingRunwayPerformance, LandingPerformanceScenario
>
{

  // MARK: - Template Method Implementations

  override func reportTitle() -> String {
    String(localized: "Landing Report")
  }

  override func operationType() -> String {
    String(localized: "Landing")
  }

  override func extractPerformances(from scenario: LandingPerformanceScenario) -> [RunwayInput:
    LandingRunwayPerformance]
  {
    scenario.runways
  }

  override func extractScenarioName(from scenario: LandingPerformanceScenario) -> String {
    scenario.scenarioName
  }

  override func generateDataTable() -> Table {
    Table {
      Thead {
        Tr {
          Th(String(localized: "A/P"))
          Th(String(localized: "Rwy"))
          Th(String(localized: "OAT"))
          Th(String(localized: "Wind"))
          Th(String(localized: "QNH"))
          Th(String(localized: "LW"))
          Th(String(localized: "Config"))
        }
      }
      Tbody {
        Tr {
          Td(input.airport.locationID)
          Td(input.runway.name)
          Td(
            (input.conditions.temperature ?? standardTemperature).converted(to: temperatureUnit)
              .formatted(
                .temperature
              )
          )
          Td(
            format(windDirection: input.conditions.windDirection, speed: input.conditions.windSpeed)
          )
          Td(
            (input.conditions.seaLevelPressure ?? standardSeaLevelPressure)
              .converted(to: pressureUnit)
              .formatted(.airPressure)
          )
          Td(input.weight.converted(to: weightUnit).formatted(.weight))
          Td(SF50_TOLD.format(flapSetting: input.flapSetting, short: true))
        }
      }
    }
  }

  override func generateRunwaysTable(_ runways: [RunwayInput: RunwayInfo]) -> Table {
    Table {
      Thead {
        Tr {
          Th(String(localized: "Rwy"))
          Th(String(localized: "ALD"))
          Th(String(localized: "MLW"))
          Th(String(localized: "Limit"))
          Th(String(localized: "Cond"))
        }
      }
      Tbody {
        for (runwayInput, info) in runways.sorted(by: { $0.key < $1.key }) {
          Tr {
            Th(runwayInput.name)
            Td(runwayInput.length.converted(to: runwayLengthUnit).formatted(.length))
            Td(info.maxWeight.converted(to: weightUnit).formatted(.weight))
            Td(info.limitingFactor.rawValue)
            Td(format(contamination: info.contamination))
          }
        }
      }
    }
  }

  override func generatePerformanceTable(_ performances: [RunwayInput: LandingRunwayPerformance])
    -> Table
  {
    Table {
      Thead {
        Tr {
          Th(String(localized: "Rwy"))
          Th(String(localized: "VREF"))
          Th(String(localized: "Ldg Run (margin)"))
          Th(String(localized: "Ldg Dist (margin)"))
          Th(String(localized: "Meets G/A Req?"))
        }
      }
      Tbody {
        for (runwayInput, perf) in performances.sorted(by: { $0.key < $1.key }) {
          let rowClass = perf.isValid ? "" : "invalid"
          Tr {
            Th(runwayInput.name)
            Td(format(speed: perf.Vref))
            Td(format(performanceDistance: perf.landingRun))
            Td(format(performanceDistance: perf.landingDistance))
            Td(format(bool: perf.meetsGoAroundRequirement))
          }
          .class(rowClass)
        }
      }
    }
  }
}
