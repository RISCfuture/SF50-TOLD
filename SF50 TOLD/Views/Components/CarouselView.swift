import SwiftUI

/// A generic horizontal carousel view with snap-to-page behavior.
///
/// `CarouselView` provides a reusable horizontal scrolling carousel that snaps to pages.
/// It tracks the current page index and supports any data type through generics.
///
/// Example usage:
/// ```swift
/// @State private var currentIndex = 0
///
/// CarouselView(
///   data: items,
///   id: \.id,
///   currentIndex: $currentIndex
/// ) { item in
///   ItemView(item: item)
/// }
/// .frame(height: 300)
/// ```
struct CarouselView<Data, ID, Content>: View
where Data: RandomAccessCollection, ID: Hashable, Content: View {
  let data: Data
  let id: KeyPath<Data.Element, ID>
  @ViewBuilder let content: (Data.Element) -> Content

  @Binding var currentIndex: Int
  @State private var scrollPositionId: ID?

  var body: some View {
    let idKeyPath = id
    let dataCollection = data

    ScrollView(.horizontal) {
      LazyHStack(alignment: .top, spacing: 0) {
        ForEach(Array(dataCollection.enumerated()), id: \.offset) { _, item in
          content(item)
            .containerRelativeFrame(.horizontal)
            .id(item[keyPath: idKeyPath])
        }
      }
      .scrollTargetLayout()
    }
    .scrollTargetBehavior(.paging)
    .scrollPosition(id: $scrollPositionId, anchor: .center)
    .scrollIndicators(.hidden)
    .onChange(of: scrollPositionId) { _, newId in
      if let newId,
        let index = dataCollection.firstIndex(where: { $0[keyPath: idKeyPath] == newId })
      {
        currentIndex = dataCollection.distance(from: dataCollection.startIndex, to: index)
      }
    }
    .onChange(of: currentIndex) { _, newIndex in
      // When currentIndex changes externally (e.g., from scrubbing), update scroll position
      let count = dataCollection.distance(
        from: dataCollection.startIndex,
        to: dataCollection.endIndex
      )
      guard newIndex >= 0 && newIndex < count else { return }
      let targetIndex = dataCollection.index(dataCollection.startIndex, offsetBy: newIndex)
      let targetItem = dataCollection[targetIndex]
      let targetId = targetItem[keyPath: idKeyPath]

      if scrollPositionId != targetId {
        // Smooth scroll animation with slight springback
        withAnimation(.smooth(duration: 0.4, extraBounce: 0.05)) {
          scrollPositionId = targetId
        }
      }
    }
  }
}

private struct CarouselPreviewItem: Identifiable {
  let id: Int
  let title: String
  let color: Color
}

#Preview {
  @Previewable @State var currentIndex = 0

  let items = [
    CarouselPreviewItem(id: 1, title: "First", color: .red),
    CarouselPreviewItem(id: 2, title: "Second", color: .blue),
    CarouselPreviewItem(id: 3, title: "Third", color: .green),
    CarouselPreviewItem(id: 4, title: "Fourth", color: .orange),
    CarouselPreviewItem(id: 5, title: "Fifth", color: .purple)
  ]

  VStack(spacing: 12) {
    Text("Current: \(currentIndex + 1) of \(items.count)")
      .font(.caption)

    CarouselView(
      data: items,
      id: \.id,
      content: { item in
        VStack {
          Text(item.title)
            .font(.title)
            .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(item.color)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding()
      },
      currentIndex: $currentIndex
    )
    .frame(height: 200)

    Text("Drag the indicator below to scrub")
      .font(.caption2)
      .foregroundStyle(.secondary)

    CarouselIndicator(currentIndex: $currentIndex, totalPages: items.count)
      .padding(.top, 4)
  }
}
