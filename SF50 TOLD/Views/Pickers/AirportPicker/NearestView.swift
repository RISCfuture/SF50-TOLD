import CoreLocation
import SF50_Shared
import SwiftData
import SwiftUI
import UIKit

struct NearestView: View {
  var onSelect: (Airport) -> Void

  @Environment(\.modelContext)
  private var modelContext

  @Environment(\.locationStreamer)
  private var locationStreamer

  @State private var nearestAirports: NearestAirportViewModel?
  @State private var authorizationStatus: CLAuthorizationStatus = .notDetermined

  var body: some View {
    Group {
      switch authorizationStatus {
        case .notDetermined:
          LocationPermissionPromptView()
        case .denied, .restricted:
          LocationDeniedView()
        case .authorizedWhenInUse, .authorizedAlways:
          if let nearestAirports {
            if let error = nearestAirports.error {
              LocationErrorView(error: error)
            } else if nearestAirports.airports.isEmpty {
              List {
                Text("No nearby airports.")
                  .foregroundStyle(.secondary)
                  .multilineTextAlignment(.leading)
              }
            } else {
              List(nearestAirports.airports) { (airport: Airport) in
                AirportRow(airport: airport, showFavoriteButton: true)
                  .onTapGesture {
                    onSelect(airport)
                  }
                  .accessibility(addTraits: .isButton)
                  .accessibilityIdentifier("airportRow-\(airport.displayID)")
              }
            }
          } else {
            List {
              Text("Unable to determine location.")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.leading)
            }
          }
        @unknown default:
          List {
            Text("Location services unavailable.")
              .foregroundStyle(.secondary)
              .multilineTextAlignment(.leading)
          }
      }
    }
    .task {
      authorizationStatus = CLLocationManager().authorizationStatus
      if authorizationStatus == .notDetermined || authorizationStatus == .authorizedWhenInUse
        || authorizationStatus == .authorizedAlways
      {
        await locationStreamer.start()
        nearestAirports = .init(
          container: modelContext.container,
          locationStreamer: locationStreamer
        )
      }
    }
    .onDisappear {
      Task {
        await locationStreamer.stop()
      }
    }
    .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification))
    { _ in
      // Check authorization status when app becomes active (user might have changed it in Settings)
      Task { @MainActor in
        let newStatus = CLLocationManager().authorizationStatus
        if newStatus != authorizationStatus {
          authorizationStatus = newStatus
          if newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways {
            await locationStreamer.start()
            nearestAirports = .init(
              container: modelContext.container,
              locationStreamer: locationStreamer
            )
          }
        }
      }
    }
    .onReceive(Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()) { _ in
      let newStatus = CLLocationManager().authorizationStatus
      if newStatus != authorizationStatus {
        authorizationStatus = newStatus
        if (newStatus == .authorizedWhenInUse || newStatus == .authorizedAlways)
          && nearestAirports == nil
        {
          Task {
            await locationStreamer.start()
            nearestAirports = .init(
              container: modelContext.container,
              locationStreamer: locationStreamer
            )
          }
        }
      }
    }
  }
}

#Preview("Airports") {
  PreviewView(insert: .KOAK, .K1C9, .KSQL) { _ in
    return NearestView { _ in }
      .environment(\.locationStreamer, MockLocationStreamer())
  }
}

#Preview("No Airports") {
  PreviewView { _ in
    return NearestView { _ in }
      .environment(\.locationStreamer, MockLocationStreamer())
  }
}
