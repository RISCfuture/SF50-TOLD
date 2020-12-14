import SwiftUI

struct InterpolationView: View {
    var interpolation: Interpolation?
    var suffix: String? = nil
    var maximum: Double? = nil
    
    var body: some View {
        if let interpolation = interpolation {
            HStack(spacing: 0) {
                switch interpolation {
                    case .offscaleLow:
                        Text("Off-scale Low")
                            .foregroundColor(.gray)
                            .bold()
                    case .offscaleHigh:
                        Text("Off-scale High")
                            .foregroundColor(.red)
                            .bold()
                    case .configNotAuthorized:
                        Text("Configuration not authorized")
                            .foregroundColor(.red)
                            .bold()
                    case .value(let number):
                        Text(NSNumber(value: number), formatter: integerFormatter.forView)
                            .bold()
                            .foregroundColor(maximum != nil && number > maximum! ? .red : .primary)
                            .multilineTextAlignment(.trailing)
                        if let suffix = suffix {
                            Text(" \(suffix)")
                                .foregroundColor(maximum != nil && number > maximum! ? .red : .primary)
                        }
                }
            }
        } else {
            Spacer()
        }
    }
}

struct InterpolationView_Previews: PreviewProvider {
    static var previews: some View {
        InterpolationView(interpolation: .value(5), suffix: "ft.")
    }
}
