import Foundation
import FoundationModels
import Logging

/// Manages downloading and loading of the NOTAM parsing adapter.
///
/// Uses Apple-Hosted Background Assets (WWDC25) to download the adapter that matches
/// the device's system model version. The adapter is uploaded via App Store Connect
/// and downloaded automatically when the app is installed or updated.
///
/// Note: Custom adapter support requires the Foundation Models Framework Adapter Entitlement.
@available(iOS 26.0, macOS 26.0, *)
@MainActor
@Observable
public final class NOTAMAdapterManager {

  /// Shared singleton instance.
  public static let shared = NOTAMAdapterManager()

  /// Current adapter state.
  public private(set) var state: State = .checking

  /// The URL to the adapter file, if downloaded.
  public private(set) var adapterURL: URL?

  /// Logger for adapter operations.
  private let logger = Logger(label: "NOTAMAdapterManager")

  /// The loader used to fetch the adapter.
  private var loader: (any NOTAMAdapterLoader)?

  // MARK: - Public API

  /// Whether an adapter is available for use.
  public var isAvailable: Bool { adapterURL != nil }

  private init() {
    self.loader = Self.createLoader()
    Task { await checkAndLoadAdapter() }
  }

  // MARK: - Loader Selection

  private static func createLoader() -> (any NOTAMAdapterLoader)? {
    #if targetEnvironment(simulator)
      return nil
    #else
      #if DEBUG
        if BundledAdapterLoader.isAvailable {
          return BundledAdapterLoader()
        }
      #endif
      return HostedAdapterLoader()
    #endif
  }

  /// Ensures the adapter asset pack is downloaded and loads the adapter.
  public func checkAndLoadAdapter() async {
    guard let loader else {
      state = .failed(message: "NOTAM adapter not supported on this platform")
      return
    }

    state = .checking

    do {
      let url = try await loader.load { [weak self] progress in
        self?.state = .downloading(progress: progress)
      }
      // Verify the adapter can be loaded before marking as downloaded
      _ = try SystemLanguageModel.Adapter(fileURL: url)
      adapterURL = url
      state = .downloaded
    } catch {
      logger.error("Failed to load NOTAM adapter: \(error)")
      state = .failed(message: error.localizedDescription)
    }
  }

  /// Reloads the adapter (useful after adapter update).
  public func reloadAdapter() async {
    adapterURL = nil
    await checkAndLoadAdapter()
  }

  /// Removes the downloaded adapter to free storage.
  public func removeAdapter() async {
    guard let loader else { return }

    do {
      try await loader.remove()
      adapterURL = nil
      state = .notDownloaded
    } catch {
      logger.error("Failed to remove NOTAM adapter: \(error.localizedDescription)")
    }
  }

  // MARK: - Types

  /// Current state of the adapter.
  public enum State: Equatable, Sendable {
    case checking
    case notDownloaded
    case downloading(progress: Double)
    case downloaded
    case failed(message: String)
  }
}
