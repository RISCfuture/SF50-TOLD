import SwiftUI

struct ContaminationWarningView: View {
  var body: some View {
    Label(
      "Contaminated runway performance data is considered supplemental and is not FAA approved. Data is primarily for runways where greater than 0.1 inch (3.0 mm) of contaminant is observed (FICON 4 or worse). Pilots/operators should recognize that these values are considered minimums and actual distances may be greater when landing in these conditions.",
      systemImage: "info.circle"
    )
    .font(.system(size: 14))
    .foregroundColor(.secondary)
  }
}

#Preview {
  List {
    ContaminationWarningView()
  }
}
