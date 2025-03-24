import SwiftUI
import CoreData
import WidgetKit

struct RunwayGridItem: View {
    var runway: Runway
    var takeoffDistance: Interpolation?

    var body: some View {
        HStack(spacing: 2) {
            switch takeoffDistance {
                case let .value(value, _):
                    if Int16(value) > runway.takeoffDistance {
                        Image(systemName: "x.circle.fill")
                            .foregroundColor(.red)
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                case .configNotAuthorized:
                    Image(systemName: "x.circle.fill")
                        .foregroundColor(.red)
                case .none:
                    Image(systemName: "questionmark.circle.fill")
                        .foregroundColor(.gray)
            }

            Text(runway.name!)
                .bold()
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

struct RunwayGridItem_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!

    static var rwy33 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "33"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        return r
    }()

    static var previews: some View {
        RunwayGridItem(runway: rwy33, takeoffDistance: .value(2300, offscale: .none))
            .containerBackground(for: .widget) { Color("WidgetBackground") }
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
