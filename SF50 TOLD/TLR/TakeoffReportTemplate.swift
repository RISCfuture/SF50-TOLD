import Foundation
import SF50_Shared
import SwiftHtml

#if canImport(UIKit)
  import UIKit
#endif

// MARK: - Takeoff Report Template

class TakeoffReportTemplate: BaseReportTemplate<
  TakeoffRunwayPerformance, TakeoffPerformanceScenario
>
{

  // MARK: - Template Method Implementations

  override func reportTitle() -> String {
    String(localized: "Takeoff Report")
  }

  override func operationType() -> String {
    String(localized: "Takeoff")
  }

  override func extractPerformances(from scenario: TakeoffPerformanceScenario) -> [RunwayInput:
    TakeoffRunwayPerformance]
  {
    scenario.runways
  }

  override func extractScenarioName(from scenario: TakeoffPerformanceScenario) -> String {
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
          Th(String(localized: "TOW"))
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
        }
      }
    }
  }

  override func generateRunwaysTable(_ runways: [RunwayInput: RunwayInfo]) -> Table {
    Table {
      Thead {
        Tr {
          Th(String(localized: "Rwy"))
          Th(String(localized: "Length"))
          Th(String(localized: "MTOW"))
          Th(String(localized: "Limit"))
        }
      }
      Tbody {
        for (runwayInput, info) in runways.sorted(by: { $0.key < $1.key }) {
          Tr {
            Th(runwayInput.name)
            Td(runwayInput.length.converted(to: runwayLengthUnit).formatted(.length))
            Td(info.maxWeight.converted(to: weightUnit).formatted(.weight))
            Td(info.limitingFactor.rawValue)
          }
        }
      }
    }
  }

  override func generatePerformanceTable(_ performances: [RunwayInput: TakeoffRunwayPerformance])
    -> Table
  {
    Table {
      Thead {
        Tr {
          Th(String(localized: "Runway"))
          Th(String(localized: "Ground Run (margin)"))
          Th(String(localized: "Total Dist (margin)"))
          Th(String(localized: "Climb Rate"))
        }
      }
      Tbody {
        for (runwayInput, perf) in performances.sorted(by: { $0.key < $1.key }) {
          let rowClass = perf.isValid ? "" : "invalid"
          Tr {
            Th(runwayInput.name)

            // Ground Run
            Td {
              format(performanceDistance: perf.groundRun)
            }

            // Total Distance
            Td {
              format(performanceDistance: perf.totalDistance)
            }

            // Climb Rate
            Td(format(slope: perf.climbRate))
          }
          .class(rowClass)
        }
      }
    }
  }
}
