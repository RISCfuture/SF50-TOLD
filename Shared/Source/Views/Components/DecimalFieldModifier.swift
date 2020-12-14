import Foundation
import SwiftUI

struct DecimalFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        #if canImport(UIKit)
        return content
            .keyboardType(.decimalPad)
            .selectAllOnFocus()
            .multilineTextAlignment(.trailing)
        #else
        return content
            .selectAllOnFocus()
            .multilineTextAlignment(.trailing)
        #endif
    }
}

extension View {
    func decimalField() -> some View {
        modifier(DecimalFieldModifier())
    }
}
