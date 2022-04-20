import SwiftUI
import CoreData
import Defaults

struct NOTAMView: View {
    var operation: Operation
    
    @ObservedObject var notam: NOTAM
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    
    @State var coreDataError: NSError? = nil
    private var hasCoreDataError: Binding<Bool> {
        .init(get: { self.coreDataError != nil }, set: {_ in })
    }
    private var coreDataErrorText: String {
        coreDataError?.localizedFailureReason
        ?? coreDataError?.localizedDescription
        ?? "An unknown error occurred."
    }
    
    private let formatter = numberFormatter(precision: 0, minimum: 0)
    
    private var shortenPrompt: String {
        switch operation {
            case .takeoff: return "Shorten takeoff distance by:"
            case .landing: return "Shorten landing distance by:"
        }
    }
    
    private var shortenBinding: Binding<Double> {
        switch operation {
            case .takeoff: return $notam.takeoffDistanceShortening
            case .landing: return $notam.landingDistanceShortening
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Runway Shortening")) {
                    HStack {
                        Text(shortenPrompt)
                        Spacer()
                        DecimalField("Distance", value: shortenBinding, formatter: formatter, suffix: "ft.")
                    }
                }
                
                if operation == .takeoff {
                    Section(header: Text("Obstacle")) {
                        HStack {
                            Text("Obstacle Height")
                            Spacer()
                            DecimalField("Height", value: $notam.obstacleHeight, formatter: formatter, suffix: "ft.")
                        }
                        
                        HStack {
                            Text("Obstacle Distance")
                            Spacer()
                            DecimalField("Distance", value: $notam.obstacleDistance, formatter: formatter, suffix: "ft.")
                        }
                    }
                }
                
                Button("Clear NOTAMs") {
                    notam.clearFor(operation)
                    presentationMode.wrappedValue.dismiss()
                }
            }.navigationTitle("NOTAMs")
        }.navigationViewStyle(navigationStyle)
            .onDisappear {
                do {
                    try notam.managedObjectContext?.save()
                } catch (let error as NSError) {
                    coreDataError = error
                }
            }
            .alert("Couldn’t Save NOTAM", isPresented: hasCoreDataError, actions: {
                Button("OK") { coreDataError = nil }
            }, message: {
                Text(coreDataErrorText)
            })
    }
}

struct NOTAMView_Previews: PreviewProvider {
    static let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    
    private static let notam = { () -> NOTAM in
        let n = NOTAM(entity: model.entitiesByName["NOTAM"]!, insertInto: nil)
        n.takeoffDistanceShortening = 200
        n.landingDistanceShortening = 300
        n.obstacleHeight = 250
        n.obstacleDistance = 1500
        return n
    }()
    
    static var previews: some View {
        NOTAMView(operation: .takeoff, notam: notam)
    }
}
