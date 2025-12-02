import SF50_Shared
import SwiftUI

struct NOTAMListItemView: View {
  let notam: DownloadedNOTAM
  let plannedTime: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      // NOTAM ID and badges
      HStack {
        Text(notam.notamId)
          .font(.system(size: 14, weight: .medium, design: .monospaced))
          .multilineTextAlignment(.leading)

        Spacer()

        NOTAMTimeBadge(notam: notam, plannedTime: plannedTime)
      }

      // NOTAM text - wrap instead of horizontal scroll
      Text(notam.notamText)
        .font(.system(size: 12, weight: .regular, design: .monospaced))
        .fixedSize(horizontal: false, vertical: true)

      // Effective times
      VStack(alignment: .leading, spacing: 0) {
        Text("Effective: \(notam.effectiveStart, format: .dateTime)")
          .font(.caption)
          .foregroundStyle(.secondary)

        if let end = notam.effectiveEnd {
          Text("Until: \(end, format: .dateTime)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
    }
  }
}

#Preview {
  PreviewView { preview in
    let now = Date()
    let notams = preview.generateNOTAMs(count: 5, icaoLocation: "NZNR", baseTime: now)

    return List {
      ForEach(notams) { notam in
        NOTAMListItemView(
          notam: notam,
          plannedTime: now
        )
      }
    }
  }
}
