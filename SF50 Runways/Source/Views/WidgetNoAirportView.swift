import SwiftUI
import WidgetKit

struct WidgetNoAirportView: View {
    @Environment(\.widgetFamily) var family: WidgetFamily
    
    private var fontSize: CGFloat {
        switch family {
            case .systemSmall: return 12
            default: return 14
        }
    }
    
    var body: some View {
        Text("Select an airport from the SF50 TOLD app first.")
            .foregroundColor(.secondary)
            .padding()
            .font(.system(size: fontSize))
    }
}

struct WidgetNoAirportView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetNoAirportView()
        .previewContext(WidgetPreviewContext(family: .systemSmall))
        .environment(\.widgetFamily, .systemSmall)
        
        WidgetNoAirportView()
        .previewContext(WidgetPreviewContext(family: .systemMedium))
        .environment(\.widgetFamily, .systemMedium)
    }
}
