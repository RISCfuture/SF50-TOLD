import SwiftUI
import WidgetKit

struct RunwayPlaceholderGridItem: View {
    var body: some View {
        HStack(spacing: 2) {
            Text("RWY")
                .redacted(reason: .placeholder)
            Image(systemName: "questionmark.circle.fill")
                .foregroundColor(.gray)
                .redacted(reason: .placeholder)
        }
    }
}

struct RunwayPlaceholderGridItem_Previews: PreviewProvider {
    static var previews: some View {
        RunwayPlaceholderGridItem()
            .containerBackground(for: .widget) { Color("WidgetBackground") }
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
