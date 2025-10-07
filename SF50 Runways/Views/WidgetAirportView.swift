import SwiftUI
import WidgetKit

struct WidgetAirportView: View {
  var name: String?
  var body: some View {
    if let name {
      Text(name)
        .font(.system(size: 11))
        .bold()
    } else {
      Text("Airport Name").redacted(reason: .placeholder)
    }
  }
}
