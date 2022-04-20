import SwiftUI

struct VxClimbView: View {
    @ObservedObject var state: PerformanceState
    
    private var vxText: Text {
        Text("V")
        + Text("X")
            .font(.system(size: 8.0))
            .baselineOffset(-3.0)
    }
    
    private var requiredClimbGradientIfNotMet: Double? {
        guard let climbGradientInterp = state.climbGradient else {
            return nil
        }
        guard case let .value(climbGradient, _) = climbGradientInterp else {
            return nil
        }
        
        return state.requiredClimbGradient > climbGradient ? state.requiredClimbGradient : nil
    }
    
    var body: some View {
        VStack {
            HStack {
                vxText + Text(" Climb Gradient")
                Spacer()
                InterpolationView(interpolation: state.climbGradient,
                                  suffix: "ft/NM",
                                  minimum: state.requiredClimbGradient)
            }
        }
        
        if let requiredClimbGradient = requiredClimbGradientIfNotMet {
            HStack {
                Label("A climb gradient of \(integerFormatter.string(for: requiredClimbGradient)) ft/NM is required.",
                      systemImage: "exclamationmark.triangle")
                .font(.system(size: 14))
                .foregroundColor(.red)
            }
        }
        
        HStack {
            vxText + Text(" Climb Rate")
            Spacer()
            InterpolationView(interpolation: state.climbRate,
                              suffix: "ft/min",
                              minimum: 0)
        }
    }
}

struct VxClimbView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            VxClimbView(state: .init(operation: .takeoff))
        }
    }
}
