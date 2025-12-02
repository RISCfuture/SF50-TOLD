import Foundation

/// A type representing the state of a view's data loading lifecycle.
///
/// ``ViewState`` is similar to ``Loadable`` but uses terminology more aligned
/// with UI patterns. It tracks whether a view is idle, loading, has data, or
/// encountered an error.
///
/// ## States
///
/// - ``idle``: View is ready but hasn't started loading
/// - ``loading``: Data is being fetched
/// - ``loaded(_:)``: Data is available
/// - ``error(_:)``: An error occurred
///
/// ## Usage
///
/// ```swift
/// @Published var state: ViewState<[Airport]> = .idle
///
/// var body: some View {
///     switch state {
///     case .idle:
///         Button("Load") { load() }
///     case .loading:
///         ProgressView()
///     case .loaded(let airports):
///         List(airports) { ... }
///     case .error(let error):
///         ErrorView(error: error)
///     }
/// }
/// ```
public enum ViewState<T>: Sendable where T: Sendable {
  /// View is idle, no loading has started.
  case idle
  /// Data is being loaded.
  case loading
  /// Data has been loaded successfully.
  case loaded(T)
  /// An error occurred during loading.
  case error(Error)

  /// Whether data is currently being loaded.
  public var isLoading: Bool {
    if case .loading = self { return true }
    return false
  }

  /// Whether data has been loaded successfully.
  public var hasData: Bool {
    if case .loaded = self { return true }
    return false
  }

  /// Whether an error occurred during loading.
  public var hasError: Bool {
    if case .error = self { return true }
    return false
  }

  /// The loaded data, or nil if not in the `.loaded` state.
  public var data: T? {
    if case .loaded(let data) = self { return data }
    return nil
  }

  /// The error if in the `.error` state, or nil otherwise.
  public var error: Error? {
    if case .error(let error) = self { return error }
    return nil
  }

  /// Transforms the loaded data using the given closure.
  /// - Parameter transform: A closure that transforms the loaded data.
  /// - Returns: A new `ViewState` with the transformed data, or the same state if not loaded.
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
