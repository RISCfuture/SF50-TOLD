import SwiftUI

/// Badge showing configured vs available NOTAM counts.
///
/// Displays NOTAM status with color coding:
/// - Gray: No NOTAMs available
/// - Orange: Available NOTAMs not configured
/// - Green: All available NOTAMs configured
struct NOTAMBadge: View {
  /// Number of NOTAMs configured/applied in the app
  let localCount: Int

  /// Number of NOTAMs available from the API
  let downloadedCount: Int

  /// Whether NOTAMs are currently being loaded
  let isLoading: Bool

  /// Whether a NOTAM fetch has been attempted (to distinguish "not fetched" from "fetched with 0")
  let hasAttemptedFetch: Bool

  var body: some View {
    HStack(spacing: 4) {
      if isLoading {
        ProgressView()
          .controlSize(.mini)
        Text("Loading…")
      } else {
        Image(systemName: "pencil")
          .accessibilityLabel("Configured NOTAMs")
        Text("\(localCount, format: .number)")

        // Only show download count if we've attempted to fetch
        if hasAttemptedFetch {
          Image(systemName: "network")
            .accessibilityLabel("Downloaded NOTAMs")
            .padding(.leading, 6)
          Text("\(downloadedCount, format: .number)")
        }
      }
    }
    .font(.caption2)
    .fontWeight(.medium)
    .foregroundStyle(textColor)
    .padding(.horizontal, 8)
    .padding(.vertical, 4)
    .background(
      Capsule()
        .fill(Color.secondary.opacity(0.1))
    )
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
  }

  private var textColor: Color {
    if isLoading {
      return .secondary
    }
    // If we haven't fetched yet, just show based on configured count
    if !hasAttemptedFetch {
      return localCount > 0 ? .primary : .secondary
    }
    // If we have fetched, show based on both counts
    if localCount == 0 || downloadedCount == 0 {
      return .secondary
    }
    return .primary
  }

  private var accessibilityLabel: String {
    if isLoading {
      return String(localized: "Loading NOTAMs")
    }
    if hasAttemptedFetch {
      return String(
        localized:
          "\(localCount, format: .count) configured, \(downloadedCount, format: .count) downloaded"
      )
    }
    return String(localized: "\(localCount, format: .count) configured")
  }

  init(
    configuredCount: Int,
    availableCount: Int,
    isLoading: Bool = false,
    hasAttemptedFetch: Bool = false
  ) {
    self.localCount = configuredCount
    self.downloadedCount = availableCount
    self.isLoading = isLoading
    self.hasAttemptedFetch = hasAttemptedFetch
  }
}

#Preview {
  List {
    LabeledContent("Loading") {
      NOTAMBadge(configuredCount: 0, availableCount: 0, isLoading: true)
    }
    LabeledContent("None") {
      NOTAMBadge(configuredCount: 0, availableCount: 0)
    }
    LabeledContent("Some") {
      NOTAMBadge(configuredCount: 2, availableCount: 5)
    }
  }
}
