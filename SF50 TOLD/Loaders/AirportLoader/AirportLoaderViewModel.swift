import Defaults
import Observation
import SF50_Shared
import SwiftData
import SwiftNASR

@Observable
@MainActor
final class AirportLoaderViewModel: WithIdentifiableError {
  private(set) var state: AirportLoader.State = .idle
  var error: Swift.Error?

  private(set) var noData = false
  private(set) var needsLoad = true
  private(set) var canSkip = false
  private(set) var networkIsExpensive = false
  private(set) var deferred = false

  private let container: ModelContainer
  private var cancellables: Set<Task<Void, Never>> = []

  var showLoader: Bool {
    (noData || needsLoad) && !deferred
  }

  init(container: ModelContainer) {
    self.container = container
    do {
      try recalculate()
    } catch {
      self.error = error
    }

    setupObservation()
  }

  private func setupObservation() {
    addTask(
      Task {
        for await _ in Defaults.updates([.schemaVersion, .lastCycleLoaded]) where !Task.isCancelled
        {
          do {
            try recalculate()
          } catch {
            self.error = error
          }
        }
      }
    )

    addTask(
      Task {
        do {
          let context = ModelContext(container)
          try setAnyAirports(context: context)
          while !Task.isCancelled {
            try setAnyAirports(context: context)
            try? await Task.sleep(for: .seconds(0.5))
          }
        } catch {
          self.error = error
        }
      }
    )
  }

  private func addTask(_ task: Task<Void, Never>) {
    cancellables.insert(task)
  }

  func load() {
    let loader = AirportLoader(modelContainer: container)

    addTask(
      Task {
        do {
          error = nil
          Defaults[.lastCycleLoaded] = nil
          Defaults[.ourAirportsLastUpdated] = nil
          let (cycle, lastUpdated) = try await loader.load()

          await MainActor.run {
            Defaults[.lastCycleLoaded] = cycle
            Defaults[.ourAirportsLastUpdated] = lastUpdated
            Defaults[.schemaVersion] = latestSchemaVersion
          }
        } catch {
          self.error = error
        }
      }
    )

    addTask(
      Task { [weak self] in
        while !Task.isCancelled {
          let state = await loader.state
          self?.state = state
          try? await Task.sleep(for: .seconds(0.25))
        }
      }
    )
  }

  func loadLater() {
    if canSkip { deferred = true }
  }

  private func outOfDate(cycle: Cycle?) -> Bool {
    if let cycle, cycle.isEffective { return false }
    return true
  }

  private func outOfDate(schemaVersion: Int) -> Bool {
    schemaVersion != latestSchemaVersion
  }

  private func recalculate() throws {
    let schemaOutOfDate = outOfDate(schemaVersion: Defaults[.schemaVersion])
    let cycleOutOfDate = outOfDate(cycle: Defaults[.lastCycleLoaded])
    needsLoad = schemaOutOfDate || cycleOutOfDate
    canSkip = !noData && !schemaOutOfDate
  }

  private func setAnyAirports(context: ModelContext) throws {
    var descriptor = FetchDescriptor<SF50_Shared.Airport>()
    descriptor.fetchLimit = 1
    noData = try context.fetch(descriptor).isEmpty
    try recalculate()
  }
}
