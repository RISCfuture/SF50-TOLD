import SwiftUI
import WidgetKit

struct RunwayPlaceholderGridItem: View {
  let runwayName: String
  let isGreen: Bool

  var body: some View {
    HStack(spacing: 2) {
      Image(systemName: isGreen ? "checkmark.circle.fill" : "x.circle.fill")
        .foregroundColor(isGreen ? .green : .red)
        .opacity(0.5)
        .accessibilityHidden(true)

      Text(runwayName)
        .bold()
        .opacity(0.5)
        .fixedSize(horizontal: true, vertical: false)
    }
    .overlay(
      RoundedRectangle(cornerRadius: 4)
        .fill(.regularMaterial)
        .opacity(0.8)
    )
  }
}
