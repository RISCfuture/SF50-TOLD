import SF50_Shared
import Sentry
import SwiftUI

private enum PreviewError: Error {
  case runwayNotFound(String)
}

struct NOTAMView: View {
  @Bindable var notam: NOTAM
  let downloadedNOTAMs: [NOTAMResponse]
  let plannedTime: Date
  let performance: BasePerformanceViewModel

  @State private var error: Error?
  @State private var errorSheetPresented = false
  @State private var currentNOTAMIndex: Int = 0

  /// NOTAMs sorted with intelligent prioritization:
  /// 1. Apple Intelligence autofilled NOTAMs (at front with badge)
  /// 2. Currently effective aerodrome NOTAMs
  /// 3. Currently effective non-aerodrome NOTAMs
  /// 4. Future aerodrome NOTAMs (soonest first)
  /// 5. Future non-aerodrome NOTAMs (soonest first)
  /// 6. Expired NOTAMs (most recently expired first)
  private var sortedNOTAMs: [NOTAMResponse] {
    guard !downloadedNOTAMs.isEmpty else { return [] }

    return downloadedNOTAMs.sorted { lhs, rhs in
      let lhsUsed = notam.sourceNOTAMs.contains(lhs.notamId)
      let rhsUsed = notam.sourceNOTAMs.contains(rhs.notamId)

      // 1. Apple Intelligence: Autofilled NOTAMs always come first
      if lhsUsed != rhsUsed {
        return lhsUsed
      }

      // For remaining NOTAMs, prioritize by relevance
      let lhsEffectiveWindow = lhs.isEffective(within: plannedTime, windowInterval: 3600)
      let rhsEffectiveWindow = rhs.isEffective(within: plannedTime, windowInterval: 3600)
      let lhsExpired = lhs.hasExpired(before: plannedTime, windowInterval: 3600)
      let rhsExpired = rhs.hasExpired(before: plannedTime, windowInterval: 3600)
      let lhsAerodrome = lhs.isAerodromeRelated
      let rhsAerodrome = rhs.isAerodromeRelated

      // 2. Expired NOTAMs go to the back
      if lhsExpired != rhsExpired {
        return rhsExpired  // Non-expired comes first
      }

      // If both expired, show most recently expired first
      if lhsExpired && rhsExpired {
        if let lhsEnd = lhs.effectiveEnd, let rhsEnd = rhs.effectiveEnd {
          return lhsEnd > rhsEnd
        }
        return false
      }

      // 3. Effective NOTAMs come before future NOTAMs
      if lhsEffectiveWindow != rhsEffectiveWindow {
        return lhsEffectiveWindow
      }

      // 4. Within same effectiveness category, aerodrome NOTAMs come first
      if lhsAerodrome != rhsAerodrome {
        return lhsAerodrome
      }

      // 5. For effective NOTAMs, show newest first (most recently started)
      if lhsEffectiveWindow && rhsEffectiveWindow {
        return lhs.effectiveStart > rhs.effectiveStart
      }

      // 6. For future NOTAMs, show soonest to become effective first
      return lhs.effectiveStart < rhs.effectiveStart
    }
  }

  @Environment(\.operation)
  private var operation

  @Environment(\.presentationMode)
  private var presentationMode

  @Environment(\.modelContext)
  private var modelContext

