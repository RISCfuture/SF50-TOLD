import SwiftUI

struct OffscaleWarningView: View {
  let offscaleLow: Bool
  let offscaleHigh: Bool

  var body: some View {
    if offscaleHigh {
      Label(
        "The input values are above the maximums specified in the AFM table. Proceed with extreme caution.",
        systemImage: "exclamationmark.triangle"
      )
      .font(.system(size: 14))
      .foregroundColor(.red)
    } else if offscaleLow {
      Label(
        "The input values are below the minimums specified in the AFM table.",
        systemImage: "info.circle"
      )
      .font(.system(size: 14))
      .foregroundColor(.secondary)
    }
  }

  init(offscaleLow: Bool = false, offscaleHigh: Bool = false) {
    self.offscaleLow = offscaleLow
    self.offscaleHigh = offscaleHigh
  }
}

#Preview("Low") {
  List {
    OffscaleWarningView(offscaleLow: true)
  }
}

#Preview("High") {
  List {
    OffscaleWarningView(offscaleHigh: true)
  }
}
