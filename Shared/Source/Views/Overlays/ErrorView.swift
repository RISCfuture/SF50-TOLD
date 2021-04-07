import SwiftUI

struct ErrorView<Content: View>: View {
    let error: Error?
    let content: () -> Content

    init(error: Error?, @ViewBuilder content: @escaping () -> Content) {
        self.error = error
        self.content = content
    }


    var body: some View {
        if let error = error {
            VStack(alignment: .leading, spacing: 20) {
                HStack(alignment: .top) {
                    Image(systemName: "xmark.octagon")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 40)
                    Text("Uh oh, an error occurred.")
                        .font(.headline)
                }
                Text(error.localizedDescription)
                    .font(.subheadline)
            }.padding()
        } else { content() }
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(error: BogusError.bogus) { Text("hi") }
        ErrorView(error: nil) { Text("hi 2") }
    }
}

fileprivate enum BogusError: Swift.Error, LocalizedError {
    case bogus

    var errorDescription: String? {
        return NSLocalizedString("Bogus error", comment: "bogus error")
    }
}
