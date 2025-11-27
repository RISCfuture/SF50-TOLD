import Foundation

/// Response from the NOTAM API containing NOTAM data and pagination info.
public struct NOTAMListResponse: Codable, Sendable {
  /// Array of NOTAM entries
  public let data: [NOTAMResponse]

  /// Pagination metadata
  public let pagination: Pagination

  public struct Pagination: Codable, Sendable {
    /// Total number of NOTAMs matching the query
    public let total: Int

    /// Maximum number of results per page
    public let limit: Int

    /// Number of results skipped
    public let offset: Int
  }
}

/// Individual NOTAM entry from the API.
public struct NOTAMResponse: Codable, Sendable, Identifiable {
  /// Database primary key
  public let id: Int

  /// Official NOTAM identifier (e.g., "FDC 2/1234")
  public let notamId: String

  /// ICAO airport/location code
  public let icaoLocation: String

  /// When the NOTAM becomes effective (UTC)
  public let effectiveStart: Date

  /// When the NOTAM expires (nil for permanent NOTAMs)
  public let effectiveEnd: Date?

  /// D-field: Daily schedule if applicable (e.g., "0800-1800")
  public let schedule: String?

  /// E-field: Human-readable NOTAM description
  public let notamText: String

  /// Structured Q-line data (may be nil for text NOTAMs)
  public let qLine: QLine?

  /// NOTAM purpose code
  public let purpose: String?

  /// NOTAM scope code
  public let scope: String?

  /// Traffic type code
  public let trafficType: String?

  /// When the record was created in the database
  public let createdAt: Date

  /// When the record was last updated
  public let updatedAt: Date

  /// Raw AIXM XML or text NOTAM (only included in single NOTAM endpoint)
  public let rawMessage: String?

  /// Public initializer for creating NOTAM responses (e.g., in previews and tests)
  public init(
    id: Int,
    notamId: String,
    icaoLocation: String,
    effectiveStart: Date,
    effectiveEnd: Date?,
    schedule: String?,
    notamText: String,
    qLine: QLine?,
    purpose: String?,
    scope: String?,
    trafficType: String?,
    createdAt: Date = Date(),
    updatedAt: Date = Date(),
    rawMessage: String? = nil
  ) {
    self.id = id
    self.notamId = notamId
    self.icaoLocation = icaoLocation
    self.effectiveStart = effectiveStart
    self.effectiveEnd = effectiveEnd
    self.schedule = schedule
    self.notamText = notamText
    self.qLine = qLine
    self.purpose = purpose
    self.scope = scope
    self.trafficType = trafficType
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.rawMessage = rawMessage
  }

  enum CodingKeys: String, CodingKey {
    case id
    case notamId = "notam_id"
    case icaoLocation = "icao_location"
    case effectiveStart = "effective_start"
    case effectiveEnd = "effective_end"
    case schedule
    case notamText = "notam_text"
    case qLine = "q_line"
    case purpose
    case scope
    case trafficType = "traffic_type"
    case createdAt = "created_at"
    case updatedAt = "updated_at"
    case rawMessage = "raw_message"
  }
}

/// Structured Q-line data from a NOTAM.
public struct QLine: Codable, Sendable {
  /// NOTAM purpose code (N, B, O, M, K)
  public let purpose: String?

  /// NOTAM scope (A, E, W)
  public let scope: String?

  /// Traffic type code
  public let trafficType: String?

  /// Lower altitude limit
  public let lowerAltitude: String?

  /// Upper altitude limit
  public let upperAltitude: String?

  /// Coordinates
  public let coordinates: String?

  enum CodingKeys: String, CodingKey {
    case purpose
    case scope
    case trafficType = "traffic_type"
    case lowerAltitude = "lower_altitude"
    case upperAltitude = "upper_altitude"
    case coordinates
  }
}

/// Error response from the NOTAM API.
public struct NOTAMErrorResponse: Codable, Sendable {
  /// Error details
  public let error: ErrorDetail

  public struct ErrorDetail: Codable, Sendable {
    /// Human-readable error message
    public let message: String

    /// Machine-readable error code
    public let code: String
  }
}

extension NOTAMResponse {
  /// Returns true if the NOTAM is currently effective.
  public var isEffectiveNow: Bool {
    let now = Date()
    if now < effectiveStart {
      return false
    }
    if let end = effectiveEnd, now > end {
      return false
    }
    return true
  }

  /// Returns true if the NOTAM is related to runways (aerodrome scope).
  public var isAerodromeRelated: Bool {
    scope == "A" || qLine?.scope == "A"
  }

  /// Returns a short summary of the NOTAM for display purposes.
  public var summary: String {
    if notamText.count <= 60 {
      return notamText
    }
    return String(notamText.prefix(57)) + "..."
  }

  /// Returns true if the NOTAM has expired before the given time window.
  ///
  /// - Parameters:
  ///   - referenceTime: The reference time (e.g., planned departure/arrival)
  ///   - windowInterval: How far before the reference time to check (default: 1 hour)
  /// - Returns: True if NOTAM expired before the time window
  public func hasExpired(before referenceTime: Date, windowInterval: TimeInterval = 3600) -> Bool {
    guard let end = effectiveEnd else { return false }
    return end < referenceTime.addingTimeInterval(-windowInterval)
  }

  /// Returns true if the NOTAM is effective within a time window around the reference time.
  ///
  /// - Parameters:
  ///   - referenceTime: The reference time (e.g., planned departure/arrival)
  ///   - windowInterval: The time window before/after reference time (default: 1 hour)
  /// - Returns: True if NOTAM is effective during the time window
  public func isEffective(
    within referenceTime: Date,
    windowInterval: TimeInterval = 3600
  ) -> Bool {
    let windowStart = referenceTime.addingTimeInterval(-windowInterval)
    let windowEnd = referenceTime.addingTimeInterval(windowInterval)

    // Check if NOTAM starts before window ends
    guard effectiveStart <= windowEnd else { return false }

    // Check if NOTAM ends after window starts (or has no end date)
    if let end = effectiveEnd {
      return end >= windowStart
    }

    // No end date means permanent/indefinite
    return true
  }

  /// Returns the time interval until this NOTAM becomes effective, relative to a reference time.
  ///
  /// - Parameter referenceTime: The reference time (e.g., planned departure/arrival)
  /// - Returns: Time interval until effective (negative if already started)
  public func timeUntilEffective(from referenceTime: Date) -> TimeInterval {
    return effectiveStart.timeIntervalSince(referenceTime)
  }

  /// Returns true if the NOTAM will become effective in the future relative to the reference time.
  ///
  /// - Parameter referenceTime: The reference time (e.g., planned departure/arrival)
  /// - Returns: True if NOTAM starts after the reference time
  public func isInFuture(relativeTo referenceTime: Date) -> Bool {
    return effectiveStart > referenceTime
  }
}
