import SwiftUI
import CoreData

struct ContaminationView: View {
    @ObservedObject var notam: NOTAM
    private let formatter = numberFormatter(precision: 1)
    
    private var typeBinding: Binding<String> {
        .init(
            get: { notam.contaminationType ?? "none" },
            set: { type in
                if type == "none" {
                    notam.clearContamination()
                } else {
                    notam.contaminationType = type
                }
            })
    }
    
    private var depthBinding: Binding<Float> {
        .init(get: { notam.contaminationDepth!.floatValue },
              set: { notam.contaminationDepth = NSDecimalNumber(value: $0) })
    }
    
    var body: some View {
        Section(header: Text("Contamination")) {
            HStack {
                Text("Contamination")
                Picker("", selection: typeBinding) {
                    Text("None").tag("none")
                    Text("Water/Slush").tag("waterOrSlush")
                    Text("Slush/Wet Snow").tag("slushOrWetSnow")
                    Text("Dry Snow").tag("drySnow")
                    Text("Compact Snow").tag("compactSnow")
                }.accessibilityIdentifier("contaminationTypePicker")
            }
            
            if notam.contaminationType == "waterOrSlush" || notam.contaminationType == "slushOrWetSnow" {
                VStack {
                    HStack {
                        Text("Depth")
                        Spacer()
                        Text(formatDepth(notam.contaminationDepth))
                    }
                    
                    HStack {
                        Text(formatDepth(0)).foregroundColor(.secondary)
                        Slider(value: depthBinding, in: 0.0...0.5, step: 0.1)
                            .accessibilityIdentifier("contaminationDepthSlider")
                        Text(formatDepth(0.5)).foregroundColor(.secondary)
                    }
                }
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

#Preview {
    let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    let notam = NOTAM(entity: model.entitiesByName["NOTAM"]!, insertInto: nil)
    
    return List {
        ContaminationView(notam: notam)
    }
}
