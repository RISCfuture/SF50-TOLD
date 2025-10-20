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
    }
    .navigationTitle("Scenarios")
  }

  private func deleteScenarios(at offsets: IndexSet, from scenarios: [Scenario]) {
    for index in offsets {
      modelContext.delete(scenarios[index])
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

#Preview {
  PreviewView { helper in
    try helper.insertBasicScenarios()

    return NavigationStack {
      ScenariosSettingsView()
    }
  }
}
