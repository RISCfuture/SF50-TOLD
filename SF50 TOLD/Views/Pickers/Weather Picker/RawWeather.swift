import SF50_Shared
import SwiftUI

struct RawWeather: View {
  var rawText: Loadable<String?>

  var body: some View {
    switch rawText {
      case .loading:
        HStack {
          ProgressView()
          Text("Loading…").foregroundStyle(.secondary)
        }
      case .notLoaded, .value(nil):
        Group {}
      case .value(let rawText):
        ScrollView(.horizontal) {
          Text(rawText!)
            .font(.system(size: 14, weight: .regular, design: .monospaced))
            .multilineTextAlignment(.leading)
        }
      case .error(let error):
        Text(error.localizedDescription).foregroundStyle(.red)
          .font(.system(size: 14))
          .multilineTextAlignment(.leading)
    }
  }
}

#Preview("Loading") {
  Form {
    RawWeather(rawText: .loading)
  }
}

#Preview("Weather") {
  let taf =
    "KSFO 172057Z 1721/1824 VRB04KT P6SM SKC WS020/02025KT\n  FM172200 31008KT P6SM SKC\n  FM180100 28013KT P6SM FEW200\n  FM180800 28006KT P6SM FEW200\n  FM181000 VRB05KT P6SM SKC WS020/02030KT\n  FM181500 36008KT P6SM SKC WS015/03030KT\n  FM182000 36012KT P6SM SKC WS015/03035KT"

  Form {
    RawWeather(rawText: .value(taf))
  }
}

#Preview("Error") {
  let error = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "foo"))

  Form {
    RawWeather(rawText: .error(error))
  }
}
