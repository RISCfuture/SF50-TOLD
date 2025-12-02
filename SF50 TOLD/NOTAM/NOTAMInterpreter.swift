import Foundation
import FoundationModels
import Logging
import SF50_Shared

/// Parses raw NOTAM text into structured runway performance data.
///
/// Uses the FoundationModels framework with a trained adapter for extraction.
/// Parsing is only available when the adapter has been downloaded.
@available(iOS 26.0, macOS 26.0, *)
public actor NOTAMInterpreter {

  /// Shared singleton instance.
  public static let shared = NOTAMInterpreter()

  private let logger = Logger(label: "NOTAMParser")

  /// Language model session (reused for efficiency).
  private var session: LanguageModelSession?

  /// Whether we've attempted to initialize the session.
  private var sessionInitialized = false

  /// Returns whether the adapter is currently available.
  public var isAdapterAvailable: Bool {
    get async {
      await MainActor.run {
        NOTAMAdapterManager.shared.isAvailable
      }
    }
  }

  private init() {}

  // MARK: - Public API

  /// Parses a NOTAM response into structured data.
  ///
  /// - Parameters:
  ///   - notam: The NOTAM response from the API
  ///   - runway: Optional runway to filter for
  /// - Returns: Parsed NOTAM data, or nil if parsing failed or adapter unavailable
  public func parse(_ notam: DownloadedNOTAM, for runway: String? = nil) async -> InterpretedNOTAM?
  {
    await initializeSessionIfNeeded()
    guard session != nil else { return nil }
    let prompt = buildPrompt(for: notam, runway: runway)
    return await extractWithModel(prompt: prompt, notamId: notam.notamId)
  }

  /// Parses multiple NOTAMs for a specific runway.
  ///
  /// - Parameters:
  ///   - notams: Array of NOTAM responses
  ///   - runway: The runway designator to filter for
  /// - Returns: Array of parsed NOTAMs (non-nil results only)
  public func parse(_ notams: [DownloadedNOTAM], for runway: String) async -> [InterpretedNOTAM] {
    return await withTaskGroup { group in
      var results: [InterpretedNOTAM] = []

      for notam in notams {
        group.addTask { await self.parse(notam, for: runway) }
      }

      for await notam in group.compactMap(\.self) {
        results.append(notam)
      }
      return results
    }
  }

  /// Reloads the session (useful after adapter download completes).
  public func reloadSession() async {
    session = nil
    sessionInitialized = false
    await initializeSessionIfNeeded()
  }

  // MARK: - Private Implementation

  /// Initializes the language model session with the adapter if available.
  private func initializeSessionIfNeeded() async {
    guard !sessionInitialized else { return }
    sessionInitialized = true

    // Get adapter URL from MainActor-isolated manager
    let adapterURL = await MainActor.run {
      NOTAMAdapterManager.shared.adapterURL
    }
    guard let adapterURL else { return }

    do {
      let adapter = try SystemLanguageModel.Adapter(fileURL: adapterURL)
      let model = SystemLanguageModel(adapter: adapter)
      session = LanguageModelSession(model: model)
    } catch {
      logger.error("Failed to load NOTAM adapter: \(error.localizedDescription)")
    }
  }

  /// Builds the extraction prompt for a NOTAM.
  private func buildPrompt(for notam: DownloadedNOTAM, runway: String?) -> String {
    let formatter = ISO8601DateFormatter()
    let effectiveStartStr = formatter.string(from: notam.effectiveStart)
    let effectiveEndStr = notam.effectiveEnd.map { formatter.string(from: $0) } ?? "PERM"

    return """
      Extract runway performance data from this NOTAM.

      Airport: \(notam.icaoLocation)
      Runway: \(runway ?? "ALL")
      Effective: \(effectiveStartStr) to \(effectiveEndStr)

      NOTAM \(notam.notamId):
      \(notam.notamText)
      """
  }

  /// Extracts structured data using the language model.
  private func extractWithModel(prompt: String, notamId: String) async -> InterpretedNOTAM? {
    guard let session else { return nil }

    do {
      // Use schema-free guided generation (adapter was trained with consistent JSON output format)
      let response = try await session.respond(
        to: prompt,
        generating: NOTAMExtraction.self,
        includeSchemaInPrompt: false
      )
      return response.content.toInterpretedNOTAM()
    } catch {
      logger.warning("NOTAM extraction failed for \(notamId): \(error)")
      return nil
    }
  }
}
