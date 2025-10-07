import SwiftUI

/// The type of performance operation being calculated.
public enum Operation: Sendable {
  /// Takeoff performance calculation
  case takeoff
  /// Landing performance calculation
  case landing
}

private struct OperationKey: EnvironmentKey {
  static let defaultValue = Operation.takeoff
}

extension EnvironmentValues {
  /// The current performance operation type (takeoff or landing) for the view hierarchy.
  public var operation: Operation {
    get { self[OperationKey.self] }
    set { self[OperationKey.self] = newValue }
  }
}
