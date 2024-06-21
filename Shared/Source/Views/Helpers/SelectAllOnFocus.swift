import SwiftUI

#if canImport(UIKit)
fileprivate class Delegate: NSObject, UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        textField.selectAll(nil)
    }
}
#endif

struct SelectAllOnFocus: ViewModifier {
    #if canImport(UIKit)
    fileprivate var delegate = Delegate()
    #endif
    
    func body(content: Content) -> some View {
        return content.onReceive(NotificationCenter.default.publisher(for: UITextField.textDidBeginEditingNotification)) { obj in
            guard let textField = obj.object as? UITextField else { return }
            textField.selectAll(nil)
        }
    }
}

extension View {
    func selectAllOnFocus() -> some View {
        modifier(SelectAllOnFocus())
    }
}
