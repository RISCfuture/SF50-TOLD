import CoreLocation
import Defaults
import SF50_Shared
import SwiftUI

private enum AirportPickerTabs {
  case favorites
  case recents
  case nearest
  case search
}

struct AirportPicker: View {
  var onSelect: (Airport) -> Void

  @State private var tabIndex: AirportPickerTabs = .favorites
  @State private var showNearestTab = false

  @Environment(\.presentationMode)
  private var mode

  @Environment(\.locationStreamer)
  private var locationStreamer

  @Default(.recentAirports)
  private var recentAirports

  var body: some View {
    VStack(alignment: .leading) {
      Picker("Tab", selection: $tabIndex) {
        Text("Favorites").tag(AirportPickerTabs.favorites)
        Text("Recents").tag(AirportPickerTabs.recents)
        if showNearestTab {
          Text("Nearest").tag(AirportPickerTabs.nearest)
        }
        Text("Search").tag(AirportPickerTabs.search)
      }
      .pickerStyle(SegmentedPickerStyle())
      .padding(.horizontal)
      .accessibilityIdentifier("airportListPicker")

      switch tabIndex {
        case .favorites: FavoritesView(onSelect: selectAndDismiss)
        case .recents: RecentsView(onSelect: selectAndDismiss)
        case .nearest: NearestView(onSelect: selectAndDismiss)
        case .search: SearchView(onSelect: selectAndDismiss)
      }
    }
    .task {
      showNearestTab =
        CLLocationManager.locationServicesEnabled()
        && CLLocationManager.significantLocationChangeMonitoringAvailable()
    }
  }

  private func selectAndDismiss(airport: Airport) {
    recentAirports.appendRemovingDuplicates(of: airport.recordID)
    if recentAirports.count > 10 {
      recentAirports.removeFirst(recentAirports.count - 10)
    }

    onSelect(airport)
    mode.wrappedValue.dismiss()
  }
}

#Preview {
  PreviewView(insert: .KOAK, .K1C9, .KSQL) { preview in
    preview.setUpToDate()
    Defaults[.favoriteAirports] = ["OAK"]
    Defaults[.recentAirports] = ["SQL"]

    return AirportPicker { _ in }
      .environment(\.locationStreamer, MockLocationStreamer())
  }
}