  var body: some View {
    Form {
      // Auto-fill status section
      if notam.automaticallyCreated || performance.autoFillAvailable || performance.isParsingNOTAMs {
        Section {
          AutofillStatusRow(
            isAutomaticallyCreated: notam.automaticallyCreated,
            isParsing: performance.isParsingNOTAMs,
            onAutoFill: performance.autoFillAvailable ? {
              await performance.applyAutoFillNOTAM()
            } : nil
          )
        }
      }

      Section("Runway Restrictions") {
        RunwayShorteningView(notam: notam)
        if operation == .takeoff { ObstacleView(notam: notam) }
        if operation == .landing {
          ContaminationView(contamination: $notam.contamination)
        }
      }
      .onChange(of: notam.contamination) { _, _ in
        // Clear auto-created flag when user manually edits
        if notam.automaticallyCreated {
          notam.automaticallyCreated = false
          notam.isManuallyEdited = true
        }
      }

      Button("Clear NOTAMs") {
        notam.clearFor(operation: operation)
        presentationMode.wrappedValue.dismiss()
      }.accessibilityIdentifier("clearNOTAMsButton")

      if performance.isLoadingNOTAMs {
        Section("Downloading NOTAMs…") {
          HStack {
            Spacer()
            ProgressView()
            Spacer()
          }
          .listRowBackground(Color.clear)
        }
      } else if !downloadedNOTAMs.isEmpty {
        Section(
          "Downloaded NOTAMs (\(currentNOTAMIndex + 1, format: .number) of \(sortedNOTAMs.count, format: .number))"
        ) {
          VStack(spacing: 12) {
            // Carousel with card styling
            CarouselView(
              data: sortedNOTAMs,
              id: \.id,
              content: { notamResponse in
                let isUsedForAutofill = notam.sourceNOTAMs.contains(notamResponse.notamId)
                NOTAMListItemView(
                  notam: notamResponse,
                  plannedTime: plannedTime,
                  isUsedForAutofill: isUsedForAutofill
                )
                .padding()
                .if(isUsedForAutofill) { view in
                  view.appleIntelligenceStyle()
                }
                .if(!isUsedForAutofill) { view in
                  view
                    .background(
                      RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                    )
                }
                .padding(.horizontal, 8)
              },
              currentIndex: $currentNOTAMIndex
            )
            .frame(height: 300)

            // Smart page indicator
            CarouselIndicator(
              currentIndex: $currentNOTAMIndex,
              totalPages: sortedNOTAMs.count
            )
            .padding(.top, 4)
          }
          .listRowBackground(Color.clear)
        }
      }
    }
    .navigationTitle("NOTAMs")
    .onDisappear {
      do {
        try modelContext.save()
      } catch {
        SentrySDK.capture(error: error)
        self.error = error
        errorSheetPresented = true
      }
    }
    .alert(
      "Couldn’t Save NOTAM",
      isPresented: $errorSheetPresented,
      actions: {
        Button("OK") {
          errorSheetPresented = false
          error = nil
        }
      },
      message: {
        Text(error?.localizedDescription ?? "<no error>")
      }
    )
  }
}

#Preview("Many NOTAMs") {
  PreviewView(insert: .KOAK) { preview in
    guard let runway = try preview.load(airportID: "OAK", runway: "30") else {
      throw PreviewError.runwayNotFound("OAK/30")
    }
    let notam = try preview.addNOTAM(
      to: runway,
      shortenTakeoff: 500.0,
      obstacleHeight: 75,
      obstacleDistance: 0.25
    )
    // Mark first NOTAM as used for autofill
    notam.sourceNOTAMs = ["A8000/2025"]
    notam.automaticallyCreated = true

    let sampleNOTAMs = preview.generateNOTAMs(count: 23, baseTime: .now)
    let performance = TakeoffPerformanceViewModel(container: preview.container)

    return NOTAMView(
      notam: notam,
      downloadedNOTAMs: sampleNOTAMs,
      plannedTime: .now,
      performance: performance
    )
    .environment(\.operation, .takeoff)
  }
}

#Preview("Single NOTAM") {
  PreviewView(insert: .KOAK) { preview in
    guard let runway = try preview.load(airportID: "OAK", runway: "30") else {
      throw PreviewError.runwayNotFound("OAK/30")
    }
    let notam = try preview.addNOTAM(
      to: runway,
      shortenTakeoff: 500.0,
      obstacleHeight: 75,
      obstacleDistance: 0.25
    )
    notam.sourceNOTAMs = ["A8000/2025"]
    notam.automaticallyCreated = true

    let sampleNOTAMs = preview.generateNOTAMs(count: 1, baseTime: .now)
    let performance = TakeoffPerformanceViewModel(container: preview.container)

    return NOTAMView(
      notam: notam,
      downloadedNOTAMs: sampleNOTAMs,
      plannedTime: .now,
      performance: performance
    )
    .environment(\.operation, .takeoff)
  }
}

#Preview("No NOTAMs") {
  PreviewView(insert: .KOAK) { preview in
    guard let runway = try preview.load(airportID: "OAK", runway: "30") else {
      throw PreviewError.runwayNotFound("OAK/30")
    }
    let notam = try preview.addNOTAM(
      to: runway,
      shortenLanding: 500.0,
      contamination:
        .waterOrSlush(depth: .init(value: 0.2, unit: .inches))
    )

    let performance = LandingPerformanceViewModel(container: preview.container)

    return NOTAMView(
      notam: notam,
      downloadedNOTAMs: [],
      plannedTime: .now,
      performance: performance
    )
    .environment(\.operation, .landing)
  }
}
