import SF50_Shared
import SwiftUI

/// Badge showing the time relevance of a NOTAM relative to planned departure/arrival time.
struct NOTAMTimeBadge: View {
  private static let criticalTimeInterval: TimeInterval = 3600  // 1 hr
  private static let warningTimeInterval: TimeInterval = 10800  // 3 hr

  let notam: DownloadedNOTAM
  let plannedTime: Date

  private var timeRelevance: TimeRelevance {
    if notam.hasExpired(before: plannedTime, windowInterval: Self.criticalTimeInterval) {
      return .expired
    }
    if notam.isEffective(within: plannedTime, windowInterval: Self.criticalTimeInterval) {
      return .active
    }

    // Check if NOTAM will be effective warning (within 3 hours of planned time)
    let timeUntilEffective = notam.timeUntilEffective(from: plannedTime)
    if timeUntilEffective <= Self.warningTimeInterval {
      return .warning(timeInterval: timeUntilEffective)
    }

    // NOTAM is in the distant future
    return .future(timeInterval: timeUntilEffective)
  }

  var body: some View {
    Text(timeRelevance.label)
      .font(.caption)
      .fontWeight(.medium)
      .padding(.horizontal, 8)
      .padding(.vertical, 4)
      .background(
        Capsule()
          .fill(timeRelevance.backgroundColor)
      )
      .foregroundStyle(timeRelevance.foregroundColor)
  }

  enum TimeRelevance {
    case expired
    case active
    case warning(timeInterval: TimeInterval)
    case future(timeInterval: TimeInterval)

    var foregroundColor: Color {
      switch self {
        case .expired: return .gray
        case .active: return .white  // Effective during planned time ± 1 hour
        case .warning: return .white  // Will be effective within 3 hours of planned time
        case .future: return .green  // More than 3 hours after planned time
      }
    }

    var backgroundColor: Color {
      switch self {
        case .expired: return .gray.opacity(0.2)
        case .active: return .red  // Effective during planned time ± 1 hour
        case .warning: return .orange  // Will be effective within 3 hours of planned time
        case .future:
          return .green.opacity(
            0.2
          )  // More than 3 hours after planned time
      }
    }

    var label: String {
      switch self {
        case .expired: return String(localized: "Expired")
        case .active: return String(localized: "Active")
        case .warning(let interval):
          return Self.formatTimeInterval(interval)
        case .future(let interval):
          return Self.formatTimeInterval(interval)
      }
    }

    private static func formatTimeInterval(_ interval: TimeInterval) -> String {
      let formatter = RelativeDateTimeFormatter()
      formatter.unitsStyle = .abbreviated
      formatter.formattingContext = .standalone

      let futureDate = Date().addingTimeInterval(interval)
      return formatter.localizedString(for: futureDate, relativeTo: Date())
    }
  }
}

#Preview {
  PreviewView { preview in
    let plannedTime = Date()
    let notams = preview.generateNOTAMs(count: 5, icaoLocation: "NZNR", baseTime: plannedTime)

    return VStack(spacing: 12) {
      ForEach(notams) { notam in
        NOTAMTimeBadge(
          notam: notam,
          plannedTime: plannedTime
        )
      }
    }
    .padding()
  }
}
