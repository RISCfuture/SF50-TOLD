import SwiftUI
import CoreData

struct GoAroundClimbGradientView: View {
    @ObservedObject var state: PerformanceState
    
    var body: some View {
        
        HStack {
            Text("Meets Go-Around Climb Gradient")
            Spacer()
            if let meets = state.meetsGoAroundClimbGradient {
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
        List {
            GoAroundClimbGradientView(state: .init(operation: .landing))
        }
    }
}
