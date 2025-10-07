import Defaults
import SwiftNASR
import SwiftUI

struct AboutView: View {
  private static let ourAirportsTimeout: TimeInterval = 60 * 60 * 24 * 28

  @Default(.lastCycleLoaded)
  private var lastCycleLoaded

  @Default(.ourAirportsLastUpdated)
  private var ourAirportsLastUpdated

  private var releaseVersionNumber: String {
    return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
  }

  private var buildVersionNumber: String {
    return Bundle.main.infoDictionary!["CFBundleVersion"] as! String
  }

  private var ourAirportsDataIsOld: Bool {
    guard let ourAirportsLastUpdated else { return true }
    return ourAirportsLastUpdated.timeIntervalSinceNow < -Self.ourAirportsTimeout
  }

  var body: some View {
    NavigationView {
      Form {
        Section("Application") {
          LabeledContent("Aircraft") {
            Text("Cirrus SF50 Vision (G1 through G2+)")
              .bold()
          }

          LabeledContent("App Version") {
            Text(
              "\(releaseVersionNumber) (\(buildVersionNumber))",
              comment: "release version (build number)"
            )
            .bold()
          }
        }

        Section("Nav Data Sources") {
          LabeledContent("FAA") {
            if let lastCycleLoaded {
              Text("Cycle \(lastCycleLoaded.id)")
                .bold()
                .foregroundStyle(lastCycleLoaded.isEffective ? Color.primary : Color.red)
            } else {
              Text("None loaded")
                .bold()
                .foregroundStyle(.secondary)
            }
          }

          LabeledContent("OurAirports") {
            if let ourAirportsLastUpdated {
              Text(ourAirportsLastUpdated, format: .dateTime.day().month().year())
                .bold()
                .foregroundStyle(ourAirportsDataIsOld ? Color.red : Color.primary)
            } else {
              Text("None loaded")
                .bold()
                .foregroundStyle(.secondary)
            }
          }
        }

        Section("SF50 G1 Data Source") {
          LabeledContent("Serials") {
            Text(
              "with Cirrus Perspective Touch Avionics System and FL280 Maximum Operating Altitude"
            )
            .bold()
            .font(.system(size: 14))
          }

          LabeledContent("P/N") {
            Text("31452-001", comment: "P/N")
              .bold()
          }

          LabeledContent("Revision") {
            Text("A1 (04 Feb 2022)")
              .bold()
          }
        }

        Section("SF50 G2–G2+ Data Source") {
          LabeledContent("Serials") {
            Text(
              "with Cirrus Perspective Touch+ Avionics System and FL310 Maximum Operating Altitude"
            )
            .bold()
            .font(.system(size: 14))
          }

          LabeledContent("P/N") {
            Text("31452-002", comment: "P/N")
              .bold()
          }

          LabeledContent("Revision") {
            Text("2 (04 Feb 2022)")
              .bold()
          }
        }

        Section("Updated Thrust Schedule Data Source") {
          LabeledContent("Serials") {
            Text("26000-004 or Compliance with SB5X-72-01")
              .bold()
              .font(.system(size: 14))
          }

          LabeledContent("P/N") {
            Text("31452-111", comment: "P/N")
              .bold()
          }

          LabeledContent("Revision") {
            Text("1 (10 Feb 2022)")
              .bold()
          }
        }

        Label(
          "This app has not been approved by the FAA or by Cirrus Aircraft as an official source of performance information. Always verify performance information with official sources when using this app.",
          systemImage: "exclamationmark.triangle"
        )
        .font(.system(size: 14))
        .foregroundStyle(.secondary)
      }.navigationTitle("About")
    }.navigationViewStyle(navigationStyle)
  }
}

#Preview {
  AboutView()
}
