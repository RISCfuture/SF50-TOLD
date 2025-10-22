import Defaults
import SF50_Shared
import Sentry
import SwiftData
import SwiftUI

private struct HTMLReport: Identifiable {
  let id = UUID()
  let html: String
}

struct TakeoffReportButton: View {
  @Environment(TakeoffPerformanceViewModel.self)
  private var performance
  @Environment(WeatherViewModel.self)
  private var weather
  @Environment(\.modelContext)
  private var modelContext

  @State private var reportToShow: HTMLReport?
  @State private var isGenerating = false
  @State private var error: Error?

  var body: some View {
    Button {
      generateReport()
    } label: {
      HStack {
        if isGenerating {
          ProgressView()
            .controlSize(.small)
          Text("Generating…")
            .foregroundStyle(.secondary)
        } else {
          Text("Generate Takeoff Report…")
        }
      }
    }
    .accessibilityIdentifier("generateTakeoffReportButton")
    .disabled(!canGenerateReport || isGenerating)
    .sheet(item: $reportToShow) { report in
      HTMLReportViewer(
        htmlContent: report.html,
        reportTitle: "Takeoff Report"
      )
    }
    .sheet(
      item: Binding(
        get: { error.map { IdentifiableError(error: $0) } },
        set: { _ in error = nil }
      )
    ) { identifiableError in
      ErrorSheet(error: identifiableError.error)
    }
  }

  private var canGenerateReport: Bool {
    performance.airport != nil && performance.runway != nil
  }

  private func generateReport() {
    guard let airport = performance.airport,
      let runway = performance.runway
    else {
      return
    }

    isGenerating = true

    Task {
      do {
        // Allow UI to update with loading state
        try await Task.sleep(nanoseconds: 100_000_000)

        // Capture snapshots and settings on main actor
        let airportSnapshot = AirportInput(from: airport)
        let runwaySnapshot = RunwayInput(from: runway, airport: airport)
        let conditions = performance.conditions
        let weight = performance.weight
        let flapSetting = performance.flapSetting
        let safetyFactor =
          runwaySnapshot.notam?.contamination != nil
          ? Defaults[.safetyFactorWet] : Defaults[.safetyFactorDry]
        let useRegressionModel = Defaults[.useRegressionModel]
        let updatedThrustSchedule = Defaults[.updatedThrustSchedule]
        let emptyWeight = Defaults[.emptyWeight]
        let date = weather.time

        // Fetch and convert scenarios from SwiftData
        let descriptor = FetchDescriptor<Scenario>(
          predicate: #Predicate { $0._operation == "takeoff" },
          sortBy: [SortDescriptor(\.name)]
        )
        let scenarioModels = try modelContext.fetch(descriptor)
        let userScenarios = scenarioModels.map { PerformanceScenario.from($0) }

        // Always prepend "Forecast Conditions" scenario (base conditions with no adjustments)
        let forecastScenario = PerformanceScenario(name: "Forecast Conditions")
        let scenarios = [forecastScenario] + userScenarios

        // Now run the report generation in the background
        let input = PerformanceInput(
          airport: airportSnapshot,
          runway: runwaySnapshot,
          conditions: conditions,
          weight: weight,
          flapSetting: flapSetting,
          safetyFactor: safetyFactor,
          useRegressionModel: useRegressionModel,
          updatedThrustSchedule: updatedThrustSchedule,
          emptyWeight: emptyWeight,
          date: date
        )
        let generatedHTML = try generateTakeoffReport(input: input, scenarios: scenarios)

        await MainActor.run {
          reportToShow = HTMLReport(html: generatedHTML)
          isGenerating = false
        }
      } catch {
        SentrySDK.capture(error: error)
        await MainActor.run {
          self.error = error
          isGenerating = false
        }
      }
    }
  }
}
