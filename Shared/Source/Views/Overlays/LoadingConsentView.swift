import SwiftUI
import Defaults

struct LoadingConsentView: View {
    @EnvironmentObject var state: AppState
    
    var titleString: String {
        if Defaults[.lastCycleLoaded] == nil {
            return "You need to download airport data before you can use this app."
        } else {
            return "Your airport database is out of date. Would you like to update it?"
        }
    }
    
    var body: some View {
        VStack(alignment: .center, spacing: 20) {
            Image("Logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: 200, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
            
            Text(titleString)
                .multilineTextAlignment(.center)
            
            Text("This process can take around 30 minutes to complete. It must be done the first time the app launches, and approximately once a month as new navigation data is released. I recommend you keep \(localizedModel()) plugged into a power source.")
                .font(.footnote)
                .padding(.horizontal, 20)
                .multilineTextAlignment(.leading)
            
            if state.networkIsExpensive {
                Text("Warning: You are on a slow or metered network.")
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                    
            }
            
            HStack(spacing: 20) {
                Button("Download Airport Data") {
                    self.state.airportLoadingService.loadNASR()
                }
                if state.canSkipLoad {
                    Button("Skip For Now") {
                        self.state.airportLoadingService.skipLoadThisSession = true
                    }
                }
            }
        }.padding()
    }
}

struct LoadingConsentView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingConsentView().preferredColorScheme(.dark).environmentObject(AppState())
    }
}
