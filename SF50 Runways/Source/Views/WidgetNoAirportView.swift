import SwiftUI
import WidgetKit

struct WidgetNoAirportView: View {
    @Environment(\.widgetFamily) var family
    
    private var fontSize: CGFloat {
        switch family {
            case .systemSmall: return 12
            default: return 14
        }
    }
    
    var body: some View {
        Text("Select an airport from the SR22-G2 TOLD app first.")
            .foregroundColor(.secondary)
            .font(.system(size: fontSize))
            .containerBackground(for: .widget) { Color("WidgetBackground") }
    }
}

struct WidgetNoAirportView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WidgetNoAirportView()
                .previewContext(WidgetPreviewContext(family: .systemSmall))
            
            WidgetNoAirportView()
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
    }
}
