import SwiftUI

/// Row displaying auto-fill status for NOTAMs.
///
/// Shows either:
/// - Parsing indicator when AI is analyzing NOTAMs
/// - Auto-filled indicator when NOTAMs were automatically created
/// - Auto-fill button when user edits have blocked auto-fill
struct AutofillStatusRow: View {
  let isAutomaticallyCreated: Bool
  let isParsing: Bool
  let onAutoFill: (() async -> Void)?

  var body: some View {
    if isParsing {
      // Parsing indicator
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          ProgressView()
            .controlSize(.small)
          Text("Studying downloaded NOTAMs…")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
      }
      .appleIntelligenceStyle()
      .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
      .listRowBackground(Color.clear)
    } else if isAutomaticallyCreated {
      // Auto-filled indicator
      VStack(alignment: .leading, spacing: 4) {
        HStack(spacing: 8) {
          Image(systemName: "sparkles")
            .foregroundStyle(LinearGradient.appleIntelligence)
          Text("Auto-filled from NOTAMs")
            .font(.subheadline)
            .foregroundStyle(.secondary)
          Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
      }
      .appleIntelligenceStyle()
      .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
      .listRowBackground(Color.clear)
    } else if let onAutoFill {
      // Auto-fill button
      Button {
        Task {
          await onAutoFill()
        }
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "wand.and.stars")
            .foregroundStyle(LinearGradient.appleIntelligence)

          VStack(alignment: .leading, spacing: 2) {
            Text("Auto-fill from downloaded NOTAMs?")
              .font(.subheadline)
              .foregroundStyle(.primary)

            Text("Updated NOTAMs available")
              .font(.caption)
              .foregroundStyle(.secondary)
          }

          Spacer()

          Image(systemName: "chevron.right")
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
      }
      .appleIntelligenceStyle()
      .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
      .listRowBackground(Color.clear)
    }
  }
}

#Preview {
  Form {
    Section {
      AutofillStatusRow(isAutomaticallyCreated: false, isParsing: true, onAutoFill: nil)
    }
    Section {
      AutofillStatusRow(isAutomaticallyCreated: true, isParsing: false, onAutoFill: nil)
    }
    Section {
      AutofillStatusRow(isAutomaticallyCreated: false, isParsing: false) { }
    }
  }
}
