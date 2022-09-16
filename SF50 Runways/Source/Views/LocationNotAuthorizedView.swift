import SwiftUI
import WidgetKit

struct LocationNotAuthorizedView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    private var fontSize: CGFloat {
        switch family {
            case .systemSmall: return 12
            default: return 14
        }
    }
    
    var body: some View {
        Text("You must authorize this widget to access your location.")
            .foregroundColor(.secondary)
            .padding()
            .font(.system(size: fontSize))
    }
}

struct LocationNotAuthorizedView_Previews: PreviewProvider {
    static var previews: some View {
        LocationNotAuthorizedView()
            .previewContext(WidgetPreviewContext(family: .systemSmall))
            .environment(\.widgetFamily, .systemSmall)
        
        LocationNotAuthorizedView()
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .environment(\.widgetFamily, .systemMedium)
    }
}
