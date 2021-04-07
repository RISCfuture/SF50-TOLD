import Foundation
import Combine
import CoreData
import Defaults

class AirportState: ObservableObject {
    static let recentsSize = 10
    
    @Published var airport: Airport
    @Published var error: Error? = nil
    
    private var publisher: ManagedObjectPublisher<Airport>
    private var context: NSManagedObjectContext? { AppState.instance?.viewContext }
    private var cancellables = Set<AnyCancellable>()
    
    init(airport: Airport) {
        self.airport = airport
        self.publisher = .init(value: airport)
        
        publisher.publisher.assign(to: &$airport)
        $airport.sink { [weak self] airport in self?.publisher = .init(value: airport) }.store(in: &cancellables)
    }
    
    deinit {
        for c in cancellables { c.cancel() }
    }
    
    func toggleFavorite() {
        airport.favorite = !airport.favorite
        save()
    }
    
    private func save() {
        guard let context = context else { return }
        guard context.hasChanges else { return }
        
        do {
            try context.save()
        } catch (let error as NSError) {
            if error.code == 0 { return }
            self.error = error
        } catch (let error) {
            self.error = error
        }
    }
}
