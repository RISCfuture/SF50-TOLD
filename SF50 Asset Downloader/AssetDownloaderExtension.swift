import BackgroundAssets
import ExtensionFoundation
import StoreKit

/// Background Assets downloader extension for managed asset packs.
///
/// This extension is invoked by the system to determine which asset packs
/// should be downloaded. For Apple-Hosted Background Assets, the system
/// handles all download management automatically.
@main
struct AssetDownloaderExtension: StoreDownloaderExtension {
  /// Determines whether a specific asset pack should be downloaded.
  ///
  /// Called by the system when an asset pack is available for download.
  /// Return `true` to allow the download, `false` to skip it.
  ///
  /// - Parameter assetPack: The asset pack being considered for download
  /// - Returns: Whether to download this asset pack
  func shouldDownload(_: AssetPack) -> Bool {
    // Download all available asset packs (currently just the NOTAM adapter)
    return true
  }
}
