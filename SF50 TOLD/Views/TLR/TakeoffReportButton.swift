import Defaults
import SF50_Shared
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
      // Allow UI to update with loading state
      try? await Task.sleep(nanoseconds: 100_000_000)

      // Capture snapshots and settings on main actor
      let airportSnapshot = AirportInput(from: airport)
      let runwaySnapshot = RunwayInput(from: runway, airport: airport)
      let conditions = performance.conditions
      let weight = performance.weight
      let flapSetting = performance.flapSetting
      let safetyFactor = Defaults[.safetyFactor]
      let useRegressionModel = Defaults[.useRegressionModel]
      let updatedThrustSchedule = Defaults[.updatedThrustSchedule]
      let emptyWeight = Defaults[.emptyWeight]
      let date = weather.time

      do {
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
        let generatedHTML = try generateTakeoffReport(input: input)

        await MainActor.run {
          reportToShow = HTMLReport(html: generatedHTML)
          isGenerating = false
        }
      } catch {
        await MainActor.run {
          self.error = error
          isGenerating = false
        }
      }
    }
  }
}
