import Logging
import SwiftUI

struct LogViewer: View {
  let logEntries: [LogEntry]

  var body: some View {
    ScrollViewReader { proxy in
      ScrollView {
        VStack(alignment: .leading, spacing: 2) {
          ForEach(logEntries) { entry in
            Text(entry.formattedEntry)
              .font(.system(.caption, design: .monospaced))
              .foregroundStyle(colorForLogLevel(entry.level))
              .textSelection(.enabled)
              .id(entry.id)
          }
        }
        .padding(4)
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .frame(height: 200)
      .background(Color(nsColor: .textBackgroundColor))
      .border(Color.secondary.opacity(0.3))
      .onChange(of: logEntries.count) { _, _ in
        if let lastEntry = logEntries.last {
          withAnimation {
            proxy.scrollTo(lastEntry.id, anchor: .bottom)
          }
        }
      }
    }
  }

  private func colorForLogLevel(_ level: Logger.Level) -> Color {
    switch level {
      case .trace, .debug:
        return .secondary
      case .info, .notice:
        return .primary
      case .warning:
        return .orange
      case .error, .critical:
        return .red
    }
  }
}

#Preview {
  LogViewer(logEntries: [
    LogEntry(
      timestamp: Date(),
      level: .notice,
      message: "Initializing timezone lookup database…",
      metadata: nil
    ),
    LogEntry(
      timestamp: Date().addingTimeInterval(1),
      level: .notice,
      message: "Loading NASR data for cycle 2024-01-25…",
      metadata: nil
    ),
    LogEntry(
      timestamp: Date().addingTimeInterval(2),
      level: .notice,
      message: "Loading NASR archive…",
      metadata: nil
    ),
    LogEntry(
      timestamp: Date().addingTimeInterval(5),
      level: .notice,
      message: "Parsing NASR airports…",
      metadata: nil
    ),
    LogEntry(
      timestamp: Date().addingTimeInterval(8),
      level: .info,
      message: "Processed 2,145 airports",
      metadata: nil
    ),
    LogEntry(
      timestamp: Date().addingTimeInterval(10),
      level: .warning,
      message: "Some runways missing elevation data",
      metadata: nil
    ),
    LogEntry(
      timestamp: Date().addingTimeInterval(12),
      level: .error,
      message: "Parse error",
      metadata: [
        "error": "The data couldn't be read because it isn't in the correct format.",
        "failureReason": "Invalid field format in APT record",
        "recoverySuggestion":
          "Check that the NASR data cycle is compatible with this version of SwiftNASR"
      ]
    )
  ])
  .padding()
}
