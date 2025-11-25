import SwiftUI

extension Color {
  static let ui = Color.UI()

  struct UI {
    let warning = Color("WarningColor")
  }

  /// Creates a color from a hex value (e.g., 0xFF5733)
  init(hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xff) / 255,
      green: Double((hex >> 08) & 0xff) / 255,
      blue: Double((hex >> 00) & 0xff) / 255,
      opacity: alpha
    )
  }
}
