import Foundation
import Dispatch

class LRUCache<T> where T: Identifiable {
    let size: UInt
    
    private var stack = Array<T.ID>()
    private var dictionary = Dictionary<T.ID, T>()
    private let mutex = DispatchSemaphore(value: 1)
    
    init(size: UInt) {
        self.size = size
    }
    
    func add(_ element: T) {
        mutex.wait()
        
        touch(element.id)
        if stack.count == size {
            if let deletedID = stack.popLast() {
                dictionary.removeValue(forKey: deletedID)
            }
        }
        stack.insert(element.id, at: 0)
        dictionary[element.id] = element
        mutex.signal()
    }
    
    subscript(_ id: T.ID) -> T? {
        mutex.wait()
        let element = dictionary[id]
        touch(id)
        
        mutex.signal()
        return element
    }
    
    func contains(_ id: T.ID) -> Bool {
        mutex.wait()
        let doesContain = dictionary.keys.contains(id)
        mutex.signal()
        return doesContain
    }
    
    private func touch(_ id: T.ID) {
        guard dictionary.keys.contains(id) else { return }
        stack.removeAll { $0 == id }
        stack.insert(id, at: 0)
    }
}
