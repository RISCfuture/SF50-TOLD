import SwiftUI

/// Apple Intelligence gradient colors and styling.
extension LinearGradient {
  /// The Apple Intelligence gradient used for borders and icons.
  static var appleIntelligence: LinearGradient {
    LinearGradient(
      stops: [
        Gradient.Stop(color: Color(hex: 0xBC82F3), location: 0.0),
        Gradient.Stop(color: Color(hex: 0xF5B9EA), location: 0.15),
        Gradient.Stop(color: Color(hex: 0x8D9FFF), location: 0.3),
        Gradient.Stop(color: Color(hex: 0xAA6EEE), location: 0.45),
        Gradient.Stop(color: Color(hex: 0xFF6778), location: 0.6),
        Gradient.Stop(color: Color(hex: 0xFFBA71), location: 0.8),
        Gradient.Stop(color: Color(hex: 0xC686FF), location: 1.0)
      ],
      startPoint: .topLeading,
      endPoint: .bottomTrailing
    )
  }
}

/// View modifier that applies Apple Intelligence-style gradient border and glow effects.
struct AppleIntelligenceStyle: ViewModifier {
  private var gradient: LinearGradient {
    .appleIntelligence
  }

  private var shadowColor: Color {
    Color(hex: 0xAA6EEE).opacity(0.25)
  }

  func body(content: Content) -> some View {
    content
      .background(Color(.systemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 12))
      // Outer soft glow (furthest out, most diffuse)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(gradient.opacity(0.15), lineWidth: 12)
          .blur(radius: 6)
      )
      // Middle glow layer
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(gradient.opacity(0.3), lineWidth: 6)
          .blur(radius: 3)
      )
      // Inner soft border (most visible, slightly blurred)
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .strokeBorder(gradient.opacity(0.7), lineWidth: 1.5)
          .blur(radius: 0.5)
      )
      .shadow(color: shadowColor, radius: 8, x: 0, y: 2)
  }
}

extension View {
  /// Applies Apple Intelligence-style gradient border and glow effects.
  func appleIntelligenceStyle() -> some View {
    modifier(AppleIntelligenceStyle())
  }

  /// Conditionally applies a view modifier.
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}
