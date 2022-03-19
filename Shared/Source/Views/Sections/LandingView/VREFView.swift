import SwiftUI

struct VREFView: View {
    @ObservedObject var state: PerformanceState
    
    var body: some View {
        HStack {
            Text("VREF")
            Spacer()
            InterpolationView(interpolation: state.vref, suffix: "kts.")
        }
    }
}

struct VREFView_Previews: PreviewProvider {
    static var previews: some View {
        VREFView(state: PerformanceState(operation: .landing))
    }
}
