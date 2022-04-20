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
        List {
            VREFView(state: .init(operation: .landing))
        }
    }
}
