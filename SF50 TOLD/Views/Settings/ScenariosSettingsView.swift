import SF50_Shared
import SwiftData
import SwiftUI

struct ScenariosSettingsView: View {
  @Environment(\.modelContext)
  private var modelContext

  @Query(filter: #Predicate<Scenario> { $0._operation == "takeoff" }, sort: \Scenario.name)
  private var takeoffScenarios: [Scenario]

  @Query(filter: #Predicate<Scenario> { $0._operation == "landing" }, sort: \Scenario.name)
  private var landingScenarios: [Scenario]

  @State private var errorState = ErrorState()

  var body: some View {
    Form {
      Section("Takeoff Scenarios") {
        ForEach(takeoffScenarios) { scenario in
          NavigationLink(destination: ScenarioDetailView(scenario: scenario)) {
            Text(scenario.name)
          }
        }
        .onDelete { indices in
          deleteScenarios(at: indices, from: takeoffScenarios)
        }

        NavigationLink(destination: NewScenarioView(operation: .takeoff)) {
          Label("Add Scenario", systemImage: "plus.circle.fill")
        }
      }

      Section("Landing Scenarios") {
        ForEach(landingScenarios) { scenario in
          NavigationLink(destination: ScenarioDetailView(scenario: scenario)) {
            Text(scenario.name)
          }
        }
        .onDelete { indices in
          deleteScenarios(at: indices, from: landingScenarios)
        }

        NavigationLink(destination: NewScenarioView(operation: .landing)) {
          Label("Add Scenario", systemImage: "plus.circle.fill")
        }
      }

      if takeoffScenarios.isEmpty && landingScenarios.isEmpty {
        Section {
          Button("Restore Default Scenarios") { restoreDefaultScenarios() }
        }
      }
    }
    .navigationTitle("Scenarios")
    .withErrorSheet(state: errorState)
  }

  private func deleteScenarios(at offsets: IndexSet, from scenarios: [Scenario]) {
    for index in offsets {
      modelContext.delete(scenarios[index])
    }
  }

  private func restoreDefaultScenarios() {
    withAnimation {
      for scenario in Scenario.defaultScenarios() {
        modelContext.insert(scenario)
      }

      do {
        try modelContext.save()
      } catch {
        errorState.error = error
      }
    }
  }
}

private struct NewScenarioView: View {
  @Environment(\.modelContext)
  private var modelContext

  let operation: SF50_Shared.Operation

  @State private var scenario: Scenario?

  var body: some View {
    Group {
      if let scenario {
        ScenarioDetailView(scenario: scenario)
      } else {
        ProgressView()
          .onAppear {
            createScenario()
          }
      }
    }
  }

  private func createScenario() {
    let newScenario = Scenario(name: "New Scenario", operation: operation)
    modelContext.insert(newScenario)
    try? modelContext.save()
    scenario = newScenario
  }
}

@MainActor
@Observable
private final class ErrorState: WithIdentifiableError {
  var error: Error?
}

#Preview("With Scenarios") {
  PreviewView { helper in
    try helper.insertBasicScenarios()

    return NavigationStack {
      ScenariosSettingsView()
    }
  }
}

#Preview("No Scenarios") {
  PreviewView { _ in
    NavigationStack {
      ScenariosSettingsView()
    }
  }
}
