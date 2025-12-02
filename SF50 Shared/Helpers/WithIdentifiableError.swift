import Foundation

/// A wrapper that makes any error conform to `Identifiable`.
///
/// ``IdentifiableError`` wraps an `Error` with a unique identifier, enabling
/// use with SwiftUI APIs that require `Identifiable` (like `.alert(item:)`).
///
/// ## Usage
///
/// ```swift
/// .alert(item: $viewModel.identifiableError) { identifiableError in
///     Alert(
///         title: Text("Error"),
///         message: Text(identifiableError.error.localizedDescription)
///     )
/// }
/// ```
public struct IdentifiableError: Identifiable, Equatable {
  /// Unique identifier for this error instance.
  public let id = UUID()
  /// The underlying error.
  public let error: Error

  public init(error: Error) {
    self.error = error
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

/// Protocol for types that expose errors as identifiable values.
///
/// ``WithIdentifiableError`` provides a standard pattern for view models
/// to expose errors in a way compatible with SwiftUI's `alert(item:)` API.
///
/// ## Conformance
///
/// Conforming types must provide a settable `error` property. The protocol
/// provides a default implementation of ``identifiableError`` that wraps
/// the error value.
///
/// ```swift
/// @Observable
/// class MyViewModel: WithIdentifiableError {
///     var error: Error?
/// }
/// ```
@MainActor
public protocol WithIdentifiableError {
  /// The current error, if any.
  var error: Error? { get set }
  /// The error wrapped as an identifiable value.
  var identifiableError: IdentifiableError? { get }
}

extension WithIdentifiableError {
  public var identifiableError: IdentifiableError? { error.map { .init(error: $0) } }
}
