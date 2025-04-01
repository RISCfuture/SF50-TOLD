import SwiftUI
import WidgetKit

struct RunwayPlaceholderListItem: View {
    var body: some View {
        HStack {
            Text("RWY").bold()
                .redacted(reason: .placeholder)

            Text("2 H / 3 L").bold()
                .redacted(reason: .placeholder)

            Spacer()

            Text("10,000 / 10,000")
                .redacted(reason: .placeholder)
        }
    }
}

struct RunwayPlaceholderListItem_Previews: PreviewProvider {
    static var previews: some View {
        RunwayPlaceholderListItem()
            .containerBackground(for: .widget) { Color("WidgetBackground") }
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
