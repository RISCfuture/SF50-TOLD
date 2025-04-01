import Defaults
import Foundation
import SwiftNASR

public class CycleBridge: _DefaultsBridge {
    public typealias Value = Cycle
    public typealias Serializable = String

    public func serialize(_ value: Cycle?) -> String? {
        value.map { "\($0.year)-\($0.month)-\($0.day)" }
    }

    public func deserialize(_ object: String?) -> Cycle? {
        guard let object else { return nil }

        let parts = object.components(separatedBy: "-")
        guard let year = Int(parts[0]),
              let mon = Int(parts[1]),
              let day = Int(parts[2]) else { return nil }

        let dateComp = DateComponents(calendar: Calendar(identifier: .gregorian), year: year, month: mon, day: day)
        guard let date = dateComp.date else { return nil}

        return Cycle.effectiveCycle(for: date)
    }
}

extension Cycle: @retroactive _DefaultsSerializable {
    public typealias Bridge = CycleBridge

    public static var bridge: CycleBridge {
        CycleBridge()
    }
}
