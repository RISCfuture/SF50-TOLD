import SwiftUI

struct TakeoffGroundRollView: View {
    @ObservedObject var state: PerformanceState

    private var takeoffRun: Double? {
        guard let run = state.runway?.notamedTakeoffRun else { return nil }
        return Double(run)
    }

    var body: some View {
        HStack {
            Text("Ground Roll")
            Spacer()
            InterpolationView(interpolation: state.takeoffRoll,
                              suffix: "ft",
                              maximum: takeoffRun)
        }
    }
}

#Preview {
    List {
        TakeoffGroundRollView(state: .init(operation: .takeoff))
    }
}
