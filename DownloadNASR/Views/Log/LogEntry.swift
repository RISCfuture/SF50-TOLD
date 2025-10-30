import Foundation
import Logging

struct LogEntry: Identifiable {
  let id = UUID()
  let timestamp: Date
  let level: Logger.Level
  let message: String
  let metadata: Logger.Metadata?

  var formattedTimestamp: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss"
    return formatter.string(from: timestamp)
  }

  var levelString: String {
    switch level {
      case .trace: return "TRACE"
      case .debug: return "DEBUG"
      case .info: return "INFO"
      case .notice: return "NOTICE"
      case .warning: return "WARNING"
      case .error: return "ERROR"
      case .critical: return "CRITICAL"
    }
  }

  var formattedEntry: String {
    var result = "[\(formattedTimestamp)] \(levelString): \(message)"

    // Append metadata if present
    if let metadata, !metadata.isEmpty {
      // For error-level logs with structured error info, format each field on a new line
      if level == .error || level == .critical {
        for (key, value) in metadata {
          result += "\n  \(key): \(value)"
        }
      } else {
        // For other log levels, use compact inline format
        let metadataString =
          metadata
          .map { key, value in "\(key)=\(value)" }
          .joined(separator: ", ")
        result += " [\(metadataString)]"
      }
    }

    return result
  }
}
