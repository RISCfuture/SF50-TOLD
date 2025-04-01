import SwiftUI

struct VREFView: View {
    @ObservedObject var state: PerformanceState

    var body: some View {
        HStack {
            Text("V")
            + Text("REF")
                .font(.system(size: 8.0))
                .baselineOffset(-3.0)
            Spacer()
            InterpolationView(interpolation: state.vref, suffix: "kts")
        }
    }
}

#Preview {
    List {
        VREFView(state: .init(operation: .landing))
    }
}
