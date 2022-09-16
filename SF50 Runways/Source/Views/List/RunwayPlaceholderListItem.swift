import SwiftUI
import WidgetKit

struct RunwayPlaceholderListItem: View {
    var body: some View {
        HStack {
            Text("RWY").bold()
                .redacted(reason: .placeholder)
            
            Spacer()
            
            Text("10,000 ft. / 10,000 ft.")
                .redacted(reason: .placeholder)
        }
    }
}

struct RunwayPlaceholderListItem_Previews: PreviewProvider {
    static var previews: some View {
        RunwayPlaceholderListItem()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
