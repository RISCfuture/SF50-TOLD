import SwiftUI
import WidgetKit

struct LocationNotAuthorizedView: View {
    @Environment(\.widgetFamily)
    var family

    private var fontSize: CGFloat {
        switch family {
            case .systemSmall: return 12
            default: return 14
        }
    }

    var body: some View {
        Text("Couldn’t find your closest airport.")
            .foregroundColor(.secondary)
            .font(.system(size: fontSize))
            .containerBackground(for: .widget) { Color("WidgetBackground") }
    }
}

struct LocationNotAuthorizedView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LocationNotAuthorizedView()
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            LocationNotAuthorizedView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
