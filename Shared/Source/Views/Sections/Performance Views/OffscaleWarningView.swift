import SwiftUI

struct OffscaleWarningView: View {
    var offscale: Offscale
    
    var body: some View {
        switch offscale {
            case .none: Spacer()
            case .low:
                Label("The input values are below the minimums specified in the AFM table.",
                      systemImage: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            case .high:
                Label("The input values are above the maximums specified in the AFM table. Proceed with extreme caution.",
                      systemImage: "exclamationmark.triangle")
                    .font(.system(size: 14))
                    .foregroundColor(.red)
        }
    }
}

struct OffscaleWarningView_Previews: PreviewProvider {
    static var previews: some View {
        OffscaleWarningView(offscale: .high)
    }
}
