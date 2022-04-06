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
                        Text("Cirrus SF50 Vision (G1 through G2+)")
                            .bold()
                    }
                    
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("\(releaseVersionNumber) (\(buildVersionNumber))")
                            .bold()
                    }
                }
                
                Section(header: Text("SF50 G1 Data Source")) {
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
                
                Section(header: Text("SF50 G2 Data Source")) {
                    HStack {
                        Text("Serials")
                        Spacer()
                        Text("Aircraft Serials with Cirrus Perspective Touch+ Avionics System and FL310 Maximum Operating Altitude")
                            .bold()
                            .font(.system(size: 14))
                    }
                    
                    HStack {
                        Text("P/N")
                        Spacer()
                        Text("31452-002")
                            .bold()
                    }
                    
                    HStack {
                        Text("Reissue")
                        Spacer()
                        Text("Original")
                            .bold()
                    }
                }
                
                Section(header: Text("Updated Thrust Schedule Data Source")) {
                    HStack {
                        Text("Serials")
                        Spacer()
                        Text("26000-004 or Compliance with SB5X-72-01")
                            .bold()
                            .font(.system(size: 14))
                    }
                    
                    HStack {
                        Text("P/N")
                        Spacer()
                        Text("31452-111")
                            .bold()
                    }
                    
                    HStack {
                        Text("Revision")
                        Spacer()
                        Text("1 (10 Feb 2022)")
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
