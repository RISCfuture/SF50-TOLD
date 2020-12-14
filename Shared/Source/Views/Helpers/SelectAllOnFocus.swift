import SwiftUI
import Introspect

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
        #if canImport(UIKit)
        return content.introspectTextField { textField in
            textField.addTarget(self.delegate, action: #selector(Delegate.textFieldDidBeginEditing), for: .editingDidBegin)
        }
        #else
        return content
        #endif
    }
}

extension View {
    func selectAllOnFocus() -> some View {
        modifier(SelectAllOnFocus())
    }
}
