import SwiftUI

struct LandingResultsView: View {
    @ObservedObject var state: PerformanceState
    
    var body: some View {
        Section(header: Text("Performance")) {
            VREFView()
            LandingGroundRollView(state: state)
            LandingDistanceView(state: state)
        }
        
        if state.offscale != .none {
            OffscaleWarningView(offscale: state.offscale)
        }
    }
}

struct LandingResultsView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            LandingResultsView(state: .init(operation: .landing))
        }
    }
}
