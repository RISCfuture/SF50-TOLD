import Foundation
import Logging
import SwiftNASR

/// View model coordinating the airport data processing UI.
///
/// ``ProcessorViewModel`` manages the state for the DownloadNASR tool's main
/// interface. It coordinates ``NASRProcessor`` execution and provides observable
/// properties for progress display.
///
/// ## Usage
///
/// ```swift
/// @State private var viewModel = ProcessorViewModel()
///
/// viewModel.process(cycle: .current, outputURL: downloadsURL)
/// ```
@Observable
@MainActor
class ProcessorViewModel {
  /// Whether processing is currently running.
  var isProcessing = false

  /// Current progress (0.0 to 1.0).
  var progress: Double = 0.0

  /// Human-readable status message for current operation.
  var statusMessage = ""

  /// Error message if processing failed.
  var errorMessage: String?

  /// Log entries from the processor for display.
  var logEntries: [LogEntry] = []

  /// Error that occurred during GitHub upload, if any.
  var uploadError: Error?

  /// Task handle for cancellation support.
  private var processingTask: Task<Void, Never>?

  /// Observation for progress updates.
  private var progressObservation: NSKeyValueObservation?

  /// Whether to show the progress bar UI.
  var showProgressBar: Bool {
    (isProcessing || !statusMessage.isEmpty) && errorMessage == nil
  }

  /// Starts processing for the given AIRAC cycle, outputting to the specified URL.
  func process(cycle: Cycle, outputURL: URL) {
    // Cancel any existing task
    processingTask?.cancel()
    progressObservation?.invalidate()

    // Reset state
    isProcessing = true
    progress = 0.0
    statusMessage = "Starting…"
    errorMessage = nil
    uploadError = nil
    logEntries = []

    processingTask = Task {
      do {
        // Create progress object
        let progressObject = Progress(totalUnitCount: 100)

        // Observe progress changes
        await MainActor.run {
          self.progressObservation = progressObject.observe(\.fractionCompleted, options: [.new]) {
            [weak self] progress, _ in
            Task { @MainActor in
              self?.progress = progress.fractionCompleted
              self?.statusMessage = progress.localizedDescription ?? ""
            }
          }
        }

        // Create custom log handler that captures logs for UI
        let uiHandler = UILogHandler(viewModel: self)

        // Create logger with custom handler
        let logger = Logger(label: "codes.tim.SF50-TOLD.DownloadNASR") { _ in
          var handler = uiHandler
          handler.logLevel = .notice
          return handler
        }

        var processor = NASRProcessor(
          cycle: cycle,
          outputLocation: outputURL,
          logger: logger,
          progress: progressObject
        )

        // Set upload error handler
        processor.onUploadError = { @MainActor [weak self] error in
          self?.uploadError = error
        }

        // Process on background thread
        try await processor.process()

        // Update UI on main actor
        await MainActor.run {
          statusMessage = "Complete!"
          progress = 1.0
        }

        // Reset after a brief delay
        try? await Task.sleep(for: .seconds(2))
        if !Task.isCancelled {
          await MainActor.run {
            reset()
          }
        }
      } catch {
        await MainActor.run {
          errorMessage = error.localizedDescription
          statusMessage = "Error occurred"
          isProcessing = false
        }
      }
    }
  }

  /// Resets all state to initial values.
  func reset() {
    isProcessing = false
    progress = 0.0
    statusMessage = ""
    errorMessage = nil
    uploadError = nil
    logEntries = []
  }

  /// Cancels the current processing task and resets state.
  func cancel() {
    processingTask?.cancel()
    reset()
  }

  /// Adds a log entry to the display list.
  func addLogEntry(_ entry: LogEntry) {
    logEntries.append(entry)
  }
}

// Custom log handler that updates the view model
private struct UILogHandler: LogHandler {
  weak var viewModel: ProcessorViewModel?

  var logLevel: Logger.Level = .notice
  var metadata: Logger.Metadata = [:]

  func log(
    level: Logger.Level,
    message: Logger.Message,
    metadata: Logger.Metadata?,
    source _: String,
    file _: String,
    function _: String,
    line _: UInt
  ) {
    guard level >= logLevel else { return }

    // Merge instance metadata with log-specific metadata
    var mergedMetadata = self.metadata
    if let metadata {
      mergedMetadata.merge(metadata) { _, new in new }
    }

    let entry = LogEntry(
      timestamp: Date(),
      level: level,
      message: message.description,
      metadata: mergedMetadata.isEmpty ? nil : mergedMetadata
    )

    Task { @MainActor in
      viewModel?.addLogEntry(entry)
    }
  }

  subscript(metadataKey key: String) -> Logger.Metadata.Value? {
    get { metadata[key] }
    set { metadata[key] = newValue }
  }
}
