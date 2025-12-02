import Foundation
import Logging

// MARK: - Adapter Loader Protocol

@available(iOS 26.0, macOS 26.0, *)
protocol NOTAMAdapterLoader: Sendable {

  /// Loads the adapter and returns its URL.
  /// - Parameter onProgress: Called with download progress (0.0 to 1.0) if downloading.
  /// - Returns: URL to the loaded adapter.
  @MainActor
  func load(onProgress: @escaping @MainActor (Double) -> Void) async throws -> URL

  /// Removes the adapter from storage.
  @MainActor
  func remove() async throws
}

// MARK: - Bundled Adapter Loader (DEBUG only)

#if DEBUG && !targetEnvironment(simulator)
  @available(iOS 26.0, macOS 26.0, *)
  struct BundledAdapterLoader: NOTAMAdapterLoader {
    static var isAvailable: Bool {
      Bundle.main.url(forResource: "NOTAMAdapter", withExtension: "fmadapter") != nil
    }

    @MainActor
    func load(onProgress _: @escaping @MainActor (Double) -> Void) throws -> URL {
      guard
        let url = Bundle.main.url(forResource: "NOTAMAdapter", withExtension: "fmadapter")
      else {
        throw AdapterError.notDownloaded
      }
      return url
    }

    @MainActor
    func remove() throws {
      // Bundled adapters cannot be removed
    }
  }
#endif

// MARK: - Hosted Adapter Loader (Production)

#if !targetEnvironment(simulator)
  import BackgroundAssets
  import System

  @available(iOS 26.0, macOS 26.0, *)
  struct HostedAdapterLoader: NOTAMAdapterLoader {
    private static let adapterFilePath = FilePath("NOTAMAdapter.fmadapter")

    /// Known toolkit versions and their compatible OS version ranges.
    /// Each toolkit version corresponds to a specific system model signature.
    /// New entries should be added when Apple releases new toolkit versions.
    private static let toolkitVersions: [(id: String, minOS: OperatingSystemVersion)] = [
      // Toolkit 26.1 - compatible with iOS/macOS 26.0+
      (
        "notam-adapter-26-1",
        OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)
      )
    ]

    /// Returns the asset pack ID for the current OS version.
    /// Finds the most recent toolkit version compatible with this OS.
    private static var assetPackID: String {
      let currentOS = ProcessInfo.processInfo.operatingSystemVersion

      // Find the latest toolkit version that this OS supports
      // (the one with the highest minOS that's <= currentOS)
      let compatible =
        toolkitVersions
        .last(where: { isOS(currentOS, atLeast: $0.minOS) })

      return compatible?.id ?? toolkitVersions.last!.id
    }

    private let logger = Logger(label: "HostedAdapterLoader")

    private static func isOS(
      _ current: OperatingSystemVersion,
      atLeast min: OperatingSystemVersion
    ) -> Bool {
      if current.majorVersion != min.majorVersion {
        return current.majorVersion > min.majorVersion
      }
      if current.minorVersion != min.minorVersion {
        return current.minorVersion > min.minorVersion
      }
      return current.patchVersion >= min.patchVersion
    }

    @MainActor
    func load(onProgress: @escaping @MainActor (Double) -> Void) async throws -> URL {
      let manager = AssetPackManager.shared

      let statusTask = Task {
        await monitorDownloadProgress(onProgress: onProgress)
      }

      let assetPack = try await manager.assetPack(withID: Self.assetPackID)
      try await manager.ensureLocalAvailability(of: assetPack)
      statusTask.cancel()

      return try manager.url(for: Self.adapterFilePath)
    }

    @MainActor
    func remove() async throws {
      try await AssetPackManager.shared.remove(assetPackWithID: Self.assetPackID)
    }

    private func monitorDownloadProgress(
      onProgress: @escaping @MainActor (Double) -> Void
    ) async {
      for await status in AssetPackManager.shared.statusUpdates(
        forAssetPackWithID: Self.assetPackID
      ) {
        switch status {
          case .downloading(_, let progress):
            await onProgress(progress.fractionCompleted)
          case .failed(_, let error):
            logger.error("NOTAM adapter download failed: \(error.localizedDescription)")
          case .finished, .began, .paused:
            break
          @unknown default:
            break
        }
      }
    }
  }
#endif

// MARK: - Errors

public enum AdapterError: LocalizedError {
  case notDownloaded
  case loadFailed(Error)
  case downloadFailed(Error)

  public var errorDescription: String? {
    String(localized: "NOTAM adapter couldn’t be loaded.")
  }

  public var failureReason: String? {
    switch self {
      case .notDownloaded:
        String(localized: "The adapter has not been downloaded yet.")
      case .loadFailed(let error):
        String(localized: "Failed to load adapter: \(error.localizedDescription)")
      case .downloadFailed(let error):
        String(localized: "Failed to download adapter: \(error.localizedDescription)")
    }
  }

  public var recoverySuggestion: String? {
    switch self {
      case .notDownloaded:
        String(
          localized:
            "The adapter should download automatically. Try again later or reinstall the app."
        )
      case .loadFailed:
        String(
          localized:
            "The adapter may be corrupted or incompatible with this iOS version. Try reinstalling the app, or waiting for a compatibility update for this iOS version."
        )
      case .downloadFailed:
        String(localized: "Check your internet connection and try again.")
    }
  }
}
