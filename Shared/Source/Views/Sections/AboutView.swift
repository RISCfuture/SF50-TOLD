import SwiftUI

struct AboutView: View {
    private var releaseVersionNumber: String {
        return Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
    }
    private var buildVersionNumber: String {
        return Bundle.main.infoDictionary!["CFBundleVersion"] as! String
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Application")) {
                    HStack {
                        Text("Aircraft")
                        Spacer()
                        Text("Cirrus SF50 Vision (G1)")
                            .bold()
                    }
                    
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("\(releaseVersionNumber) (\(buildVersionNumber))")
                            .bold()
                    }
                }
                
                Section(header: Text("Data Source")) {
                    HStack {
                        Text("Serials")
                        Spacer()
                        Text("Aircraft Serials with Cirrus Perspective Touch Avionics System and FL280 Maximum Operating Altitude")
                            .bold()
                            .font(.system(size: 14))
                    }
                    
                    HStack {
                        Text("P/N")
                        Spacer()
                        Text("31452-001")
                            .bold()
                    }
                    
                    HStack {
                        Text("Reissue")
                        Spacer()
                        Text("A")
                            .bold()
                    }
                }
                
                Label("This app has not been approved by the FAA or by Cirrus Aircraft as an official source of performance information. Always verify performance information with official sources when using this app.", systemImage: "exclamationmark.triangle")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }.navigationTitle("About")
        }.navigationViewStyle(navigationStyle)
    }
}

struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
    }
}
