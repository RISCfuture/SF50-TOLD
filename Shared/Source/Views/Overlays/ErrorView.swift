import SwiftUI

struct ErrorView: View {
    var error: DataDownloadError

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                Image(systemName: "xmark.octagon")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 40)
                    .accessibilityHidden(true)
                Text("Couldn’t load airports because an error occurred.")
                    .font(.headline)
            }
            Text(error.localizedDescription)
                .font(.subheadline)
        }.padding()
    }
}

#Preview {
    ErrorView(error: DataDownloadError.cycleNotAvailable)
}
