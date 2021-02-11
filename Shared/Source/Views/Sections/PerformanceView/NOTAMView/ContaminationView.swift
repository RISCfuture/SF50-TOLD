import SwiftUI
import CoreData

struct ContaminationView: View {
    @ObservedObject var notam: NOTAM
    private let formatter = numberFormatter(precision: 1)
    
    var body: some View {
        Section(header: Text("Contamination")) {
            HStack {
                Text("Runway Wet")
                Toggle("", isOn: $notam.wet)
                    .accessibilityIdentifier("wetToggle")
            }
        }
    }
    
    private func formatDepth(_ depth: NSDecimalNumber?) -> String {
        guard let depthStr = formatter.string(from: depth ?? 0) else { return "" }
        return "\(depthStr)″"
    }
    
    private func formatDepth(_ depth: Double) -> String {
        formatDepth(NSDecimalNumber(value: depth))
    }
}

struct ContaminationView_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    
    private static let notam = NOTAM(entity: model.entitiesByName["NOTAM"]!, insertInto: nil)
    
    static var previews: some View {
        List {
            ContaminationView(notam: notam)
        }
    }
}
