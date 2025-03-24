import SwiftUI
import WidgetKit

struct WidgetAirportView: View {
    var name: String?
    var body: some View {
        if let name {
            Text(name)
                .font(.system(size: 11))
                .bold()
        } else {
            Text("Airport Name").redacted(reason: .placeholder)
        }
    }
}

struct WidgetAirportView_Previews: PreviewProvider {
    static var previews: some View {
        WidgetAirportView(name: "Metro Oakland Intl")
            .containerBackground(for: .widget) { Color("WidgetBackground") }
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
