import SwiftUI

struct TakeoffDistanceView: View {
    @ObservedObject var state: PerformanceState
    
    private var takeoffDistance: Double? {
        guard let distance = state.runway?.notamedTakeoffDistance else { return nil }
        return Double(distance)
    }
    
    var body: some View {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Distance")
                    Text("over a 50-foot obstacle")
                        .font(.system(size: 11))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                InterpolationView(interpolation: state.takeoffDistance,
                                  suffix: "ft.",
                                  maximum: takeoffDistance)
            }
    }
}

struct TakeoffDistanceView_Previews: PreviewProvider {
    static var previews: some View {
        TakeoffDistanceView(state: .init(operation: .takeoff))
    }
}
