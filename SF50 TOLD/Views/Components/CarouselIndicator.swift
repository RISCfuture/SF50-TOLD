import SwiftUI

/// Page indicator with a dock-style zooming effect centered on the current item.
///
/// `CarouselIndicator` displays page dots for carousel navigation. When there are many pages,
/// only a window of dots is shown around the current index, with edge dots shrinking to indicate
/// more content. Supports scrubbing: drag horizontally to quickly navigate between pages.
///
/// Example usage:
/// ```swift
/// CarouselIndicator(
///   currentIndex: $currentIndex,
///   totalPages: 10
/// )
/// ```
struct CarouselIndicator: View {
  @Binding var currentIndex: Int
  let totalPages: Int

  /// Maximum number of dots to display at once
  private let maxVisibleDots = 7

  @State private var indicatorWidth: CGFloat = 0

  /// The range of indices to display as dots
  private var visibleRange: ClosedRange<Int> {
    guard totalPages > maxVisibleDots else {
      return 0...(totalPages - 1)
    }

    // Calculate window centered on current index
    let halfWindow = maxVisibleDots / 2
    var start = currentIndex - halfWindow
    var end = currentIndex + halfWindow

    // Clamp to valid range
    if start < 0 {
      start = 0
      end = maxVisibleDots - 1
    } else if end >= totalPages {
      end = totalPages - 1
      start = totalPages - maxVisibleDots
    }

    return start...end
  }

  var body: some View {
    HStack(spacing: 4) {
      ForEach(Array(visibleRange), id: \.self) { index in
        pageDot(index: index)
      }
    }
    .background(
      GeometryReader { geometry in
        Color.clear.onAppear {
          indicatorWidth = geometry.size.width
        }
        .onChange(of: geometry.size.width) { _, newWidth in
          indicatorWidth = newWidth
        }
      }
    )
    .gesture(
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          guard indicatorWidth > 0 else { return }

          // Calculate the index based on drag position across ALL pages, not just visible ones
          let fraction = max(0, min(1, value.location.x / indicatorWidth))
          let newIndex = Int(round(fraction * Double(totalPages - 1)))

          if newIndex != currentIndex && newIndex >= 0 && newIndex < totalPages {
            currentIndex = newIndex
          }
        }
    )
    .animation(.smooth(duration: 0.25), value: currentIndex)
  }

  private func pageDot(index: Int) -> some View {
    let isCurrent = index == currentIndex
    let distance = abs(index - currentIndex)
    let scale = scaleFactor(for: index, distance: distance)
    let size = 8.0 * scale

    return Circle()
      .fill(isCurrent ? Color.accentColor : Color.secondary.opacity(0.3))
      .frame(width: size, height: size)
  }

  /// Calculate scale factor based on distance from current index and position in visible range
  private func scaleFactor(for index: Int, distance: Int) -> Double {
    let range = visibleRange

    // If we're showing all dots (few pages), use distance-based scaling
    guard totalPages > maxVisibleDots else {
      return distanceScale(for: distance)
    }

    // Edge dots shrink to indicate more content beyond
    let isAtStart = index == range.lowerBound && range.lowerBound > 0
    let isAtEnd = index == range.upperBound && range.upperBound < totalPages - 1

    if isAtStart || isAtEnd {
      return 0.375  // Small dot to indicate more pages
    }

    // Second-from-edge dots are medium sized when near boundaries
    let isNearStart = index == range.lowerBound + 1 && range.lowerBound > 0
    let isNearEnd = index == range.upperBound - 1 && range.upperBound < totalPages - 1

    if isNearStart || isNearEnd {
      return min(0.625, distanceScale(for: distance))
    }

    return distanceScale(for: distance)
  }

  /// Base scale factor based on distance from current index
  private func distanceScale(for distance: Int) -> Double {
    switch distance {
      case 0: return 1.0  // Current dot: 100%
      case 1: return 0.75  // Adjacent dots: 75%
      case 2: return 0.625  // Two away: 62.5%
      default: return 0.5  // Far away: 50%
    }
  }
}

#Preview("Few Pages") {
  @Previewable @State var currentIndex = 2

  VStack(spacing: 20) {
    Text("Page \(currentIndex + 1) of 5")
      .font(.caption)
    Text("Drag horizontally to scrub")
      .font(.caption2)
      .foregroundStyle(.secondary)
    CarouselIndicator(currentIndex: $currentIndex, totalPages: 5)
  }
  .padding()
}

#Preview("Many Pages") {
  @Previewable @State var currentIndex = 7

  VStack(spacing: 20) {
    Text("Page \(currentIndex + 1) of 20")
      .font(.caption)
    Text("Drag horizontally to scrub")
      .font(.caption2)
      .foregroundStyle(.secondary)
    CarouselIndicator(currentIndex: $currentIndex, totalPages: 20)
  }
  .padding()
}
