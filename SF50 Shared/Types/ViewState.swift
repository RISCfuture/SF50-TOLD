import Foundation

public enum ViewState<T>: Sendable where T: Sendable {
  case idle
  case loading
  case loaded(T)
  case error(Error)

  public var isLoading: Bool {
    if case .loading = self { return true }
    return false
  }

  public var hasData: Bool {
    if case .loaded = self { return true }
    return false
  }

  public var hasError: Bool {
    if case .error = self { return true }
    return false
  }

  public var data: T? {
    if case .loaded(let data) = self { return data }
    return nil
  }

  public var error: Error? {
    if case .error(let error) = self { return error }
    return nil
  }

  public func map<U>(_ transform: (T) throws -> U) rethrows -> ViewState<U> {
    switch self {
      case .idle:
        return .idle
      case .loading:
        return .loading
      case .loaded(let data):
        return .loaded(try transform(data))
      case .error(let error):
        return .error(error)
    }
  }
}

extension ViewState: Equatable where T: Equatable {
  public static func == (lhs: ViewState<T>, rhs: ViewState<T>) -> Bool {
    switch (lhs, rhs) {
      case (.idle, .idle):
        return true
      case (.loading, .loading):
        return true
      case (.loaded(let lhsData), .loaded(let rhsData)):
        return lhsData == rhsData
      case (.error, .error):
        return true  // Don't compare errors, just state
      default:
        return false
    }
  }
}
