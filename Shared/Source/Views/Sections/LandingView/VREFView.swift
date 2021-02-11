import SwiftUI

struct VREFView: View {
    var body: some View {
        HStack {
            Text("V")
            + Text("REF")
                .font(.system(size: 8.0))
                .baselineOffset(-3.0)
            Spacer()
            Text("77 kts")
        }
    }
}

struct VREFView_Previews: PreviewProvider {
    static var previews: some View {
        List {
            VREFView()
        }
    }
}
