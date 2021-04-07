import Foundation
import Combine
import CoreData

class ManagedObjectPublisher<T> where T: NSManagedObject, T: Identifiable {
    private let subject: CurrentValueSubject<T, Never>
    
    var publisher: AnyPublisher<T, Never> { subject.eraseToAnyPublisher() }
    
    init(value: T) {
        self.subject = .init(value)
        NotificationCenter.default.addObserver(self, selector: #selector(changed), name: .NSManagedObjectContextDidSave, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc private func changed(_ notification: Notification) {
        guard let objects = notification.userInfo![NSUpdatedObjectsKey] as? Set<T> else {
            return
        }
        
        for value in objects {
            if value.id == subject.value.id {
                subject.send(value)
            }
        }
    }
}
