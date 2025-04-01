import CoreData
import SwiftUI

private func _headwind(wind: Wind, runway: Runway) -> Int {
    let ɑ = Double(Int16(wind.direction) - runway.heading)
    let hw = cos(ɑ * Double.pi / 180) * Double(wind.speed)
    return Int(hw.rounded())
}

private func _crosswind(wind: Wind, runway: Runway) -> Int {
    let ɑ = Double(Int16(wind.direction) - runway.heading)
    let hw = sin(ɑ * Double.pi / 180) * Double(wind.speed)
    return Int(hw.rounded())
}

struct WindComponents: View {
    private static let formatter = NumberFormatter()

    var runway: Runway
    var wind: Wind!
    var crosswindLimit: UInt?
    var tailwindLimit: UInt?

    var headwind: Int { _headwind(wind: wind!, runway: runway) }
    var crosswind: Int { _crosswind(wind: wind!, runway: runway) }

    private var headwindNum: NSNumber { NSNumber(value: abs(headwind)) }
    private var crosswindNum: NSNumber { NSNumber(value: abs(crosswind)) }

    private var exceedsTailwindLimits: Bool {
        guard let tailwindLimit else { return false }
        return headwind < -Int(tailwindLimit)
    }

    private var exceedsCrosswindLimits: Bool {
        guard let crosswindLimit else { return false }
        return abs(crosswind) > crosswindLimit
    }

    var body: some View {
        HStack {
            if headwind > 0 {
                HStack(spacing: 0) {
                    Image(systemName: "arrowtriangle.down.fill")
                        .foregroundColor(.green)
                        .accessibilityLabel("headwind")
                    Text(headwindNum, formatter: Self.formatter)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityIdentifier("headwind")
                }
            } else if headwind < 0 {
                HStack(spacing: 0) {
                    Image(systemName: "arrowtriangle.up.fill")
                        .foregroundColor(.red)
                        .accessibilityLabel("tailwind")
                    Text(headwindNum, formatter: Self.formatter)
                        .foregroundColor(exceedsTailwindLimits ? .red : .primary)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityIdentifier("headwind")
                }
            }
            if crosswind > 0 {
                HStack(spacing: 0) {
                    Image(systemName: "arrowtriangle.left.fill")
                        .foregroundColor(.gray)
                        .accessibilityLabel("left crosswind")
                    Text(crosswindNum, formatter: Self.formatter)
                        .foregroundColor(exceedsCrosswindLimits ? .red : .primary)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityIdentifier("crosswind")
                }
            } else if crosswind < 0 {
                HStack(spacing: 0) {
                    Image(systemName: "arrowtriangle.right.fill")
                        .foregroundColor(.gray)
                        .accessibilityLabel("right crosswind")
                    Text(crosswindNum, formatter: Self.formatter)
                        .foregroundColor(exceedsCrosswindLimits ? .red : .primary)
                        .fixedSize(horizontal: true, vertical: false)
                        .accessibilityIdentifier("crosswind")
                }
            }
        }
    }
}

#Preview {
    let model = NSManagedObjectModel(contentsOf: Bundle.main.url(forResource: "Airports", withExtension: "momd")!)!
    let rwy30 = { () -> Runway in
        let r = Runway(entity: model.entitiesByName["Runway"]!, insertInto: nil)
        r.name = "30"
        r.takeoffRun = 2600
        r.takeoffDistance = 2800
        r.heading = 302
        return r
    }()

    return WindComponents(runway: rwy30, wind: Wind(direction: 280, speed: 15))
}
