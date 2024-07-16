import SwiftUI

struct SearchField: View {
    var placeholder = "Search"
    @Binding var text: String
    @State private var isEditing = false
    
#if canImport(UIKit)
    var backgroundColor = Color(.secondarySystemFill)
#endif
    
    var body: some View {
        HStack {
            TextField(placeholder, text: $text)
                .disableAutocorrection(true)
                .padding(7)
                .padding(.horizontal, 25)
#if canImport(UIKit)
                .background(backgroundColor)
#endif
                .cornerRadius(100)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if isEditing {
                            Button(action: {
                                self.text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
                .padding(.horizontal, 10)
                .onTapGesture {
                    self.isEditing = true
                }
                .accessibilityAddTraits(.isSearchField)
        }
    }
}

struct SearchField_Previews: PreviewProvider {
    static var previews: some View {
        SearchField(text: .constant(""))
    }
}
