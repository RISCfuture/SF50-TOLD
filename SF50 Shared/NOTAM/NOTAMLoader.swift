import Foundation
import Logging

/**
 * Actor responsible for fetching NOTAM data from the NOTAM API.
 *
 * ``NOTAMLoader`` provides thread-safe access to NOTAM data with error handling.
 * It connects to a custom NOTAM API service to retrieve FAA NOTAMs in a structured
 * JSON format.
 *
 * ## Configuration
 *
 * API credentials are loaded from the app bundle's Info.plist:
 * - `NOTAM_API_BASE_URL`: Base URL for the NOTAM service
 * - `NOTAM_API_TOKEN`: Bearer token for authentication
 *
 * ## Querying NOTAMs
 *
 * NOTAMs can be fetched by:
 * - ICAO location code
 * - Date range (effective start/end)
 * - Purpose and scope filters
 *
 * ## Response Format
 *
 * Results are returned as ``NOTAMListResponse`` containing:
 * - Array of ``NOTAMResponse`` objects
 * - Pagination metadata
 *
 * ## Usage
 *
 * ```swift
 * let response = try await NOTAMLoader.shared.fetchNOTAMs(
 *     for: "KJFK",
 *     startDate: Date(),
 *     endDate: Date().addingTimeInterval(86400 * 7)
 * )
 *
 * for notam in response.data {
 *     print(notam.notamText)
 * }
 * ```
 */
