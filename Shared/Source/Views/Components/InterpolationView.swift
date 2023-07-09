import SwiftUI

struct InterpolationView: View {
    var interpolation: Interpolation?
    var suffix: String? = nil
    var minimum: Double? = nil
    var maximum: Double? = nil
    
    var body: some View {
        if let interpolation = interpolation {
            HStack(spacing: 0) {
                switch interpolation {
                    case .configNotAuthorized:
                        Text("Configuration not authorized")
                            .foregroundColor(.red)
                            .bold()
                    case let .value(number, _):
                        Text(NSNumber(value: number), formatter: integerFormatter.forView)
                            .bold()
                            .foregroundColor(color(for: number))
                            .multilineTextAlignment(.trailing)
                        if let suffix = suffix {
                            Text(" \(suffix)")
                                .foregroundColor(color(for: number))
                        }
                }
            }
        } else {
            Spacer()
        }
    }
    
    private func color(for number: Double) -> Color {
        if let min = minimum {
            if number < min { return .red }
        }
        if let max = maximum {
            if number > max { return .red }
        }
        return .primary
    }
}

struct InterpolationView_Previews: PreviewProvider {
    static var previews: some View {
        InterpolationView(interpolation: .value(5), suffix: "ft")
    }
}
