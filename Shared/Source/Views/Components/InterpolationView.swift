import SwiftUI

struct InterpolationView: View {
    var interpolation: Interpolation?
    var suffix: String?
    var minimum: Double?
    var maximum: Double?

    var body: some View {
        if let interpolation {
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
                        if let suffix {
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
        if let minimum {
            if number < minimum { return .red }
        }
        if let maximum {
            if number > maximum { return .red }
        }
        return .primary
    }
}

#Preview {
    return InterpolationView(interpolation: .value(5), suffix: "ft")
}
