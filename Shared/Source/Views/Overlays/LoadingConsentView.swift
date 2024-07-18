import SwiftUI
import Defaults

struct LoadingConsentView: View {
    @ObservedObject var service: AirportLoadingService
    
    var titleString: String {
        if service.canSkip {
            return "Your airport database is out of date. Would you like to update it?"
        } else {
            return "You need to download airport data before you can use this app."
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
            
            if service.networkIsExpensive {
                Text("Warning: You are on a slow or metered network.")
                    .foregroundColor(.red)
                    .font(.footnote)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                    
            }
            
            HStack(spacing: 20) {
                Button("Download Airport Data") {
                    self.service.loadNASR()
                }.accessibilityIdentifier("downloadDataButton")
                if service.canSkip {
                    Button("Defer Until Later") {
                        self.service.loadNASRLater()
                    }.accessibilityIdentifier("deferDataButton")
                }
            }
        }.padding()
    }
}

struct LoadingConsentView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingConsentView(service: AirportLoadingService())
    }
}
