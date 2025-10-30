//
//  KeychainManager.swift
//  DownloadNASR
//
//  Secure storage for GitHub Personal Access Token
//

import Foundation
import Security

/// Manages secure storage of GitHub authentication tokens in the macOS Keychain
class KeychainManager {
  static let shared = KeychainManager()

  private let service = "codes.tim.SF50-TOLD.DownloadNASR"
  private let account = "github-token"

  private init() {}

  /// Save a GitHub token to the Keychain
  /// - Parameter token: The GitHub Personal Access Token to store
  /// - Throws: KeychainError if the save operation fails
  func saveToken(_ token: String) throws {
    guard let data = token.data(using: .utf8) else {
      throw KeychainError.invalidData
    }

    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecValueData as String: data
    ]

    // Delete any existing item first
    SecItemDelete(query as CFDictionary)

    // Add the new item
    let status = SecItemAdd(query as CFDictionary, nil)
    guard status == errSecSuccess else {
      throw KeychainError.saveFailed(status)
    }
  }

  /// Retrieve the stored GitHub token from the Keychain
  /// - Returns: The stored token, or nil if none exists
  /// - Throws: KeychainError if the retrieval fails (other than item not found)
  func getToken() throws -> String? {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account,
      kSecReturnData as String: true,
      kSecMatchLimit as String: kSecMatchLimitOne
    ]

    var result: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &result)

    guard status != errSecItemNotFound else { return nil }

    guard status == errSecSuccess else {
      throw KeychainError.retrievalFailed(status)
    }

    guard let data = result as? Data,
      let token = String(data: data, encoding: .utf8)
    else {
      throw KeychainError.invalidData
    }

    return token
  }

  /// Delete the stored GitHub token from the Keychain
  /// - Throws: KeychainError if the deletion fails
  func deleteToken() throws {
    let query: [String: Any] = [
      kSecClass as String: kSecClassGenericPassword,
      kSecAttrService as String: service,
      kSecAttrAccount as String: account
    ]

    let status = SecItemDelete(query as CFDictionary)
    guard status == errSecSuccess || status == errSecItemNotFound else {
      throw KeychainError.deletionFailed(status)
    }
  }

  /// Check if a valid token is currently stored in the Keychain
  /// - Returns: true if a non-empty token exists, false otherwise
  func hasStoredToken() -> Bool {
    guard let token = try? getToken(), !token.isEmpty else {
      return false
    }
    return true
  }
}

/// Errors that can occur during Keychain operations
enum KeychainError: LocalizedError {
  case saveFailed(OSStatus)
  case retrievalFailed(OSStatus)
  case deletionFailed(OSStatus)
  case invalidData

  var errorDescription: String? { .init(localized: "Failed to save GitHub token.") }

  var failureReason: String? {
    switch self {
      case .saveFailed(let status):
        return String(localized: "Keychain save operation failed with error code \(status).")
      case .retrievalFailed(let status):
        return String(localized: "Keychain retrieval operation failed with error code \(status).")
      case .deletionFailed(let status):
        return String(localized: "Keychain deletion operation failed with error code \(status).")
      case .invalidData:
        return String(localized: "Token data is invalid or corrupted.")
    }
  }

  var recoverySuggestion: String? {
    switch self {
      case .saveFailed, .invalidData:
        return String(localized: "Try entering your token again in Settings.")
      case .deletionFailed:
        return String(localized: "Try restarting the application.")
      default:
        return nil
    }
  }
}
