import CoreData
import SwiftUI
import WidgetKit

struct RunwayListItem: View {
    var runway: Runway
    var takeoffDistance: Interpolation?
    var wind: Wind?
    var crosswindLimit: UInt?
    var tailwindLimit: UInt?

    var body: some View {
        HStack {
            Text(runway.name!).bold()
                .fixedSize(horizontal: true, vertical: false)

            WindComponents(runway: runway,
                           wind: wind,
                           crosswindLimit: crosswindLimit,
                           tailwindLimit: tailwindLimit)

            Spacer()

            switch takeoffDistance {
                case let .value(value, offscale):
                    if Int16(value) > runway.takeoffDistance {
                        Text(formatDistance(Int16(value)))
                            .foregroundColor(.red)
                    } else {
                        Text(formatDistance(Int16(value)))
                            .foregroundColor(.green)
                    }
                    Text("/")
                    Text(formatDistance(runway.takeoffDistance))

                    OffscaleWarningView(offscale: offscale)
                case .configNotAuthorized:
                    Text("Config N/A")
                        .foregroundColor(.red)
                        .bold()
                case .none:
                    Text("10,000' / 10,000'")
                        .redacted(reason: .placeholder)
            }
        }
    }

    private func formatDistance(_ distance: Int16) -> String {
        return "\(integerFormatter.string(for: Int(distance)))′"
    }
}

struct RunwayListItem_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!

    static var rwy33 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "33"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        return r
    }()

    static var previews: some View {
        RunwayListItem(runway: rwy33,
                       takeoffDistance: .value(2300, offscale: .high),
                       wind: .init(direction: 260, speed: 10))
        .containerBackground(for: .widget) { Color("WidgetBackground") }
        .previewContext(WidgetPreviewContext(family: .systemMedium))
    }
}
