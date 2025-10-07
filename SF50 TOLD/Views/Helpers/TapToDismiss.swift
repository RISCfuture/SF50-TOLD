import Foundation
import SwiftUI

#if canImport(UIKit)
  private class TapDelegate: NSObject, UIGestureRecognizerDelegate {
    func gestureRecognizer(
      _: UIGestureRecognizer,
      shouldRecognizeSimultaneouslyWith _: UIGestureRecognizer
    ) -> Bool {
      false
    }
  }
#endif

struct TapToDismissKeyboard: ViewModifier {
  #if canImport(UIKit)
    private var tapDelegate = TapDelegate()
  #endif

  func body(content: Content) -> some View {
    #if canImport(UIKit)
      return content.onAppear {
        for scene in UIApplication.shared.connectedScenes {
          guard let scene = scene as? UIWindowScene else { continue }
          guard let window = scene.windows.first else { return }
          let tapGesture = UITapGestureRecognizer(
            target: window,
            action: #selector(UIView.endEditing)
          )
          tapGesture.requiresExclusiveTouchType = false
          tapGesture.cancelsTouchesInView = false
          tapGesture.delegate = tapDelegate
          window.addGestureRecognizer(tapGesture)
        }
      }
    #else
      return content
    #endif
  }
}

extension View {
  func tapToDismissKeyboard() -> some View {
    modifier(TapToDismissKeyboard())
  }
}
