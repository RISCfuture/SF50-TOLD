import SwiftUI
import CoreData
import Defaults

struct NOTAMView: View {
    var operation: Operation
    
    @ObservedObject var notam: NOTAM
    @Environment(\.presentationMode) var presentationMode
    
    @State var coreDataError: NSError? = nil
    private var hasCoreDataError: Binding<Bool> {
        .init(get: { self.coreDataError != nil }, set: {_ in })
    }
    private var coreDataErrorText: String {
        coreDataError?.localizedFailureReason
        ?? coreDataError?.localizedDescription
        ?? "An unknown error occurred."
    }
    
    var body: some View {
        Form {
            RunwayShorteningView(operation: operation, notam: notam)
            if operation == .takeoff { ObstacleView(notam: notam) }
            if operation == .landing { ContaminationView(notam: notam) }
            
            Button("Clear NOTAMs") {
                notam.clearFor(operation)
                presentationMode.wrappedValue.dismiss()
            }.accessibilityIdentifier("clearNOTAMsButton")
        }.navigationTitle("NOTAMs")
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
