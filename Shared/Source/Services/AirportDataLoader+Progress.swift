import Foundation

class Progress {
    let progress: Foundation.Progress
    var queue = DispatchQueue.main
    
    private var children = Dictionary<String, Foundation.Progress>()
    
    init(totalUnitCount: Int64) {
        progress = Foundation.Progress(totalUnitCount: totalUnitCount)
        progress.localizedDescription = ""
        progress.localizedAdditionalDescription = ""
    }
    
    func addChild(_ child: Foundation.Progress, identifier: String, pendingUnitCount: Int64) {
        queue.async {
            if self.children.keys.contains(identifier) { return }
            self.children[identifier] = child
            self.progress.addChild(child, withPendingUnitCount: pendingUnitCount)
        }
    }
    
    func addChild(identifier: String, totalUnitCount: Int64, pendingUnitCount: Int64) {
        addChild(Foundation.Progress(totalUnitCount: totalUnitCount), identifier: identifier, pendingUnitCount: pendingUnitCount)
    }
    
    func increment(_ identifier: String) {
        queue.async {
            guard let progress = self.children[identifier] else { return }
            progress.completedUnitCount += 1
        }
    }
}
