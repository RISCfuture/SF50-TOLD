import SwiftUI

struct RawWeather: View {
    var rawText: String
    var error: Swift.Error?
    
    var body: some View {
        VStack(alignment: .leading) {
            ScrollView(.horizontal) {
                Text(rawText)
                    .font(.system(size: 14, weight: .regular, design: .monospaced))
                    .multilineTextAlignment(.leading)
            }
            if let error = error {
                Text(error.localizedDescription).foregroundColor(.red)
                    .font(.system(size: 14))
                    .multilineTextAlignment(.leading)
            }
        }
    }
}

#Preview {
    let taf = "KSFO 172057Z 1721/1824 VRB04KT P6SM SKC WS020/02025KT FM172200 31008KT P6SM SKC FM180100 28013KT P6SM FEW200 FM180800 28006KT P6SM FEW200 FM181000 VRB05KT P6SM SKC WS020/02030KT FM181500 36008KT P6SM SKC WS015/03030KT FM182000 36012KT P6SM SKC WS015/03035KT"
    
    return Form {
        RawWeather(rawText: taf,
                   error: nil)
    }
}

