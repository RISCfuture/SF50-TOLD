public enum Loadable<Loaded>: Sendable where Loaded: Sendable {
  case notLoaded
  case loading
  case value(_ value: Loaded)
  case error(_ error: Error)

  public func map<U>(_ transform: (Loaded) throws -> U) rethrows -> Loadable<U> {
    switch self {
      case .value(let value):
        .value(try transform(value))
      case .error(let error): .error(error)
      case .loading: .loading
      case .notLoaded: .notLoaded
    }
  }
}

extension Loadable {
  public var isLoading: Bool {
    if case .loading = self { return true }
    return false
  }

  public var hasValue: Bool {
    if case .value = self { return true }
    return false
  }

  public var hasError: Bool {
    if case .error = self { return true }
    return false
  }

  public var isNotLoaded: Bool {
    if case .notLoaded = self { return true }
    return false
  }

  public var value: Loaded? {
    if case .value(let value) = self { return value }
    return nil
  }

  public var error: Error? {
    if case .error(let error) = self { return error }
    return nil
  }
}
