import SwiftUI

struct LandingResultsView: View {
    @ObservedObject var state: PerformanceState
    
    var body: some View {
        Section(header: Text("Performance")) {
            VREFView(state: state)
            LandingGroundRollView(state: state)
            LandingDistanceView(state: state)
            GoAroundClimbGradientView(state: state)
        }
        
        if state.offscale != .none {
            OffscaleWarningView(offscale: state.offscale)
        }
    }
}

struct LandingResultsView_Previews: PreviewProvider {
    static var previews: some View {
        LandingResultsView(state: .init(operation: .landing))
    }
}
