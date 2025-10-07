import SwiftUI
import WidgetKit

struct WidgetNoAirportView: View {
  @Environment(\.widgetFamily)
  var family

  private var fontSize: CGFloat {
    switch family {
      case .systemSmall: return 12
      default: return 14
    }
  }

  var body: some View {
    Text("Select an airport from the SF50 TOLD app first.")
      .foregroundColor(.secondary)
      .font(.system(size: fontSize))
      .containerBackground(.background, for: .widget)
  }
}
