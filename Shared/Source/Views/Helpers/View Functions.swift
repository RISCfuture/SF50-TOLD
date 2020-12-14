import SwiftUI

#if canImport(UIKit)
import UIKit

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func localizedModel() -> String {
        UIDevice.current.localizedModel
    }
}
#else
extension View {
    func hideKeyboard() {
        // noop
    }
    
    func localizedModel() -> String {
        "device"
    }
}
#endif
