import SwiftUI

struct TakeoffResultsView: View {
    @ObservedObject var state: PerformanceState

    var body: some View {
        Section(header: Text("Performance")) {
            TakeoffGroundRollView(state: state)
            TakeoffDistanceView(state: state)
            VxClimbView(state: state)

            if state.offscale != .none {
                OffscaleWarningView(offscale: state.offscale)
            }
        }
    }
}

#Preview {
    List {
        TakeoffResultsView(state: PerformanceState(operation: .takeoff))
    }
}
