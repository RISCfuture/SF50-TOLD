import Foundation
import OSLog

/// Uploads processed airport data to GitHub via REST API.
///
/// ``GitHubUploader`` uses the GitHub Contents API to upload compressed airport
/// data files to the SF50-TOLD-Airports repository. This makes the data available
/// for download by the iOS app.
///
/// ## Authentication
///
/// Requires a GitHub Personal Access Token with "Contents" write permission.
/// Tokens are stored securely using ``KeychainManager``.
///
/// ## Usage
///
/// ```swift
/// let uploader = GitHubUploader(token: token)
/// try await uploader.uploadFile(
///     filePath: localFile,
///     targetPath: "3.0/2501.plist.lzma",
///     commitMessage: "Update airport data for cycle 2501"
/// )
/// ```
///
/// ## Error Handling
///
/// Throws ``GitHubAPIError`` for common failure modes:
/// - ``GitHubAPIError/invalidToken``: Token expired or invalid
/// - ``GitHubAPIError/permissionDenied``: Token lacks write access
/// - ``GitHubAPIError/repositoryNotFound``: Repo not found or not accessible
class GitHubUploader {
  private let token: String
  private let repo: String
  private let owner: String
  private let baseURL = "https://api.github.com"
  private let logger = Logger(
    subsystem: "codes.tim.SF50-TOLD.DownloadNASR",
    category: "GitHubUploader"
  )

  /// Initialize uploader with GitHub credentials
  /// - Parameters:
  ///   - token: GitHub Personal Access Token
  ///   - repo: Repository name (default: SF50-TOLD-Airports)
  ///   - owner: Repository owner (default: RISCfuture)
  init(token: String, repo: String = "SF50-TOLD-Airports", owner: String = "RISCfuture") {
    self.token = token
    self.repo = repo
    self.owner = owner
  }

  /// Validate that the token is valid and has necessary permissions
  /// - Returns: true if token is valid
  /// - Throws: GitHubAPIError if validation fails
  func validateToken() async throws -> Bool {
    let url = URL(string: "\(baseURL)/user")!
    var request = URLRequest(url: url)
    configureRequest(&request)

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw GitHubAPIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      if httpResponse.statusCode == 401 {
        throw GitHubAPIError.invalidToken
      }
      throw GitHubAPIError.validationFailed(httpResponse.statusCode)
    }

    return true
  }

  /// Upload a file to the GitHub repository
  /// - Parameters:
  ///   - filePath: Local file path to upload
  ///   - targetPath: Path in repository (e.g., "3.0/2501.plist.lzma")
  ///   - commitMessage: Commit message for this upload
  ///   - branch: Branch to upload to (default: main)
  /// - Throws: GitHubAPIError if upload fails
  func uploadFile(
    filePath: URL,
    targetPath: String,
    commitMessage: String,
    branch: String = "main"
  ) async throws {
    logger.info("Uploading \(filePath.lastPathComponent) to \(targetPath)")

    // Read file and encode as base64
    let fileData = try Data(contentsOf: filePath)
    let base64Content = fileData.base64EncodedString()

    // Check if file exists to get its SHA (required for updates)
    let existingSHA = try? await getFileSHA(path: targetPath, branch: branch)

    if let existingSHA {
      logger.info("File exists, will update (\(existingSHA.prefix(7)))")
    } else {
      logger.info("File does not exist, will create new")
    }

    // Construct API request
    let url = URL(string: "\(baseURL)/repos/\(owner)/\(repo)/contents/\(targetPath)")!
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    configureRequest(&request)

    // Build request body
    var body: [String: Any] = [
      "message": commitMessage,
      "content": base64Content,
      "branch": branch
    ]

    if let existingSHA {
      body["sha"] = existingSHA  // Required for updates
    }

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    // Execute request
    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw GitHubAPIError.invalidResponse
    }

    guard (200...299).contains(httpResponse.statusCode) else {
      let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
      logger.error("Upload failed (HTTP \(httpResponse.statusCode)): \(errorMessage)")

      if httpResponse.statusCode == 401 {
        throw GitHubAPIError.invalidToken
      }
      if httpResponse.statusCode == 403 {
        throw GitHubAPIError.permissionDenied
      }
      if httpResponse.statusCode == 404 {
        throw GitHubAPIError.repositoryNotFound
      }
      if httpResponse.statusCode == 422 {
        throw GitHubAPIError.invalidContent(errorMessage)
      }

      throw GitHubAPIError.uploadFailed(httpResponse.statusCode, errorMessage)
    }

    logger.notice("Successfully uploaded \(filePath.lastPathComponent)")
  }

  /// Get the SHA of an existing file in the repository
  /// - Parameters:
  ///   - path: Path to file in repository
  ///   - branch: Branch to check (default: main)
  /// - Returns: SHA of the file
  /// - Throws: GitHubAPIError if file doesn't exist or request fails
  private func getFileSHA(path: String, branch: String) async throws -> String {
    let encodedPath = path.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? path
    let url = URL(
      string: "\(baseURL)/repos/\(owner)/\(repo)/contents/\(encodedPath)?ref=\(branch)"
    )!

    var request = URLRequest(url: url)
    configureRequest(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw GitHubAPIError.invalidResponse
    }

    guard httpResponse.statusCode == 200 else {
      if httpResponse.statusCode == 404 {
        throw GitHubAPIError.fileNotFound
      }
      throw GitHubAPIError.getSHAFailed(httpResponse.statusCode)
    }

    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    guard let sha = json?["sha"] as? String else {
      throw GitHubAPIError.invalidResponse
    }

    return sha
  }

  /// Configure a URL request with standard GitHub API headers
  /// - Parameter request: The request to configure
  private func configureRequest(_ request: inout URLRequest) {
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
    request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
  }
}

/// Errors that can occur during GitHub API operations
enum GitHubAPIError: LocalizedError {
  case invalidResponse
  case invalidToken
  case validationFailed(Int)
  case permissionDenied
  case repositoryNotFound
  case fileNotFound
  case getSHAFailed(Int)
  case invalidContent(String)
  case uploadFailed(Int, String)

  var errorDescription: String? { .init(localized: "Failed to upload to GitHub.") }

  var failureReason: String? {
    switch self {
      case .invalidResponse:
        return String(localized: "Received an invalid response from GitHub API.")
      case .invalidToken:
        return String(localized: "GitHub token is invalid or expired.")
      case .validationFailed(let code):
        return String(localized: "Token validation failed with HTTP status \(code).")
      case .permissionDenied:
        return String(localized: "Your token does not have write access to the repository.")
      case .repositoryNotFound:
        return String(localized: "Repository not found or token does not have access.")
      case .fileNotFound:
        return String(localized: "File not found in repository.")
      case .getSHAFailed(let code):
        return String(localized: "Failed to get file SHA with HTTP status \(code).")
      case .invalidContent(let message):
        return String(localized: "Invalid content: \(message)")
      case .uploadFailed(let code, let message):
        return String(localized: "Upload failed with HTTP status \(code): \(message)")
    }
  }

  var recoverySuggestion: String? {
    switch self {
      case .invalidToken:
        return String(localized: "Open Settings and enter a valid GitHub Personal Access Token.")
      case .permissionDenied:
        return String(
          localized: "Generate a new token with “Contents” write permission for the repository."
        )
      case .repositoryNotFound:
        return String(localized: "Verify the repository exists and your token has access to it.")
      default:
        return nil
    }
  }
}
