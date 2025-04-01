import Foundation

extension Array where Element: Equatable {
    mutating func unique() {
        var i = 0
        while i < count {
            var j = i + 1
            while j < count {
                if self[i] == self[j] { remove(at: j) }
                j += 1
            }
            i += 1
        }
    }

    func uniqued() -> Self {
        var array = Array(self)
        array.unique()
        return array
    }
}