public actor NOTAMLoader {
  /// Shared singleton instance
  public static let shared = NOTAMLoader()

  /// Logger for NOTAM operations
  private static let logger = Logger(label: "codes.tim.SF50-TOLD.NOTAMLoader")

  /// URLSession for network requests
  private var session: URLSession { .init(configuration: .ephemeral) }

  /// Base URL for the NOTAM API
  private let baseURL: String

  /// API token for authentication
  private let apiToken: String

  /// ISO8601 date formatter for API requests
  private let dateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  /// JSON decoder configured for API responses
  private let decoder: JSONDecoder = {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = formatter.date(from: dateString) {
        return date
      }

      formatter.formatOptions = [.withInternetDateTime]
      if let date = formatter.date(from: dateString) {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid date format: \(dateString)"
      )
    }
    return decoder
  }()

  /// Private initializer to enforce singleton pattern
  private init() {
    // Load configuration from bundle
    if let baseURL = Bundle.main.object(forInfoDictionaryKey: "NOTAM_API_BASE_URL") as? String,
      let token = Bundle.main.object(forInfoDictionaryKey: "NOTAM_API_TOKEN") as? String
    {
      self.baseURL = baseURL
      self.apiToken = token
    } else {
      // Fallback for development/testing
      self.baseURL = "https://notams.fly.dev"
      self.apiToken = ""
      Self.logger.warning(
        "NOTAM API configuration not found in bundle. Using defaults. API calls will fail."
      )
    }
  }

  /// Fetches NOTAMs for a specific ICAO location.
  ///
  /// - Parameters:
  ///   - icao: ICAO airport code (e.g., "KJFK")
  ///   - startDate: Optional start date filter (NOTAMs effective on or after this date)
  ///   - endDate: Optional end date filter (NOTAMs effective on or before this date)
  ///   - purpose: Optional NOTAM purpose code filter (N, B, O, M, K)
  ///   - scope: Optional NOTAM scope filter (A, E, W)
  ///   - limit: Maximum number of results (default: 100, max: 100)
  ///   - offset: Number of results to skip for pagination (default: 0)
  /// - Returns: NOTAM list response containing NOTAMs and pagination info
  /// - Throws: `NOTAMLoader.Errors` on failure
  public func fetchNOTAMs(
    for icao: String,
    startDate: Date? = nil,
    endDate: Date? = nil,
    purpose: String? = nil,
    scope: String? = nil,
    limit: Int = 100,
    offset: Int = 0
  ) async throws -> DownloadedNOTAMList {
    // Build query parameters
    var components = URLComponents(string: "\(baseURL)/api/notams")!
    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "location", value: icao.uppercased()),
      URLQueryItem(name: "limit", value: "\(min(limit, 100))"),
      URLQueryItem(name: "offset", value: "\(offset)")
    ]

    if let startDate {
      queryItems.append(
        URLQueryItem(name: "start", value: dateFormatter.string(from: startDate))
      )
    }

    if let endDate {
      queryItems.append(URLQueryItem(name: "end", value: dateFormatter.string(from: endDate)))
    }

    if let purpose {
      queryItems.append(URLQueryItem(name: "purpose", value: purpose))
    }

    if let scope {
      queryItems.append(URLQueryItem(name: "scope", value: scope))
    }

    components.queryItems = queryItems

    guard let url = components.url else {
      throw Errors.invalidURL
    }

    Self.logger.info("Fetching NOTAMs", metadata: ["url": "\(url)", "icao": "\(icao)"])

    // Create request with authentication
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.timeoutInterval = 30

    // Perform request
    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw Errors.invalidResponse
    }

    Self.logger.debug(
      "Received response",
      metadata: ["statusCode": "\(httpResponse.statusCode)", "icao": "\(icao)"]
    )

    // Handle errors
    if httpResponse.statusCode != 200 {
      // Try to decode error response
      if let errorResponse = try? decoder.decode(NOTAMErrorResponse.self, from: data) {
        Self.logger.error(
          "API error",
          metadata: [
            "statusCode": "\(httpResponse.statusCode)",
            "errorCode": "\(errorResponse.error.code)",
            "message": "\(errorResponse.error.message)"
          ]
        )
        throw Errors.apiError(
          statusCode: httpResponse.statusCode,
          code: errorResponse.error.code,
          message: errorResponse.error.message
        )
      }
      throw Errors.badResponse(httpResponse)
    }

    // Decode successful response
    do {
      let notamResponse = try decoder.decode(DownloadedNOTAMList.self, from: data)
      Self.logger.info(
        "Successfully fetched NOTAMs",
        metadata: [
          "icao": "\(icao)",
          "count": "\(notamResponse.data.count)",
          "total": "\(notamResponse.pagination.total)"
        ]
      )
      return notamResponse
    } catch {
      Self.logger.error("Failed to decode NOTAM response", metadata: ["error": "\(error)"])
      throw Errors.decodingFailed(error)
    }
  }

  /// Fetches a single NOTAM by its ID.
  ///
  /// - Parameter notamId: The NOTAM identifier (e.g., "FDC 2/1234")
  /// - Returns: NOTAM response including raw message
  /// - Throws: `NOTAMLoader.Errors` on failure
  public func fetchNOTAM(id notamId: String) async throws -> DownloadedNOTAM {
    // URL-encode the NOTAM ID
    guard
      let encodedId = notamId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed)
    else {
      throw Errors.invalidURL
    }

    guard let url = URL(string: "\(baseURL)/api/notams/\(encodedId)") else {
      throw Errors.invalidURL
    }

    Self.logger.info("Fetching single NOTAM", metadata: ["notamId": "\(notamId)"])

    // Create request with authentication
    var request = URLRequest(url: url)
    request.setValue("Bearer \(apiToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Accept")
    request.timeoutInterval = 30

    // Perform request
    let (data, response) = try await session.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw Errors.invalidResponse
    }

    // Handle errors
    if httpResponse.statusCode != 200 {
      if let errorResponse = try? decoder.decode(NOTAMErrorResponse.self, from: data) {
        throw Errors.apiError(
          statusCode: httpResponse.statusCode,
          code: errorResponse.error.code,
          message: errorResponse.error.message
        )
      }
      throw Errors.badResponse(httpResponse)
    }

    // Decode response (single NOTAM endpoint returns { "data": {...} })
    struct SingleNOTAMResponse: Codable {
      let data: DownloadedNOTAM
    }

    do {
      let singleResponse = try decoder.decode(SingleNOTAMResponse.self, from: data)
      Self.logger.info("Successfully fetched NOTAM", metadata: ["notamId": "\(notamId)"])
      return singleResponse.data
    } catch {
      Self.logger.error("Failed to decode NOTAM response", metadata: ["error": "\(error)"])
      throw Errors.decodingFailed(error)
    }
  }

  /// Errors that can occur during NOTAM loading
  public enum Errors: Error {
    /// Invalid URL construction
    case invalidURL

    /// Invalid or unexpected response
    case invalidResponse

    /// HTTP error response
    case badResponse(HTTPURLResponse)

    /// API returned an error
    case apiError(statusCode: Int, code: String, message: String)

    /// Failed to decode API response
    case decodingFailed(Error)

    /// Network request failed
    case networkError(Error)
  }
}
