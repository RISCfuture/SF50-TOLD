import SwiftUI

struct LandingGroundRollView: View {
    @ObservedObject var state: PerformanceState
    
    private var landingDistance: Double? {
        guard let run = state.runway?.notamedLandingDistance else { return nil }
        return Double(run)
    }
    
    var body: some View {
        HStack {
            Text("Ground Roll")
            Spacer()
            InterpolationView(interpolation: state.landingRoll,
                              suffix: "ft.",
                              maximum: landingDistance)
        }
    }
}

struct LandingGroundRollView_Previews: PreviewProvider {
    static var previews: some View {
        LandingGroundRollView(state: PerformanceState(operation: .landing))
    }
}
