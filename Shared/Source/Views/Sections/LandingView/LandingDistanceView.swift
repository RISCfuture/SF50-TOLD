import SwiftUI

struct LandingDistanceView: View {
    @ObservedObject var state: PerformanceState

    private var landingDistance: Double? {
        guard let run = state.runway?.notamedLandingDistance else { return nil }
        return Double(run)
    }

    var body: some View {
        HStack {
            Text("Total Distance")
            Spacer()
            InterpolationView(interpolation: state.landingDistance,
                              suffix: "ft",
                              maximum: landingDistance)
        }
    }
}

#Preview {
    List {
        LandingDistanceView(state: PerformanceState(operation: .landing))
    }
}
