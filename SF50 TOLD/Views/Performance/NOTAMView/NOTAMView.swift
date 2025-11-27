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
  let isLoadingNOTAMs: Bool

  @State private var error: Error?
  @State private var errorSheetPresented = false
  @State private var currentNOTAMIndex: Int = 0

  /// NOTAMs sorted with intelligent prioritization:
  /// 1. Currently effective aerodrome NOTAMs
  /// 2. Currently effective non-aerodrome NOTAMs
  /// 3. Future aerodrome NOTAMs (soonest first)
  /// 4. Future non-aerodrome NOTAMs (soonest first)
  /// 5. Expired NOTAMs (most recently expired first)
  private var sortedNOTAMs: [NOTAMResponse] {
    guard !downloadedNOTAMs.isEmpty else { return [] }

    return downloadedNOTAMs.sorted { lhs, rhs in
      // Prioritize by relevance
      let lhsEffectiveWindow = lhs.isEffective(within: plannedTime, windowInterval: 3600)
      let rhsEffectiveWindow = rhs.isEffective(within: plannedTime, windowInterval: 3600)
      let lhsExpired = lhs.hasExpired(before: plannedTime, windowInterval: 3600)
      let rhsExpired = rhs.hasExpired(before: plannedTime, windowInterval: 3600)
      let lhsAerodrome = lhs.isAerodromeRelated
      let rhsAerodrome = rhs.isAerodromeRelated

      // 1. Expired NOTAMs go to the back
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

      // 2. Effective NOTAMs come before future NOTAMs
      if lhsEffectiveWindow != rhsEffectiveWindow {
        return lhsEffectiveWindow
      }

      // 3. Within same effectiveness category, aerodrome NOTAMs come first
      if lhsAerodrome != rhsAerodrome {
        return lhsAerodrome
      }

      // 4. For effective NOTAMs, show newest first (most recently started)
      if lhsEffectiveWindow && rhsEffectiveWindow {
        return lhs.effectiveStart > rhs.effectiveStart
      }

      // 5. For future NOTAMs, show soonest to become effective first
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
      RunwayShorteningView(notam: notam)
      if operation == .takeoff { ObstacleView(notam: notam) }
      if operation == .landing {
        ContaminationView(contamination: $notam.contamination)
      }

      Button("Clear NOTAMs") {
        notam.clearFor(operation: operation)
        presentationMode.wrappedValue.dismiss()
      }.accessibilityIdentifier("clearNOTAMsButton")

      if isLoadingNOTAMs {
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
                NOTAMListItemView(
                  notam: notamResponse,
                  plannedTime: plannedTime
                )
                .padding()
                .background(
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
                )
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

    let sampleNOTAMs = preview.generateNOTAMs(count: 23, baseTime: .now)

    return NOTAMView(
      notam: notam,
      downloadedNOTAMs: sampleNOTAMs,
      plannedTime: .now,
      isLoadingNOTAMs: false
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

    let sampleNOTAMs = preview.generateNOTAMs(count: 1, baseTime: .now)

    return NOTAMView(
      notam: notam,
      downloadedNOTAMs: sampleNOTAMs,
      plannedTime: .now,
      isLoadingNOTAMs: false
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

    return NOTAMView(
      notam: notam,
      downloadedNOTAMs: [],
      plannedTime: .now,
      isLoadingNOTAMs: false
    )
    .environment(\.operation, .landing)
  }
}

#Preview("Loading") {
  PreviewView(insert: .KOAK) { preview in
    guard let runway = try preview.load(airportID: "OAK", runway: "30") else {
      throw PreviewError.runwayNotFound("OAK/30")
    }
    let notam = try preview.addNOTAM(to: runway)

    return NOTAMView(
      notam: notam,
      downloadedNOTAMs: [],
      plannedTime: .now,
      isLoadingNOTAMs: true
    )
    .environment(\.operation, .takeoff)
  }
}
