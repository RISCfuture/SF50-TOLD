import SwiftUI

struct SearchField: View {
    var placeholder = "Search"
    @Binding var text: String
    @State private var isEditing = false

#if canImport(UIKit)
    var backgroundColor = Color(.secondarySystemFill)
#endif

    // swiftlint:disable accessibility_trait_for_button
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .disableAutocorrection(true)
                .padding(7)
                .padding(.horizontal, 25)
#if canImport(UIKit)
                .background(backgroundColor)
                .cornerRadius(100)
#endif
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                            .accessibilityHidden(true)

                        if isEditing {
                            Button(action: { text = "" }, label: {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                                    .accessibilityLabel("Clear input")
                            })
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    isEditing = true
                }
                .accessibilityAddTraits(.isSearchField)
        }
    }
    // swiftlint:enable accessibility_trait_for_button
}

#Preview {
    // @Previewable @State var value = ""
    SearchField(text: .constant(""))
}
