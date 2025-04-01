import SwiftUI

struct CompactLabelStyle: LabelStyle {
    #if canImport(UIKit)
    @Environment(\.horizontalSizeClass)
    var sizeClass
    #endif

    let compact: String?

    init(compact: String? = nil) {
        self.compact = compact
    }

    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 2) {
            configuration.icon

            #if canImport(UIKit)
            if sizeClass == .compact && compact != nil {
                Text(compact!).lineLimit(1).minimumScaleFactor(0.5)
            } else {
                configuration.title.lineLimit(1)
            }
            #else
            configuration.title.lineLimit(1)
            #endif
        }
    }
}
