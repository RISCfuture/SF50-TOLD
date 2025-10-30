//
//  SettingsView.swift
//  DownloadNASR
//
//  GitHub token configuration interface
//

import SwiftUI

struct SettingsView: View {
  @Environment(\.dismiss)
  private var dismiss

  @State private var token = ""
  @State private var isValidating = false
  @State private var validationMessage: String?
  @State private var validationSuccess = false
  @State private var showingDeleteConfirmation = false
  @State private var hasStoredToken = false
  @State private var checkTokenTask: Task<Void, Never>?

  var body: some View {
    VStack(spacing: 20) {
      Section("Personal Access Token") {
        VStack(alignment: .leading) {
          HStack {
            SecureField("Paste your GitHub token here", text: $token)
              .textFieldStyle(.roundedBorder)
              .font(.system(.body, design: .monospaced))
              .disabled(isValidating)

            Button(action: validateAndSaveToken) {
              HStack {
                if isValidating {
                  ProgressView()
                    .scaleEffect(0.4)
                    .frame(width: 12, height: 12)
                }
                Text(isValidating ? "Validating…" : "Validate")
              }
            }
            .disabled(token.isEmpty || isValidating)
            .buttonStyle(.borderedProminent)

            if hasStoredToken {
              Button(action: { showingDeleteConfirmation = true }, label: {
                Label("Delete", systemImage: "trash")
              })
              .buttonStyle(.bordered)
              .tint(.red)
            }
          }
          .padding(.bottom, 8)

          if let validationMessage {
            Label(
              validationMessage,
              systemImage: validationSuccess
                ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
            )
            .font(.caption)
            .foregroundStyle(validationSuccess ? .green : .red)
            .padding(.top, 4)
          }
        }
      }

      GitHubInstructionsView()
    }
    .onAppear {
      loadExistingToken()
      startPeriodicCheck()
    }
    .onDisappear {
      checkTokenTask?.cancel()
    }
    .alert("Delete Token", isPresented: $showingDeleteConfirmation) {
      Button("Cancel", role: .cancel) {}
      Button("Delete", role: .destructive, action: deleteToken)
    } message: {
      Text(
        "Are you sure you want to delete your stored GitHub token? You'll need to enter a new token to upload files."
      )
    }
    .padding()
  }

  private func loadExistingToken() {
    checkHasStoredToken()
    if hasStoredToken {
      // Don't load the actual token for security, just show it exists
      token = ""
      validationMessage = "Token is saved"
      validationSuccess = true
    }
  }

  private func checkHasStoredToken() {
    hasStoredToken = KeychainManager.shared.hasStoredToken()
  }

  private func startPeriodicCheck() {
    checkTokenTask = Task {
      while !Task.isCancelled {
        try? await Task.sleep(for: .seconds(0.5))
        checkHasStoredToken()
      }
    }
  }

  private func validateAndSaveToken() {
    isValidating = true
    validationMessage = nil

    Task {
      do {
        let uploader = GitHubUploader(token: token)
        let isValid = try await uploader.validateToken()

        if isValid {
          // Token is valid, save it
          try KeychainManager.shared.saveToken(token)
          await MainActor.run {
            validationMessage = String(localized: "Token validated and saved successfully!")
            validationSuccess = true
            token = ""
          }
        }
      } catch {
        await MainActor.run {
          validationMessage = String(localized: "Validation failed: \(error.localizedDescription)")
          validationSuccess = false
        }
      }

      await MainActor.run {
        isValidating = false
      }
    }
  }

  private func deleteToken() {
    do {
      try KeychainManager.shared.deleteToken()
      token = ""
      validationMessage = String(localized: "Token deleted successfully")
      validationSuccess = false
    } catch {
      validationMessage = String(localized: "Failed to delete token: \(error.localizedDescription)")
      validationSuccess = false
    }
  }
}

#Preview {
  SettingsView()
}
