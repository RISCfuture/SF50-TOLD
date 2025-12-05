import Defaults
import SF50_Shared
import Sentry
import SwiftData
import SwiftUI

private struct HTMLReport: Identifiable {
  let id = UUID()
  let html: String
}

struct LandingReportButton: View {
  @Environment(LandingPerformanceViewModel.self)
  private var performance
  @Environment(WeatherViewModel.self)
  private var weather
  @Environment(\.modelContext)
  private var modelContext

  @State private var reportToShow: HTMLReport?
  @State private var isGenerating = false
  @State private var error: Error?

  private var container: ModelContainer {
    modelContext.container
  }

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
          Text("Generate Landing Report…")
        }
      }
    }
    .accessibilityIdentifier("generateLandingReportButton")
    .disabled(!canGenerateReport || isGenerating)
    .sheet(item: $reportToShow) { report in
      HTMLReportViewer(
        htmlContent: report.html,
        reportTitle: "Landing Report"
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
        // Fetch scenarios using ModelActor in background context
        let fetcher = ScenarioFetcher(modelContainer: container),
          scenarios = try await fetcher.fetchLandingScenarios()

        // Allow UI to update with loading state
        try await Task.sleep(nanoseconds: 100_000_000)

        // Capture snapshots and settings on main actor
        let airportSnapshot = AirportInput(from: airport),
          runwaySnapshot = RunwayInput(from: runway, airport: airport),
          conditions = performance.conditions,
          weight = performance.weight,
          flapSetting = performance.flapSetting,
          safetyFactor =
            runwaySnapshot.notam?.contamination != nil
            ? Defaults[.safetyFactorWet] : Defaults[.safetyFactorDry],
          useRegressionModel = Defaults[.useRegressionModel],
          aircraftType = Defaults.Keys.aircraftType,
          emptyWeight = Defaults[.emptyWeight],
          date = weather.time

        // Now run the report generation in the background
        let input = PerformanceInput(
          airport: airportSnapshot,
          runway: runwaySnapshot,
          conditions: conditions,
          weight: weight,
          flapSetting: flapSetting,
          safetyFactor: safetyFactor,
          useRegressionModel: useRegressionModel,
          aircraftType: aircraftType,
          emptyWeight: emptyWeight,
          date: date
        )
        let generatedHTML = try generateLandingReport(input: input, scenarios: scenarios)

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
