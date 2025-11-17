import AppKit
import Logging
import SwiftNASR
import SwiftUI

struct ContentView: View {
  @SwiftUI.State private var viewModel = ProcessorViewModel()
  @SwiftUI.State private var selectedCycleOption: CycleOption = .current
  @SwiftUI.State private var customCycleText = ""
  @SwiftUI.State private var hasStoredToken = false
  @SwiftUI.State private var checkTokenTask: Task<Void, Never>?

  private var cycle: Cycle? {
    switch selectedCycleOption {
      case .current: Cycle.current
      case .next: Cycle.current.next
      case .custom: stringToCycle(customCycleText)
    }
  }

  var body: some View {
    let showErrorSheet = Binding<Bool>(
      get: { viewModel.uploadError != nil },
      set: { _ in }
    )

    VStack(spacing: 20) {
      // Title
      Text("SF50 TOLD Data Downloader")
        .font(.title)
        .fontWeight(.bold)

      Spacer()
      Form {
        HStack {
          Picker("Cycle", selection: $selectedCycleOption) {
            Text("Current").tag(CycleOption.current)
            Text("Next").tag(CycleOption.next)
            Text("Custom…").tag(CycleOption.custom)
          }
          .disabled(viewModel.isProcessing)

          if selectedCycleOption == .custom {
            TextField("", text: $customCycleText)
              .textFieldStyle(.roundedBorder)
              .help("Enter cycle in format: YYYY-MM-DD (e.g., 2024-01-25)")
              .frame(maxWidth: 100)
              .foregroundStyle(
                isCustomCycleInvalid ? Color.red : Color.primary
              )
          }
        }
      }

      Divider()

      // Download button
      Button(buttonTitle, action: downloadAndProcess)
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isProcessing || cycle == nil)

      Spacer()

      // Processing UI
      if viewModel.showProgressBar {
        VStack(spacing: 12) {
          // Progress bar
          ProgressView(value: viewModel.progress) {
            Text(viewModel.statusMessage)
              .font(.subheadline)
              .foregroundStyle(.secondary)
          }
          .progressViewStyle(.linear)
        }
      }

      // Log viewer (always visible)
      LogViewer(logEntries: viewModel.logEntries)

      // Error message
      if let errorMessage = viewModel.errorMessage {
        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
          .padding()
          .foregroundStyle(Color.red)
      }
    }
    .padding(30)
    .onAppear {
      startPeriodicTokenCheck()
    }
    .onDisappear {
      checkTokenTask?.cancel()
    }
    .alert(
      "Upload Error",
      isPresented: showErrorSheet,
      presenting: viewModel.uploadError
    ) { _ in
      Button("OK") {
        viewModel.uploadError = nil
      }
    } message: { error in
      VStack(alignment: .leading, spacing: 8) {
        Text(error.localizedDescription)
        if let failureReason = error.failureReason {
          Text(failureReason)
            .font(.caption)
        }

        if let recoverySuggestion = error.recoverySuggestion {
          Text(recoverySuggestion)
            .font(.caption)
        }
      }
    }
  }

  // MARK: - Computed Properties

  private var isCustomCycleInvalid: Bool {
    selectedCycleOption == .custom && !customCycleText.isEmpty
      && stringToCycle(customCycleText) == nil
  }

  private var buttonTitle: String {
    hasStoredToken
      ? String(localized: "Process and Upload")
      : String(localized: "Process and Save")
  }

  private func stringToCycle(_ value: String) -> Cycle? {
    let components = value.split(separator: "-")
    guard components.count == 3 else { return nil }

    guard let year = UInt(components[0]),
      let month = UInt8(components[1]),
      let day = UInt8(components[2])
    else {
      return nil
    }

    return Cycle(year: year, month: month, day: day)
  }

  // MARK: - Actions

  private func startPeriodicTokenCheck() {
    checkTokenTask = Task {
      while !Task.isCancelled {
        await MainActor.run {
          hasStoredToken = KeychainManager.shared.hasStoredToken()
        }
        try? await Task.sleep(for: .seconds(0.5))
      }
    }
  }

  private func downloadAndProcess() {
    // Show file picker to select output directory
    let panel = NSOpenPanel()
    panel.canChooseFiles = false
    panel.canChooseDirectories = true
    panel.canCreateDirectories = true
    panel.allowsMultipleSelection = false
    panel.message = "Choose a directory to save the processed files:"
    panel.prompt = "Select"

    panel.begin { response in
      guard response == .OK, let url = panel.url, let cycle else {
        return
      }

      // Start processing
      viewModel.process(cycle: cycle, outputURL: url)
    }
  }

  enum CycleOption: CaseIterable {
    case current
    case next
    case custom
  }
}

#Preview {
  ContentView()
}
