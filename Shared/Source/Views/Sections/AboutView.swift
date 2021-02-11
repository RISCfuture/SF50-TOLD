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
                        Text("Cirrus SR22 (G2)")
                            .bold()
                    }
                    
                    HStack {
                        Text("App Version")
                        Spacer()
                        Text("\(releaseVersionNumber) (\(buildVersionNumber))")
                            .bold()
                    }
                }
                
                Section(header: Text("SR22 G2/G3 Data Source")) {
                    HStack {
                        Text("Serials")
                        Spacer()
                        Text("0002 thru 2978, 2980 thru 2991, 2993 thru 3001, 3003 thru 3025, 3027 and subs with Analog or Avidyne Avionics System")
                            .bold()
                            .font(.system(size: 14))
                    }
                    
                    HStack {
                        Text("P/N")
                        Spacer()
                        Text("13772-001")
                            .bold()
                    }
                    
                    HStack {
                        Text("Revision")
                        Spacer()
                        Text("A1 (04 Feb 2022)")
                            .bold()
                    }
                }
                
                Section(header: Text("Tornado Alley Turbo Data Source")) {
                    HStack {
                        Text("Supplemental Type Certificates")
                        Spacer()
                        Text("SA10588SC, SE10589SC")
                            .bold()
                            .font(.system(size: 14))
                    }
                    
                    HStack {
                        Text("Report")
                        Spacer()
                        Text("215-6")
                            .bold()
                    }
                    
                    HStack {
                        Text("Revision")
                        Spacer()
                        Text("3")
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
