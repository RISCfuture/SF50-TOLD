import Foundation

public struct IdentifiableError: Identifiable, Equatable {
  public let id = UUID()
  public let error: Error

  public init(error: Error) {
    self.error = error
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id
  }
}

@MainActor
public protocol WithIdentifiableError {
  var error: Error? { get set }
  var identifiableError: IdentifiableError? { get }
}

extension WithIdentifiableError {
  public var identifiableError: IdentifiableError? { error.map { .init(error: $0) } }
}
