import SF50_Shared
import SwiftData
import SwiftUI

struct LoadingProgressView: View {
  @Environment(AirportLoaderViewModel.self)
  private var loader

  var downloadProgress: StepProgress {
    switch loader.state {
      case .idle: return .pending
      case .downloading(let progress):
        if let progress { return .inProgress(progress: progress) }
        return .indeterminate
      case .extracting, .loading, .finished: return .complete
    }
  }

  var decompressProgress: StepProgress {
    switch loader.state {
      case .idle, .downloading: return .pending
      case .extracting(let progress):
        if let progress { return .inProgress(progress: progress) }
        return .indeterminate
      case .loading, .finished: return .complete
    }
  }

  var processingProgress: StepProgress {
    switch loader.state {
      case .idle, .downloading, .extracting: return .pending
      case .loading(let progress):
        if let progress { return .inProgress(progress: progress) }
        return .indeterminate
      case .finished: return .complete
    }
  }

  var body: some View {
    VStack {
      Image("Logo")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: 200, alignment: .center)
        .accessibilityHidden(true)
      Text("Loading latest airport information…")
        .padding(.bottom, 20)

      Grid(alignment: .leading) {
        GridRow {
          CircularProgressView(progress: downloadProgress)
          Text(downloadProgress == .complete ? "Downloaded" : "Downloading…")
            .foregroundStyle(downloadProgress == .pending ? .secondary : .primary)
        }

        GridRow {
          CircularProgressView(progress: decompressProgress)
          Text(decompressProgress == .complete ? "Decompressed" : "Decompressing…")
            .foregroundStyle(decompressProgress == .pending ? .secondary : .primary)
        }

        GridRow {
          CircularProgressView(progress: processingProgress)
          Text(processingProgress == .complete ? "Processed" : "Processing…")
            .foregroundStyle(processingProgress == .pending ? .secondary : .primary)
        }
      }
    }
  }
}

#Preview {
  PreviewView { preview in
    return LoadingProgressView()
      .environment(AirportLoaderViewModel(container: preview.container))
  }
}
