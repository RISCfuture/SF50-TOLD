import SwiftUI
import WidgetKit

struct OffscaleWarningView: View {
    var offscale: Offscale
    
    var body: some View {
        switch offscale {
            case .none, .low:
                EmptyView()
            case .high:
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
        }
    }
}

struct OffscaleWarningView_Previews: PreviewProvider {
    static var previews: some View {
        OffscaleWarningView(offscale: .high)
            .containerBackground(for: .widget) { Color("WidgetBackground") }
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
