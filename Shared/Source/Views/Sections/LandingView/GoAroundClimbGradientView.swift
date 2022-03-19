import SwiftUI

struct GoAroundClimbGradientView: View {
    @ObservedObject var state: PerformanceState
    
    var body: some View {
        if let meets = state.meetsGoAroundClimbGradient {
            HStack {
                Text("Meets Go-Around Climb Gradient")
                Spacer()
                if meets {
                    Text("Yes").bold()
                } else {
                    Text("No").bold().foregroundColor(.red)
                }
            }
        }
    }
}

struct GoAroundClimbGradientView_Previews: PreviewProvider {
    static var previews: some View {
        GoAroundClimbGradientView(state: .init(operation: .landing))
    }
}
