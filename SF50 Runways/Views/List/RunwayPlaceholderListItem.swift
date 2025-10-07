import SwiftUI
import WidgetKit

struct RunwayPlaceholderListItem: View {
  let runwayName: String
  let headwind: String
  let tailwind: String
  let distance: String
  let available: String
  let isGreen: Bool

  var body: some View {
    HStack {
      Text(runwayName).bold()
        .opacity(0.6)

      Text("\(headwind) H / \(tailwind) T")
        .font(.caption)
        .opacity(0.4)

      Spacer()

      Text("\(distance) / \(available)")
        .foregroundColor(isGreen ? .green : .red)
        .opacity(0.6)
    }
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .fill(.thinMaterial)
        .opacity(0.7)
    )
  }
}
