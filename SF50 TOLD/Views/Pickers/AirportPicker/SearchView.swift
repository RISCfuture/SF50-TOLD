import Defaults
import SF50_Shared
import SwiftData
import SwiftUI

struct SearchView: View {
  var onSelect: (Airport) -> Void
  @State private var viewModel: SearchViewModel?

  @Environment(\.modelContext)
  private var modelContext

  var body: some View {
    NavigationStack {
      if let viewModel {
        SearchResults(viewModel: viewModel, onSelect: onSelect)
          .searchable(
            text: Binding(
              get: { viewModel.searchText },
              set: { viewModel.searchText = $0 }
            )
          )
      }
    }
    .onAppear {
      if viewModel == nil {
        viewModel = SearchViewModel(container: modelContext.container)
      }
    }
  }
}

private struct SearchResults: View {
  var viewModel: SearchViewModel
  var onSelect: (Airport) -> Void

  var body: some View {
    Group {
      if viewModel.sortedAirports.isEmpty {
        List {
          Text("No results.")
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.leading)
        }
      } else {
        List(viewModel.sortedAirports) { (airport: Airport) in
          AirportRow(airport: airport, showFavoriteButton: true)
            .onTapGesture {
              onSelect(airport)
            }
            .accessibility(addTraits: .isButton)
            .accessibilityIdentifier("airportRow-\(airport.displayID)")
        }
      }
    }
  }
}

#Preview {
  PreviewView(insert: .KOAK, .K1C9, .KSQL) { preview in
    preview.setUpToDate()

    return SearchView { _ in }
  }
}
