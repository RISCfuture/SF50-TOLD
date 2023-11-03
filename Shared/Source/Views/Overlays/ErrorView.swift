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
                Text("Couldn’t load airports because an error occurred.")
                    .font(.headline)
            }
            Text(error.localizedDescription)
                .font(.subheadline)
        }.padding()
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(error: DataDownloadError.cycleNotAvailable)
    }
}

fileprivate enum BogusError: Swift.Error, LocalizedError {
    case bogus
    
    var errorDescription: String? {
        return NSLocalizedString("Bogus error", comment: "bogus error")
    }
}
